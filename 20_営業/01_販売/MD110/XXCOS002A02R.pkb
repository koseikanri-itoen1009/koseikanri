CREATE OR REPLACE PACKAGE BODY APPS.XXCOS002A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS002A02R(body)
 * Description      : 営業報告日報
 * MD.050           : 営業報告日報 MD050_COS_002_A02
 * Version          : 1.14
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  log_message            デバック用ログ出力
 *  init                   初期処理(A-1)
 *  delivery_data_entry    納品実績データ抽出、納品実績データ挿入(A-2,A-3)
 *  only_visit_data_entry  訪問のみデータ抽出、訪問のみデータ挿入(A-4,A-5)
 *  only_collecting_money_entry
 *                         集金のみデータ抽出、集金のみデータ挿入(A-6,A-7)
 *  calculation_total_update
 *                         営業報告日報帳票ワークテーブル更新（合計金額）(A-8)
 *  business_performance_update
 *                         営業報告日報帳票ワークテーブル更新（営業実績）(A-9)
 *  execute_svf            ＳＶＦ起動(A-10)
 *  delete_rpt_wrk_data    帳票ワークテーブル削除(A-11)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/25    1.0   T.Nakabayashi    新規作成
 *  2009/02/20    1.1   T.Nakabayashi    get_msgのパッケージ名修正
 *  2009/02/26    1.2   T.Nakabayashi    MD050課題No153対応 従業員、アサインメント適用日判断追加
 *  2009/02/27    1.3   T.Nakabayashi    帳票ワークテーブル削除処理 コメントアウト解除
 *  2009/05/01    1.4   K.Kiriu          [T1_0481]訪問データ抽出条件統一対応
 *  2009/06/03    1.5   T.Kitajima       [T1_1172]集約キーに顧客コード追加
 *  2009/06/03    1.5   T.Kitajima       [T1_1301]納品伝票番号分類で集約するように変更
 *  2009/06/19    1.6   K.Kiriu          [T1_1437]データパージ不具合対応
 *  2009/07/08    1.7   T.Tominaga       [0000477]伝票合計金額算出処理削除
 *                                                A-3.納品実績データ挿入処理のkey brake追加
 *                                                A-2,A-3後、税込入金を合計金額で更新する処理を追加
 *                                                納品実績情報カーソルの入金額取得変更
 *                                                納品実績情報カーソルのソートに販売実績ヘッダ.HHT納品入力日時を追加
 *  2009/07/15    1.7   T.Tominaga       [0000659]納品実績情報カーソルの本体金額を売上金額に変更（aftertax_sale, sale_discount）
 *                                       [0000665]納品実績情報カーソルの商品名をOPM品目アドオンの略称に変更
 *  2009/07/22    1.7   T.Tominaga       入金額の取得を納品実績情報カーソルからA-3.納品実績データ挿入処理内で別途取得に変更
 *  2009/09/02    1.8   K.Kiriu          [0000900]PT対応
 *                                       [0001273]集金のみの抽出条件不正対応
 *  2009/10/30    1.9   M.Sano           [0001373]参照ビュー変更：XXCOS_RS_INFO_V⇒XXCOS_RS_INFO2_V
 *  2009/12/17    1.10  S.Miyakoshi      [E_本稼動_00500](A-2)集約項目に「納品者」を追加
 *  2009/12/24    1.11  K.Atsushiba      [E_本稼動_00596]入金額の表示不良対応
 *  2010/01/06    1.12  K.Atsushiba      [E_本稼動_00827]帳票が出力されない対応
 *  2010/02/04    1.13  N.Maeda          [E_本稼動_01472] 入金額差額出力判定修正
 *  2010/09/14    1.14  K.Kiriu          [E_本稼動_04849] PT対応
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
  --  ===============================
  --  ユーザー定義例外
  --  ===============================
  --  *** プロファイル取得例外ハンドラ ***
  global_get_profile_expt       EXCEPTION;
  --  *** ロックエラー例外ハンドラ ***
  global_data_lock_expt         EXCEPTION;
  --  *** 対象データ無しエラー例外ハンドラ ***
  global_no_data_warm_expt      EXCEPTION;
  --  *** データ登録エラー例外ハンドラ ***
  global_insert_data_expt       EXCEPTION;
  --  *** データ更新エラー例外ハンドラ ***
  global_update_data_expt       EXCEPTION;--
  --  *** データ削除エラー例外ハンドラ ***
  global_delete_data_expt       EXCEPTION;--
--
  --
  PRAGMA  EXCEPTION_INIT(global_data_lock_expt, -54);
  -- ===============================
  -- ユーザー定義プライベート定数
  -- ===============================
  cv_pkg_name                   CONSTANT  VARCHAR2(100)                                   :=  'XXCOS002A02R';       --  パッケージ名
--
  --  帳票関連
  cv_conc_name                  CONSTANT  VARCHAR2(100)                                   :=  'XXCOS002A02R';       --  コンカレント名
  cv_file_id                    CONSTANT  VARCHAR2(100)                                   :=  'XXCOS002A02R';       --  帳票ＩＤ
  cv_extension_pdf              CONSTANT  VARCHAR2(100)                                   :=  '.pdf';               --  拡張子（ＰＤＦ）
  cv_frm_file                   CONSTANT  VARCHAR2(100)                                   :=  'XXCOS002A02S.xml';   --  フォーム様式ファイル名
  cv_vrq_file                   CONSTANT  VARCHAR2(100)                                   :=  'XXCOS002A02S.vrq';   --  クエリー様式ファイル名
  cv_output_mode_pdf            CONSTANT  VARCHAR2(1)                                     :=  '1';                  --  出力区分（ＰＤＦ）
--
  --  アプリケーション短縮名
  ct_xxcos_appl_short_name      CONSTANT  fnd_application.application_short_name%TYPE     :=  'XXCOS';              --  販物短縮アプリ名
--
  --  販物メッセージ
  ct_msg_lock_err               CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00001';   --  ロック取得エラーメッセージ
  ct_msg_get_profile_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00004';   --  プロファイル取得エラー
  ct_msg_insert_data_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00010';   --  データ登録エラー
  ct_msg_update_data_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00011';   --  データ更新エラー
  ct_msg_delete_data_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00012';   --  データ削除エラーメッセージ
  ct_msg_call_api_err           CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00017';   --  API呼出エラーメッセージ
  ct_msg_nodata_err             CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00018';   --  明細0件用メッセージ
  ct_msg_svf_api                CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00041';   --  ＳＶＦ起動ＡＰＩ
  ct_msg_request                CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00042';   --  要求ＩＤ
--
  --  機能固有メッセージ
  ct_msg_parameter_note         CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10501';   --  営業報告日報 パラメータ出力
  ct_msg_rpt_wrk_tbl            CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10502';   --  営業報告日報帳票ワークテーブル
  ct_str_only_visit_note        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10503';   --  訪問のみ
  ct_str_only_collecting_note   CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10504';   --  集金のみ
--
  --  クイックコード（作成元区分）
  ct_qct_org_cls_type           CONSTANT  fnd_lookup_types.lookup_type%TYPE               :=  'XXCOS1_MK_ORG_CLS_MST_002_A02';
  ct_qcc_org_cls_type           CONSTANT  fnd_lookup_values.lookup_code%TYPE              :=  'XXCOS_002_A02%';
--
  --  クイックコード（値引品目）
  ct_qct_discount_item_type     CONSTANT  fnd_lookup_types.lookup_type%TYPE               :=  'XXCOS1_DISCOUNT_ITEM_CODE';
--
  --  クイックコード（納品伝票区分）
  ct_qct_dlv_slip_cls_type      CONSTANT  fnd_lookup_types.lookup_type%TYPE               :=  'XXCOS1_DELIVERY_SLIP_CLASS';
--
--
  --  Yes/No
  cv_yes                        CONSTANT  VARCHAR2(1)                                     :=  'Y';
  cv_no                         CONSTANT  VARCHAR2(1)                                     :=  'N';
--
  --  パラメータ日付指定書式
  cv_fmt_date_default           CONSTANT  VARCHAR2(21)                                    :=  'YYYY/MM/DD HH24:MI:SS';
  cv_fmt_time_default           CONSTANT  VARCHAR2(7)                                     :=  'HH24:MI';
  cv_fmt_date                   CONSTANT  VARCHAR2(8)                                     :=  'YYYYMMDD';
  cv_fmt_date_profile           CONSTANT  VARCHAR2(10)                                    :=  'YYYY/MM/DD';
--
  --  メッセージ用文字列
  cv_str_profile_nm             CONSTANT  VARCHAR2(100)                                   :=  'profile_name';       --  プロファイル名
  cv_str_hht_no_nm              CONSTANT  VARCHAR2(100)                                   :=  'hht_invoice_no';     --  伝票番号
  cv_str_employee_num           CONSTANT  VARCHAR2(100)                                   :=  'employee_num';       --  営業員(納品担当)
-- ******************** 2009/07/08 Var.1.7 T.Tominaga ADD START  ******************************************
  cv_str_dlv_date               CONSTANT  VARCHAR2(100)                                   :=  'dlv_date';           --  納品日
  cv_str_party_num              CONSTANT  VARCHAR2(100)                                   :=  'party_num';          --  顧客コード
  cv_str_visit_time             CONSTANT  VARCHAR2(100)                                   :=  'visit_time';         --  訪問時間
-- ******************** 2009/07/08 Var.1.7 T.Tominaga ADD END    ******************************************
--
  --  トークン
  cv_tkn_para_date              CONSTANT  VARCHAR2(100)                                   :=  'PARA_DATE';          --  処理日付
  cv_tkn_profile                CONSTANT  VARCHAR2(100)                                   :=  'PROFILE';            --  プロファイル名
  cv_tkn_key_data               CONSTANT  VARCHAR2(100)                                   :=  'KEY_DATA';           --  キー情報
  cv_tkn_table                  CONSTANT  VARCHAR2(100)                                   :=  'TABLE_NAME';         --  テーブル名称
  cv_tkn_api_name               CONSTANT  VARCHAR2(100)                                   :=  'API_NAME';           --  API名称
  cv_tkn_request                CONSTANT  VARCHAR2(100)                                   :=  'REQUEST';            --  要求ＩＤ
  cv_tkn_para_delivery_date     CONSTANT  VARCHAR2(100)                                   :=  'PARAM1';             --  納品日
  cv_tkn_para_delivery_base     CONSTANT  VARCHAR2(100)                                   :=  'PARAM2';             --  納品拠点
  cv_tkn_para_dlv_by_code       CONSTANT  VARCHAR2(100)                                   :=  'PARAM3';             --  営業員(納品担当)
--
  --  string limit
  cn_limit_base_name            CONSTANT  PLS_INTEGER                                     :=  40;                   --  拠点名
  cn_limit_employee_name        CONSTANT  PLS_INTEGER                                     :=  40;                   --  営業員名
  cn_limit_party_name           CONSTANT  PLS_INTEGER                                     :=  40;                   --  顧客名
  cn_limit_item_name            CONSTANT  PLS_INTEGER                                     :=  16;                   --  商品名
  cn_limit_item_max             CONSTANT  PLS_INTEGER                                     :=  6;                    --  １明細内商品数
--
  --  取引区分
  cv_delivery_visit             CONSTANT  VARCHAR2(1)                                     :=  '1';                  --  納品実績
  cv_only_visit                 CONSTANT  VARCHAR2(1)                                     :=  '1';                  --  訪問のみ
  cv_only_collecting            CONSTANT  VARCHAR2(1)                                     :=  '2';                  --  集金のみ
--
  --  納品伝票区分
  cv_cls_dlv_dff1_dlv           CONSTANT  VARCHAR2(1)                                     :=  '1';                  --  納品
  cv_cls_dlv_dff1_rtn           CONSTANT  VARCHAR2(1)                                     :=  '2';                  --  返品
--
  --  顧客区分
  ct_cust_class_base            CONSTANT  hz_cust_accounts.customer_class_code%TYPE       :=  '1';                  --  拠点
  ct_cust_class_customer        CONSTANT  hz_cust_accounts.customer_class_code%TYPE       :=  '10';                 --  顧客
/* 2009/05/01 Ver1.4 Del Start */
  --  タスク
--  ct_task_obj_type_party        CONSTANT  jtf_tasks_b.source_object_type_code%TYPE        :=  'PARTY';              --  パーティ
--  ct_task_own_type_employee     CONSTANT  jtf_tasks_b.owner_type_code%TYPE                :=  'RS_EMPLOYEE';        --  営業員
/* 2009/05/01 Ver1.4 Del End   */
  --  有効訪問区分(タスク)
  cv_task_dff11_visit           CONSTANT  VARCHAR2(1)                                     :=  '0';                  --  訪問
  cv_task_dff11_valid           CONSTANT  VARCHAR2(1)                                     :=  '1';                  --  有効
  --  登録区分(タスク)
  cv_task_dff12_only_visit      CONSTANT  VARCHAR2(1)                                     :=  '1';                  --  訪問のみ
  --  明細番号初期値
  cn_line_no_default            CONSTANT  PLS_INTEGER                                     :=  1;
--****************************** 2009/07/08 1.7 T.Tominaga ADD START ******************************--
  cv_red_black_flag_red         CONSTANT  xxcos_sales_exp_lines.red_black_flag%TYPE       := '0';
--****************************** 2009/07/08 1.7 T.Tominaga ADD END   ******************************--
--****************************** 2009/07/15 1.7 T.Tominaga ADD START ******************************--
  cv_obsolete_class_one         CONSTANT VARCHAR2(1)   := '1';
--****************************** 2009/07/15 1.7 T.Tominaga ADD END   ******************************--
--
  --  ===============================
  --  ユーザー定義プライベート変数
  --  ===============================
  --  取引区分
  gv_delivery_visit_name            xxcos_rep_bus_report.dealings_content%TYPE;                                     --  納品実績
  gv_only_visit_name                xxcos_rep_bus_report.dealings_content%TYPE;                                     --  訪問のみ
  gv_only_collecting_name           xxcos_rep_bus_report.dealings_content%TYPE;                                     --  集金のみ
--
  --  ===============================
  --  ユーザー定義プライベート・カーソル
  --  ===============================
  --  ロック取得用
  CURSOR  lock_cur
  IS
    SELECT  rbre.ROWID
    FROM    xxcos_rep_bus_report      rbre
    WHERE   rbre.request_id           = cn_request_id
    FOR UPDATE NOWAIT
    ;
--
  --  納品実績情報
  CURSOR  delivery_cur  (
                        icp_delivery_date       DATE,
                        icp_delivery_base_code  VARCHAR2,
                        icp_dlv_by_code         VARCHAR2
                        )
  IS
    SELECT
/* 2009/09/02 Ver1.8 Add Start */
            /*+
-- 2009/10/30 Ver1.9 Add Start
              LEADING(rsid)
-- 2009/10/30 Ver1.9 Add Start
              LEADING(rsid.jrrx_n)
              INDEX(rsid.jrgm_n jtf_rs_group_members_n2)
              INDEX(rsid.jrgb_n jtf_rs_groups_b_u1)
              INDEX(rsid.jrrx_n xxcso_jrre_n02)
              USE_NL(rsid.papf_n)
              USE_NL(rsid.pept_n)
              USE_NL(rsid.paaf_n)
              USE_NL(rsid.jrgm_n)
              USE_NL(rsid.jrgb_n)
              LEADING(rsid.jrrx_o)
              INDEX(rsid.jrrx_o xxcso_jrre_n02)
              INDEX(rsid.jrgm_o jtf_rs_group_members_n2)
              INDEX(rsid.jrgb_o jtf_rs_groups_b_u1)
              USE_NL(rsid.papf_o)
              USE_NL(rsid.pept_o)
              USE_NL(rsid.paaf_o)
              USE_NL(rsid.jrgm_o)
              USE_NL(rsid.jrgb_o)
              USE_NL(rsid)
-- 2009/10/30 Ver1.9 Add Start
--              LEADING(rsir.jrrx_n)
--              INDEX(rsir.jrgm_n jtf_rs_group_members_n2)
--              INDEX(rsir.jrgb_n jtf_rs_groups_b_u1)
--              INDEX(rsir.jrrx_n xxcso_jrre_n02)
--              USE_NL(rsir.papf_n)
--              USE_NL(rsir.pept_n)
--              USE_NL(rsir.paaf_n)
--              USE_NL(rsir.jrgm_n)
--              USE_NL(rsir.jrgb_n)
--              LEADING(rsir.jrrx_o)
--              INDEX(rsir.jrrx_o xxcso_jrre_n02)
--              INDEX(rsir.jrgm_o jtf_rs_group_members_n2)
--              INDEX(rsir.jrgb_o jtf_rs_groups_b_u1)
--              USE_NL(rsir.papf_o)
--              USE_NL(rsir.pept_o)
--              USE_NL(rsir.paaf_o)
--              USE_NL(rsir.jrgm_o)
--              USE_NL(rsir.jrgb_o)
              USE_NL(rsid.jrgm_max.jrgm_m)
              USE_NL(rsir.jrgm_max.jrgm_m)
              USE_NL(saeh)
              USE_NL(base)
-- 2009/10/30 Ver1.9 Add End
              USE_NL(rsir)
            */
/* 2009/09/02 Ver1.8 Add End   */
            rsid.group_code               AS  group_no,
            rsid.group_in_sequence        AS  group_in_sequence,
            saeh.delivery_date            AS  dlv_date,
            saeh.dlv_invoice_number       AS  hht_invoice_no,
            sael.dlv_invoice_line_number  AS  line_no,
--****************************** 2009/06/03 1.5 T.Kitajima MOD START ******************************--
--            saeh.dlv_invoice_class        AS  dlv_invoice_class,
            MIN( saeh.dlv_invoice_class ) AS  dlv_invoice_class,
--****************************** 2009/06/03 1.5 T.Kitajima MOD  END  ******************************--
            sael.delivery_base_code       AS  base_code,
            hzpb.party_name               AS  base_name,
            saeh.dlv_by_code              AS  employee_num,
            rsid.employee_name            AS  employee_name,
            saeh.ship_to_customer_code    AS  party_num,
            hzpc.party_name               AS  party_name,
            saeh.results_employee_code    AS  performance_by_code,
            rsir.employee_name            AS  performance_by_name,
--****************************** 2009/07/15 1.7 T.Tominaga MOD START ******************************--
--            SUM(sael.pure_amount)         AS  aftertax_sale,
            SUM(sael.sale_amount)         AS  aftertax_sale,
--****************************** 2009/07/15 1.7 T.Tominaga MOD END   ******************************--
            SUM(
                CASE  sael.item_code
--****************************** 2009/07/15 1.7 T.Tominaga MOD START ******************************--
--                  WHEN  xlvd.lookup_code  THEN  sael.pure_amount
                  WHEN  xlvd.lookup_code  THEN  sael.sale_amount
--****************************** 2009/07/15 1.7 T.Tominaga MOD END   ******************************--
                  ELSE  0
                END
                )                         AS  sale_discount,
--****************************** 2009/07/22 1.7 T.Tominaga DEL START ******************************--
----****************************** 2009/07/08 1.7 T.Tominaga MOD START ******************************--
----            SUM(paym.payment_amount)      AS  pretax_payment,
--            SUM(
--                CASE  sael.red_black_flag
--                  WHEN cv_red_black_flag_red THEN ( paym.payment_amount * -1 )
--                  ELSE paym.payment_amount
--                END
--            ) AS  pretax_payment,
----****************************** 2009/07/08 1.7 T.Tominaga MOD END   ******************************--
--****************************** 2009/07/22 1.7 T.Tominaga DEL END   ******************************--
            SUM(sael.standard_qty)        AS  standard_qty,
            saeh.hht_dlv_input_date       AS  visit_time,
            sael.item_code                AS  item_code,
--****************************** 2009/07/15 1.7 T.Tominaga MOD START ******************************--
--            iimb.item_desc1               AS  item_name
            ximb.item_short_name          AS  item_name
--****************************** 2009/07/15 1.7 T.Tominaga MOD  END  ******************************--
    FROM    xxcos_sales_exp_headers   saeh,
            xxcos_sales_exp_lines     sael,
-- 2009/10/30 Ver1.9 Add Start
--            xxcos_rs_info_v           rsid,
--            xxcos_rs_info_v           rsir,
            xxcos_rs_info2_v          rsid,
            xxcos_rs_info2_v          rsir,
-- 2009/10/30 Ver1.9 Add End
            hz_cust_accounts          hzca,
            hz_parties                hzpc,
            hz_cust_accounts          base,
            hz_parties                hzpb,
            ic_item_mst_b             iimb,
--****************************** 2009/07/15 1.7 T.Tominaga ADD START ******************************--
            xxcmn_item_mst_b          ximb,
--****************************** 2009/07/15 1.7 T.Tominaga ADD  END  ******************************--
--****************************** 2009/07/22 1.7 T.Tominaga DEL START ******************************--
--            xxcos_payment             paym,
--****************************** 2009/07/22 1.7 T.Tominaga DEL  END  ******************************--
            xxcos_lookup_values_v     xlvm,
            xxcos_lookup_values_v     xlvd,
--****************************** 2009/06/03 1.5 T.Kitajima ADD START ******************************--
            xxcos_lookup_values_v     xlvn
--****************************** 2009/06/03 1.5 T.Kitajima ADD  END  ******************************--
    WHERE   saeh.delivery_date        =       icp_delivery_date
    AND     saeh.dlv_by_code          =       NVL(icp_dlv_by_code, saeh.dlv_by_code)
    AND     sael.sales_exp_header_id  =       saeh.sales_exp_header_id
    AND     sael.delivery_base_code   =       icp_delivery_base_code
    AND     rsid.base_code            =       icp_delivery_base_code
    AND     rsid.employee_number      =       saeh.dlv_by_code
-- 2009/10/30 Ver1.9 Add Start
    AND     rsid.employee_number      =       NVL(icp_dlv_by_code, rsid.employee_number)
-- 2009/10/30 Ver1.9 Add End
    AND     icp_delivery_date         BETWEEN rsid.effective_start_date
                                      AND     rsid.effective_end_date
    AND     icp_delivery_date         BETWEEN rsid.per_effective_start_date
                                      AND     rsid.per_effective_end_date
    AND     icp_delivery_date         BETWEEN rsid.paa_effective_start_date
                                      AND     rsid.paa_effective_end_date
    AND     rsir.base_code            =       icp_delivery_base_code
    AND     rsir.employee_number      =       saeh.results_employee_code
    AND     icp_delivery_date         BETWEEN rsir.effective_start_date
                                      AND     rsir.effective_end_date
    AND     icp_delivery_date         BETWEEN rsir.per_effective_start_date
                                      AND     rsir.per_effective_end_date
    AND     icp_delivery_date         BETWEEN rsir.paa_effective_start_date
                                      AND     rsir.paa_effective_end_date
    AND     hzca.account_number       =       saeh.ship_to_customer_code
    AND     hzpc.party_id             =       hzca.party_id
    AND     base.account_number       =       icp_delivery_base_code
    AND     base.customer_class_code  =       ct_cust_class_base
    AND     hzpb.party_id             =       base.party_id
    AND     iimb.item_no              =       sael.item_code
--****************************** 2009/07/15 1.7 T.Tominaga ADD START ******************************--
    AND     iimb.item_id              =       ximb.item_id
    AND     ximb.obsolete_class       <>      cv_obsolete_class_one
    AND     ximb.start_date_active    <=      saeh.delivery_date
    AND     ximb.end_date_active      >=      saeh.delivery_date
--****************************** 2009/07/15 1.7 T.Tominaga ADD END   ******************************--
--****************************** 2009/07/22 1.7 T.Tominaga DEL START ******************************--
--    AND     paym.base_code(+)         =       icp_delivery_base_code
--    AND     paym.customer_number(+)   =       saeh.ship_to_customer_code
--    AND     paym.payment_date(+)      =       saeh.delivery_date
--    AND     paym.hht_invoice_no(+)    =       saeh.dlv_invoice_number
--****************************** 2009/07/22 1.7 T.Tominaga DEL END   ******************************--
    AND     xlvm.lookup_type          =       ct_qct_org_cls_type
    AND     xlvm.lookup_code          LIKE    ct_qcc_org_cls_type
    AND     icp_delivery_date         BETWEEN NVL(xlvm.start_date_active, icp_delivery_date)
                                      AND     NVL(xlvm.end_date_active,   icp_delivery_date)
    AND     xlvm.meaning              =       saeh.create_class
    AND     xlvd.lookup_type(+)       =       ct_qct_discount_item_type
    AND     icp_delivery_date         BETWEEN NVL(xlvd.start_date_active(+),  icp_delivery_date)
                                      AND     NVL(xlvd.end_date_active(+),    icp_delivery_date)
    AND     xlvd.lookup_code(+)       =       sael.item_code
--****************************** 2009/06/03 1.5 T.Kitajima ADD START ******************************--
    AND     xlvn.lookup_type           =       ct_qct_dlv_slip_cls_type
    AND     xlvn.lookup_code           =       saeh.dlv_invoice_class
    AND     to_date(icp_delivery_date) BETWEEN NVL(xlvn.start_date_active, to_date(icp_delivery_date))
                                       AND     NVL(xlvn.end_date_active,   to_date(icp_delivery_date))
--****************************** 2009/06/03 1.5 T.Kitajima ADD  END  ******************************--
    GROUP BY
            rsid.group_code,
            rsid.group_in_sequence,
            saeh.delivery_date,
            saeh.dlv_invoice_number,
            sael.dlv_invoice_line_number,
--****************************** 2009/06/03 1.5 T.Kitajima MOD START ******************************--
--            saeh.dlv_invoice_class,
            xlvn.attribute1,
--****************************** 2009/06/03 1.5 T.Kitajima MOD  END  ******************************--
            sael.delivery_base_code,
            hzpb.party_name,
            saeh.dlv_by_code,
            rsid.employee_name,
            saeh.ship_to_customer_code,
            hzpc.party_name,
            saeh.results_employee_code,
            rsir.employee_name,
            saeh.hht_dlv_input_date,
            sael.item_code,
--****************************** 2009/07/15 1.7 T.Tominaga MOD START ******************************--
--            iimb.item_desc1
--    HAVING  SUM(sael.pure_amount)     <>      0
            ximb.item_short_name
    HAVING  SUM(sael.sale_amount)     <>      0
--****************************** 2009/07/15 1.7 T.Tominaga MOD END   ******************************--
    OR      SUM(sael.standard_qty)    <>      0
--****************************** 2009/07/22 1.7 T.Tominaga DEL START ******************************--
--    OR      SUM(paym.payment_amount)  <>      0
--****************************** 2009/07/22 1.7 T.Tominaga DEL START ******************************--
    ORDER BY
--****************************** 2009/12/17 1.10 S.Miyakoshi ADD  START  **************************--
            saeh.dlv_by_code,
--****************************** 2009/12/17 1.10 S.Miyakoshi ADD  END  ****************************--
            saeh.dlv_invoice_number,
--****************************** 2009/06/03 1.5 T.Kitajima ADD START ******************************--
            saeh.ship_to_customer_code,
--****************************** 2009/06/03 1.5 T.Kitajima ADD  END  ******************************--
--****************************** 2009/07/08 1.7 T.Tominaga ADD START ******************************--
            saeh.hht_dlv_input_date,
--****************************** 2009/07/08 1.7 T.Tominaga ADD  END  ******************************--
            sael.dlv_invoice_line_number
    ;
--
-- ******************** 2009/07/08 Var.1.7 T.Tominaga ADD START  ******************************************
    --  合計入金額算出
    CURSOR  payment_total_cur
    IS
      SELECT
              rbre.request_id               AS  request_id,
              rbre.employee_num             AS  employee_num,
              rbre.dlv_date                 AS  dlv_date,
              rbre.party_num                AS  party_num,
              rbre.visit_time               AS  visit_time,
              SUM(rbre.pretax_payment)      AS  total_payment
      FROM    xxcos_rep_bus_report          rbre
      WHERE   rbre.request_id               =   cn_request_id
      GROUP BY
              rbre.request_id,
              rbre.employee_num,
              rbre.dlv_date,
              rbre.party_num,
              rbre.visit_time
      HAVING  SUM(rbre.pretax_payment)      <>  0
      ;
-- ******************** 2009/07/08 Var.1.7 T.Tominaga ADD END    ******************************************
--
    --  各種合計金額算出
    CURSOR  calculation_cur
    IS
      SELECT
              rbre.request_id               AS  request_id,
              rbre.employee_num             AS  employee_num,
              rbre.dlv_date                 AS  dlv_date,
              SUM(rbre.aftertax_sale)       AS  dlv_total_sale,
              SUM(
                  CASE  xlvm.attribute1
                      WHEN  cv_cls_dlv_dff1_rtn  THEN  rbre.aftertax_sale
                      ELSE  0
                  END
                  )                         AS  dlv_total_rtn,
              SUM(rbre.sale_discount)       AS  dlv_total_discount,
              SUM(
                  CASE
                    WHEN  rbre.employee_num = rbre.performance_by_code  THEN  rbre.aftertax_sale
                    ELSE  0
                  END
                  )                         AS  performance_total_sale,
              SUM(
                  CASE
                    WHEN  rbre.employee_num = rbre.performance_by_code
                    AND   xlvm.attribute1   = cv_cls_dlv_dff1_rtn       THEN  rbre.aftertax_sale
                    ELSE  0
                  END
                  )                         AS  performance_total_rtn,
              SUM(
                  CASE
                    WHEN  rbre.employee_num = rbre.performance_by_code  THEN  rbre.sale_discount
                    ELSE  0
                  END
                  )                         AS  performance_total_discount
      FROM    xxcos_rep_bus_report      rbre,
              xxcos_lookup_values_v     xlvm
      WHERE   rbre.request_id           =       cn_request_id
      AND     xlvm.lookup_type          =       ct_qct_dlv_slip_cls_type
      AND     xlvm.lookup_code          =       rbre.dlv_invoice_class
      AND     rbre.dlv_date             BETWEEN NVL(xlvm.start_date_active, rbre.dlv_date)  
                                        AND     NVL(xlvm.end_date_active,   rbre.dlv_date)
      GROUP BY
              rbre.request_id,
              rbre.employee_num,
              rbre.dlv_date
      ;
--
-- ******************** 2009/07/08 Var.1.7 T.Tominaga DEL START  ******************************************
--    --  伝票合計金額算出
--    CURSOR  invoice_total_cur
--    IS
--      SELECT
--              rbre.request_id               AS  request_id,
--              rbre.employee_num             AS  employee_num,
--              rbre.dlv_date                 AS  dlv_date,
--              rbre.hht_invoice_no           AS  hht_invoice_no,
----****************************** 2009/06/03 1.5 T.Kitajima ADD START ******************************--
--              rbre.party_num                as  party_num,
----****************************** 2009/06/03 1.5 T.Kitajima ADD  END  ******************************--
--              SUM(rbre.aftertax_sale)       AS  invoice_total_sale
--      FROM    xxcos_rep_bus_report          rbre
--      WHERE   rbre.request_id               =   cn_request_id
--      GROUP BY
--              rbre.request_id,
--              rbre.employee_num,
--              rbre.dlv_date,
--              rbre.hht_invoice_no,
----****************************** 2009/06/03 1.5 T.Kitajima ADD START ******************************--
--              rbre.party_num
----****************************** 2009/06/03 1.5 T.Kitajima ADD  END  ******************************--
--     HAVING  COUNT(rbre.hht_invoice_no)    >   1
--      ;
-- ******************** 2009/07/08 Var.1.7 T.Tominaga DEL END    ******************************************
--
  --  営業実績カウント
  CURSOR  business_performance_cur(
                                  icp_delivery_date       DATE,
                                  icp_delivery_base_code  VARCHAR2,
                                  icp_dlv_by_code         VARCHAR2
                                  )
  IS
    SELECT
/* 2009/09/02 Ver1.8 Add Start */
            /*+
-- 2009/10/30 Ver1.9 Mod Start
--              LEADING(rsid.jrrx_n)
--              INDEX(rsid.jrgm_n jtf_rs_group_members_n2)
--              INDEX(rsid.jrgb_n jtf_rs_groups_b_u1)
--              INDEX(rsid.jrrx_n xxcso_jrre_n02)
--              USE_NL(rsid.papf_n)
--              USE_NL(rsid.pept_n)
--              USE_NL(rsid.paaf_n)
--              USE_NL(rsid.jrgm_n)
--              USE_NL(rsid.jrgb_n)
--              LEADING(rsid.jrrx_o)
--              INDEX(rsid.jrrx_o xxcso_jrre_n02)
--              INDEX(rsid.jrgm_o jtf_rs_group_members_n2)
--              INDEX(rsid.jrgb_o jtf_rs_groups_b_u1)
--              USE_NL(rsid.papf_o)
--              USE_NL(rsid.pept_o)
--              USE_NL(rsid.paaf_o)
--              USE_NL(rsid.jrgm_o)
--              USE_NL(rsid.jrgb_o)
--              USE_NL(rsid)
              LEADING(rsid)
-- 2009/10/30 Ver1.9 Mod End
            */
/* 2009/09/02 Ver1.8 Add End   */
            rsid.employee_number                      AS  employee_num,
            COUNT(task.task_id)                       AS  delay_visit_count,
            SUM(
                CASE  task.attribute11
                  WHEN  cv_task_dff11_valid THEN  1
                  ELSE  0
                END
                )                                     AS  delay_valid_count
/* 2009/05/01 Ver1.4 Mod Start */
--    FROM    jtf_tasks_b                   task,
    FROM    xxcso_visit_actual_v          task,
/* 2009/05/01 Ver1.4 Mod End   */
-- 2009/10/30 Ver1.9 Mod Start
--            xxcos_rs_info_v               rsid
            xxcos_rs_info2_v              rsid
-- 2009/10/30 Ver1.9 Mod End
/* 2010/09/14 Ver1.14 Mod Start */
--    WHERE   task.actual_end_date          >=      icp_delivery_date
--    AND     task.actual_end_date          <       icp_delivery_date + 1
    WHERE   TRUNC(task.actual_end_date)   >=      icp_delivery_date
    AND     TRUNC(task.actual_end_date)   <       icp_delivery_date + 1   --意図したインデックスを使用させるため残します。
/* 2010/09/14 Ver1.14 Mod End   */
/* 2009/05/01 Ver1.4 Mod Start */
--    AND     task.source_object_type_code  =       ct_task_obj_type_party
--    AND     task.owner_type_code          =       ct_task_own_type_employee
--    AND     task.deleted_flag             =       cv_no
/* 2009/05/01 Ver1.4 Mod End   */
/* 2010/09/14 Ver1.14 Mod Start */
--    AND     rsid.base_code                =       icp_delivery_base_code
    AND     UPPER(rsid.base_code)         =       icp_delivery_base_code
/* 2010/09/14 Ver1.14 Mod End   */
/* 2009/09/02 Ver1.8 Mod Start */
--    AND     rsid.employee_number          =       NVL(icp_dlv_by_code, rsid.employee_number)
    AND     (
              ( icp_dlv_by_code IS NULL )
              OR
              ( icp_dlv_by_code IS NOT NULL AND rsid.employee_number = icp_dlv_by_code )
            )
/* 2009/09/02 Ver1.8 Mod End   */
    AND     rsid.resource_id              =       task.owner_id
    AND     icp_delivery_date             BETWEEN rsid.effective_start_date
                                          AND     rsid.effective_end_date
    AND     icp_delivery_date             BETWEEN rsid.per_effective_start_date
                                          AND     rsid.per_effective_end_date
    AND     icp_delivery_date             BETWEEN rsid.paa_effective_start_date
                                          AND     rsid.paa_effective_end_date
    GROUP BY
            rsid.employee_number
    ;
--
  --  ===============================
  --  ユーザー定義プライベート型
  --  ===============================
  --  納品実績情報 テーブルタイプ
  TYPE  g_delivery_data_ttype           IS  TABLE OF  delivery_cur%ROWTYPE              INDEX BY  PLS_INTEGER;
  --  合計金額情報 テーブルタイプ
  TYPE  g_calculation_ttype             IS  TABLE OF  calculation_cur%ROWTYPE           INDEX BY  PLS_INTEGER;
-- ******************** 2009/07/08 Var.1.7 T.Tominaga MOD START  ******************************************
--  --  合計金額情報 テーブルタイプ
--  TYPE  g_invoice_total_ttype           IS  TABLE OF  invoice_total_cur%ROWTYPE         INDEX BY  PLS_INTEGER;
  --  合計入金額情報 テーブルタイプ
  TYPE  g_payment_total_ttype           IS  TABLE OF  payment_total_cur%ROWTYPE         INDEX BY  PLS_INTEGER;
-- ******************** 2009/07/08 Var.1.7 T.Tominaga MOD END    ******************************************
  --  営業実績 テーブルタイプ
  TYPE  g_business_performance_ttype    IS  TABLE OF  business_performance_cur%ROWTYPE  INDEX BY  PLS_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_delivery_date      IN      VARCHAR2,         --  1.納品日
    iv_delivery_base_code IN      VARCHAR2,         --  2.納品拠点
    iv_dlv_by_code        IN      VARCHAR2,         --  3.営業員（納品者）
    ov_errbuf             OUT     VARCHAR2,         --   エラー・メッセージ                  --# 固定 #
    ov_retcode            OUT     VARCHAR2,         --   リターン・コード                    --# 固定 #
    ov_errmsg             OUT     VARCHAR2)         --   ユーザー・エラー・メッセージ        --# 固定 #
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
    -- キー情報
    lv_key_info                 VARCHAR2(5000);
    ld_max_date                 VARCHAR2(255);
    --パラメータ出力用
    lv_para_msg                 VARCHAR2(5000);
--
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
    --  パラメータ出力
    lv_para_msg     :=  xxccp_common_pkg.get_msg(
      iv_application   =>  ct_xxcos_appl_short_name,
      iv_name          =>  ct_msg_parameter_note,
      iv_token_name1   =>  cv_tkn_para_delivery_date,
      iv_token_value1  =>  TO_CHAR(TO_DATE(iv_delivery_date, cv_fmt_date_default), cv_fmt_date_profile),
      iv_token_name2   =>  cv_tkn_para_delivery_base,
      iv_token_value2  =>  iv_delivery_base_code,
      iv_token_name3   =>  cv_tkn_para_dlv_by_code,
      iv_token_value3  =>  iv_dlv_by_code
      );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_para_msg
    );
--
    --  1行空白
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  NULL
    );
--
    --  固定文言取得(取引内容)
    gv_delivery_visit_name  :=  NULL;
    gv_only_visit_name      :=  xxccp_common_pkg.get_msg(
                                                        iv_application   =>  ct_xxcos_appl_short_name,
                                                        iv_name          =>  ct_str_only_visit_note
                                                        );
    gv_only_collecting_name :=  xxccp_common_pkg.get_msg(
                                                        iv_application   =>  ct_xxcos_appl_short_name,
                                                        iv_name          =>  ct_str_only_collecting_note
                                                        );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : delivery_data_entry
   * Description      : 納品実績データ抽出、納品実績データ挿入(A-2,A-3)
   ***********************************************************************************/
  PROCEDURE delivery_data_entry(
    iv_delivery_date      IN      VARCHAR2,         --  1.納品日
    iv_delivery_base_code IN      VARCHAR2,         --  2.納品拠点
    iv_dlv_by_code        IN      VARCHAR2,         --  3.営業員（納品者）
    ov_errbuf             OUT     VARCHAR2,         --   エラー・メッセージ                  --# 固定 #
    ov_retcode            OUT     VARCHAR2,         --   リターン・コード                    --# 固定 #
    ov_errmsg             OUT     VARCHAR2)         --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delivery_data_entry'; -- プログラム名
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
-- 2009/12/24 Ver1.11 Add Start
    cv_date_fmt         VARCHAR2(20) := 'YYYYMMDDHH24MISS';
    cv_input_date_fmt   VARCHAR2(20) := 'YYYY/MM/DD';
-- 2009/12/24 Ver1.11 Add End
    -- *** ローカル変数 ***
    -- キー情報
    lv_key_info                           VARCHAR2(5000);
    -- エラー情報
    lv_errtbl                             VARCHAR2(5000);
--
    -- <営業報告日報帳票ワーク>テーブル型
    TYPE  l_xxcos_rep_bus_report_ttype    IS  TABLE OF  xxcos_rep_bus_report%ROWTYPE  INDEX BY  PLS_INTEGER;
--
    l_xxcos_rep_bus_report_tab            l_xxcos_rep_bus_report_ttype;
--
    --  key brake判定用
    lt_hht_invoice_no                     xxcos_rep_bus_report.hht_invoice_no%TYPE;
--****************************** 2009/06/03 1.5 T.Kitajima ADD START ******************************--
    lt_party_num                          xxcos_rep_bus_report.party_num%TYPE;
--****************************** 2009/06/03 1.5 T.Kitajima ADD  END  ******************************--
--****************************** 2009/07/08 1.7 T.Tominaga ADD START ******************************--
    lt_visit_time                         xxcos_sales_exp_headers.hht_dlv_input_date%TYPE;
    ln_pretax_payment                     xxcos_payment.payment_amount%TYPE;
--****************************** 2009/07/08 1.7 T.Tominaga ADD END   ******************************--
--****************************** 2009/12/17 1.10 S.Miyakoshi ADD  START  **************************--
    lt_dlv_by_code                         xxcos_sales_exp_headers.dlv_by_code%TYPE;
--****************************** 2009/12/17 1.10 S.Miyakoshi ADD  END  ****************************--
    --  配列index定義
    lp_idx                                PLS_INTEGER;
    lp_idx_rep                            PLS_INTEGER;
    lp_idx_err                            PLS_INTEGER;
    lp_idx_err_data                       PLS_INTEGER;
    lp_item_count                         PLS_INTEGER;
-- ******************** 2009/07/08 Var.1.7 T.Tominaga ADD START  ******************************************
    lp_idx_pay                            PLS_INTEGER;
-- ******************** 2009/07/08 Var.1.7 T.Tominaga ADD END    ******************************************
--
    lp_line_count                         PLS_INTEGER;
--
    -- 納品実績情報 テーブル型
    l_delivery_data_tab                   g_delivery_data_ttype;
-- ******************** 2009/07/08 Var.1.7 T.Tominaga ADD START  ******************************************
    --  合計入金額情報 テーブル型
    l_payment_total_tab                   g_payment_total_ttype;
-- ******************** 2009/07/08 Var.1.7 T.Tominaga ADD END    ******************************************
-- 2009/12/24 Ver1.11 Add Start
  lv_pay_index                             VARCHAR2(1000);
  lv_pre_index                             VARCHAR2(1000);
  ln_dlv_index                             NUMBER;
  TYPE  l_dlv_payment_total_ttype          IS  TABLE OF  NUMBER  INDEX BY VARCHAR2(1000);
  lt_ldv_pay_total_tbl                     l_dlv_payment_total_ttype;
-- 2009/12/24 Ver1.11 Add End
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
-- 2009/12/24 Ver1.11 Add Start
  CURSOR get_payment_cur (
     ipd_delivery_date        IN  DATE
    ,ipv_delivery_base_code   IN  VARCHAR2
  ) IS
    SELECT   xp.base_code          base_code
            ,xp.customer_number    customer_number
            ,xp.payment_amount     payment_amount
            ,xp.payment_date       payment_date
            ,xp.hht_invoice_no     hht_invoice_no
    FROM    xxcos_payment   xp
    WHERE   xp.payment_date = ipd_delivery_date
    AND     xp.base_code    = ipv_delivery_base_code;
  --
  TYPE lt_payment_tbl_ttype IS TABLE OF get_payment_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  lt_payment_tbl            lt_payment_tbl_ttype;
-- 2009/12/24 Ver1.11 Add End
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
    --  ===============================
    --  A-2.納品実績データ抽出
    --  ===============================
    --  カーソルオープン
    OPEN  delivery_cur  (
                        TO_DATE(iv_delivery_date, cv_fmt_date_default),
                        iv_delivery_base_code,
                        iv_dlv_by_code
                        );
--
    -- レコード読み込み
    FETCH delivery_cur  BULK COLLECT  INTO  l_delivery_data_tab;
--
    -- 対象件数取得
    gn_target_cnt   :=  l_delivery_data_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE delivery_cur;
--
--
-- 2009/12/24 Ver1.11 Add Start
    --  ===============================
    --  入金データ抽出
    --  ===============================
    -- カーソル・オープン
    OPEN get_payment_cur (
       ipd_delivery_date      => TO_DATE(iv_delivery_date, cv_input_date_fmt)               -- 納品日
      ,ipv_delivery_base_code => iv_delivery_base_code                                      -- 拠点コード
    );
    -- レコード読込
    FETCH get_payment_cur  BULK COLLECT  INTO  lt_payment_tbl;
    --
    -- カーソル・クローズ
    CLOSE get_payment_cur;
-- 2009/12/24 Ver1.11 Add End
    -- ===============================
    -- A-3.納品実績データ挿入
    -- ===============================
--  変数初期化
    lp_idx_rep                :=  0;
    lp_item_count             :=  cn_limit_item_max;
    lt_hht_invoice_no         :=  NULL;
--****************************** 2009/06/03 1.5 T.Kitajima ADD START ******************************--
    lt_party_num              :=  NULL;
--****************************** 2009/06/03 1.5 T.Kitajima ADD  END  ******************************--
--****************************** 2009/07/08 1.7 T.Tominaga ADD START ******************************--
    lt_visit_time             :=  NULL;
    ln_pretax_payment         :=  NULL;
--****************************** 2009/07/08 1.7 T.Tominaga ADD END   ******************************--
--****************************** 2009/12/17 1.10 S.Miyakoshi ADD  START  **************************--
    lt_dlv_by_code            :=  NULL;
--****************************** 2009/12/17 1.10 S.Miyakoshi ADD  END  ****************************--
    lp_line_count             :=  cn_line_no_default - 1;
--
    --  0件の場合登録処理をスキップ
    IF  ( l_delivery_data_tab.COUNT <>  0 ) THEN
--
      <<delivery_data_entry>>
      FOR lp_idx IN l_delivery_data_tab.FIRST..l_delivery_data_tab.LAST LOOP
--
        --  key brake、商品情報数上限判定
--****************************** 2009/06/03 1.5 T.Kitajima MOD START ******************************--
--        IF  ( lt_hht_invoice_no <>  l_delivery_data_tab(lp_idx).hht_invoice_no  )
        IF  (lt_hht_invoice_no <>  l_delivery_data_tab(lp_idx).hht_invoice_no  )
--****************************** 2009/12/17 1.10 S.Miyakoshi ADD  START  **************************--
        OR  (lt_dlv_by_code    <>  l_delivery_data_tab(lp_idx).employee_num    )
--****************************** 2009/12/17 1.10 S.Miyakoshi ADD  END  ****************************--
        OR  (lt_party_num      <>  l_delivery_data_tab(lp_idx).party_num       )
--****************************** 2009/06/03 1.5 T.Kitajima MOD  END  ******************************--
--****************************** 2009/07/08 1.7 T.Tominaga ADD START ******************************--
        OR  (lt_visit_time     <>  l_delivery_data_tab(lp_idx).visit_time      )
--****************************** 2009/07/08 1.7 T.Tominaga ADD END   ******************************--
        OR  ( lp_item_count     =   cn_limit_item_max )
        THEN
          lp_idx_rep          :=  lp_idx_rep + 1;
          lp_item_count       :=  1;
--
--****************************** 2009/06/03 1.5 T.Kitajima MOD START ******************************--
--          IF  ( lt_hht_invoice_no = l_delivery_data_tab(lp_idx).hht_invoice_no  ) THEN
          IF  ( lt_hht_invoice_no = l_delivery_data_tab(lp_idx).hht_invoice_no  )
          AND (lt_party_num       =  l_delivery_data_tab(lp_idx).party_num      )
--****************************** 2009/07/08 1.7 T.Tominaga ADD START ******************************--
          AND (lt_visit_time      =  l_delivery_data_tab(lp_idx).visit_time     )
--****************************** 2009/07/08 1.7 T.Tominaga ADD END   ******************************--
          THEN
--****************************** 2009/06/03 1.5 T.Kitajima MOD  END  ******************************--
            --  明細カウントアップ
            lp_line_count     :=  lp_line_count + 1;
--****************************** 2009/07/08 1.7 T.Tominaga ADD START ******************************--
            --  入金額初期化
            ln_pretax_payment :=  NULL;
--****************************** 2009/07/08 1.7 T.Tominaga ADD END   ******************************--
          ELSE
            --  明細カウント初期化＆Key情報退避
            lp_line_count     :=  1;
            lt_hht_invoice_no :=  l_delivery_data_tab(lp_idx).hht_invoice_no;
--****************************** 2009/06/03 1.5 T.Kitajima ADD START ******************************--
            lt_party_num      :=  l_delivery_data_tab(lp_idx).party_num;
--****************************** 2009/06/03 1.5 T.Kitajima ADD  END  ******************************--
--****************************** 2009/07/08 1.7 T.Tominaga ADD START ******************************--
            lt_visit_time     :=  l_delivery_data_tab(lp_idx).visit_time;
--****************************** 2009/07/22 1.7 T.Tominaga MOD START ******************************--
--            ln_pretax_payment :=  l_delivery_data_tab(lp_idx).pretax_payment;
--****************************** 2009/07/08 1.7 T.Tominaga ADD END   ******************************--
-- 2009/12/24 Ver1.11 Del Start
--            -- 入金額の取得
--            BEGIN
--              SELECT SUM(paym.payment_amount)
--              INTO   ln_pretax_payment
--              FROM   xxcos_payment  paym
--              WHERE  paym.base_code           = l_delivery_data_tab(lp_idx).base_code
--              AND    paym.customer_number     = l_delivery_data_tab(lp_idx).party_num
--              AND    paym.payment_date        = l_delivery_data_tab(lp_idx).dlv_date
--              AND    paym.hht_invoice_no      = l_delivery_data_tab(lp_idx).hht_invoice_no
--              HAVING SUM(paym.payment_amount) <>  0;
--
--            EXCEPTION
--              WHEN NO_DATA_FOUND THEN
--                ln_pretax_payment := NULL;
--            END;
-- 2009/12/24 Ver1.11 Del End
--****************************** 2009/07/22 1.7 T.Tominaga MOD END   ******************************--
          END IF;
--
          --  新レコード用にIDを取得
          SELECT
            xxcos_rep_bus_report_s01.nextval
          INTO
            l_xxcos_rep_bus_report_tab(lp_idx_rep).record_id
          FROM
            DUAL;
--
          --  伝票情報セット
          l_xxcos_rep_bus_report_tab(lp_idx_rep).dlv_date                     :=  l_delivery_data_tab(lp_idx).dlv_date;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).base_code                    :=  l_delivery_data_tab(lp_idx).base_code;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).base_name                    :=  SUBSTRB(l_delivery_data_tab(lp_idx).base_name,
                                                                                          1,  cn_limit_base_name);
          l_xxcos_rep_bus_report_tab(lp_idx_rep).group_no                     :=  l_delivery_data_tab(lp_idx).group_no;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).group_in_sequence            :=  l_delivery_data_tab(lp_idx).group_in_sequence;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).employee_num                 :=  l_delivery_data_tab(lp_idx).employee_num;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).employee_name                :=  SUBSTRB(l_delivery_data_tab(lp_idx).employee_name,
                                                                                          1,  cn_limit_employee_name);
          l_xxcos_rep_bus_report_tab(lp_idx_rep).dealings_class               :=  cv_delivery_visit;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).dealings_content             :=  gv_delivery_visit_name;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).visit_time                   :=  TO_CHAR(l_delivery_data_tab(lp_idx).visit_time,
                                                                                          cv_fmt_time_default);
          l_xxcos_rep_bus_report_tab(lp_idx_rep).hht_invoice_no               :=  l_delivery_data_tab(lp_idx).hht_invoice_no;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).line_no                      :=  lp_line_count;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).dlv_invoice_class            :=  l_delivery_data_tab(lp_idx).dlv_invoice_class;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).party_num                    :=  l_delivery_data_tab(lp_idx).party_num;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).party_name                   :=  SUBSTRB(l_delivery_data_tab(lp_idx).party_name,
                                                                                          1,  cn_limit_party_name);
          l_xxcos_rep_bus_report_tab(lp_idx_rep).performance_by_code          :=  l_delivery_data_tab(lp_idx).performance_by_code;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).performance_by_name          :=  SUBSTRB(l_delivery_data_tab(lp_idx).performance_by_name,
                                                                                          1,  cn_limit_employee_name);
          l_xxcos_rep_bus_report_tab(lp_idx_rep).aftertax_sale                :=  l_delivery_data_tab(lp_idx).aftertax_sale;
--****************************** 2009/07/08 1.7 T.Tominaga MOD START ******************************--
--          l_xxcos_rep_bus_report_tab(lp_idx_rep).pretax_payment               :=  l_delivery_data_tab(lp_idx).pretax_payment;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).pretax_payment               :=  ln_pretax_payment;
--****************************** 2009/07/08 1.7 T.Tominaga MOD START ******************************--
          l_xxcos_rep_bus_report_tab(lp_idx_rep).sale_discount                :=  l_delivery_data_tab(lp_idx).sale_discount;
          --  商品情報セット
          l_xxcos_rep_bus_report_tab(lp_idx_rep).item_name1                   :=  SUBSTRB(l_delivery_data_tab(lp_idx).item_name,
                                                                                          1,  cn_limit_item_name);
          l_xxcos_rep_bus_report_tab(lp_idx_rep).quantity1                    :=  l_delivery_data_tab(lp_idx).standard_qty;
          --  WHO カラムセット
          l_xxcos_rep_bus_report_tab(lp_idx_rep).delay_visit_count            :=  0;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).delay_valid_count            :=  0;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).dlv_total_sale               :=  0;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).dlv_total_rtn                :=  0;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).dlv_total_discount           :=  0;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).performance_total_sale       :=  0;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).performance_total_rtn        :=  0;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).performance_total_discount   :=  0;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).created_by                   :=  cn_created_by;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).creation_date                :=  cd_creation_date;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).last_updated_by              :=  cn_last_updated_by;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).last_update_date             :=  cd_last_update_date;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).last_update_login            :=  cn_last_update_login;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).request_id                   :=  cn_request_id;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).program_application_id       :=  cn_program_application_id;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).program_id                   :=  cn_program_id;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).program_update_date          :=  cd_program_update_date;
        ELSE
          --  商品情報格納場所カウントアップ
          lp_item_count     :=  lp_item_count + 1;
--
          --  売上金額、値引金額加算
          l_xxcos_rep_bus_report_tab(lp_idx_rep).aftertax_sale                :=  l_xxcos_rep_bus_report_tab(lp_idx_rep).aftertax_sale
                                                                              +   l_delivery_data_tab(lp_idx).aftertax_sale;
          l_xxcos_rep_bus_report_tab(lp_idx_rep).sale_discount                :=  l_xxcos_rep_bus_report_tab(lp_idx_rep).sale_discount
                                                                              +   l_delivery_data_tab(lp_idx).sale_discount;
--
          --  商品情報セット
          IF    ( lp_item_count = 2 ) THEN
            l_xxcos_rep_bus_report_tab(lp_idx_rep).item_name2                 :=  SUBSTRB(l_delivery_data_tab(lp_idx).item_name,
                                                                                          1,  cn_limit_item_name);
            l_xxcos_rep_bus_report_tab(lp_idx_rep).quantity2                  :=  l_delivery_data_tab(lp_idx).standard_qty;
--
          ELSIF ( lp_item_count = 3 ) THEN
            l_xxcos_rep_bus_report_tab(lp_idx_rep).item_name3                 :=  SUBSTRB(l_delivery_data_tab(lp_idx).item_name,
                                                                                          1,  cn_limit_item_name);
            l_xxcos_rep_bus_report_tab(lp_idx_rep).quantity3                  :=  l_delivery_data_tab(lp_idx).standard_qty;
--
          ELSIF ( lp_item_count = 4 ) THEN
            l_xxcos_rep_bus_report_tab(lp_idx_rep).item_name4                 :=  SUBSTRB(l_delivery_data_tab(lp_idx).item_name,
                                                                                          1,  cn_limit_item_name);
            l_xxcos_rep_bus_report_tab(lp_idx_rep).quantity4                  :=  l_delivery_data_tab(lp_idx).standard_qty;
--
          ELSIF ( lp_item_count = 5 ) THEN
            l_xxcos_rep_bus_report_tab(lp_idx_rep).item_name5                 :=  SUBSTRB(l_delivery_data_tab(lp_idx).item_name,
                                                                                          1,  cn_limit_item_name);
            l_xxcos_rep_bus_report_tab(lp_idx_rep).quantity5                  :=  l_delivery_data_tab(lp_idx).standard_qty;
--
          ELSIF ( lp_item_count = 6 ) THEN
            l_xxcos_rep_bus_report_tab(lp_idx_rep).item_name6                 :=  SUBSTRB(l_delivery_data_tab(lp_idx).item_name,
                                                                                          1,  cn_limit_item_name);
            l_xxcos_rep_bus_report_tab(lp_idx_rep).quantity6                  :=  l_delivery_data_tab(lp_idx).standard_qty;
--
          END IF;
--
        --  key brake、商品情報数上限判定
        END IF;
--
      END LOOP  delivery_data_entry;
--
    --  0件の場合登録処理をスキップ
-- 2010/01/06 Ver1.12 Del Start
--    END IF;
-- 2010/01/06 Ver1.12 Del End
--
-- 2009/12/24 Ver1.11 Add Start
   IF ( lt_payment_tbl.COUNT > 0 ) THEN
     <<rep_loop>>
     FOR ln_rep_idx IN l_xxcos_rep_bus_report_tab.FIRST..l_xxcos_rep_bus_report_tab.LAST LOOP
       <<payment_loop>>
       FOR ln_idx IN 1..lt_payment_tbl.COUNT LOOP
         IF ( ( lt_payment_tbl.EXISTS(ln_idx) = TRUE )
               AND
              ( lt_payment_tbl(ln_idx).base_code = l_xxcos_rep_bus_report_tab(ln_rep_idx).base_code )            -- 拠点
               AND
              ( lt_payment_tbl(ln_idx).customer_number = l_xxcos_rep_bus_report_tab(ln_rep_idx).party_num )      -- 顧客コード
               AND
              ( lt_payment_tbl(ln_idx).payment_date = l_xxcos_rep_bus_report_tab(ln_rep_idx).dlv_date )          -- 納品日
               AND
              ( lt_payment_tbl(ln_idx).hht_invoice_no = l_xxcos_rep_bus_report_tab(ln_rep_idx).hht_invoice_no )  -- 納品伝票番号
               AND
              ( lt_payment_tbl(ln_idx).payment_amount = l_xxcos_rep_bus_report_tab(ln_rep_idx).aftertax_sale )   -- 入金額
           )
         THEN
           -- 入金額と売上額が一致した場合、その金額を設定
           l_xxcos_rep_bus_report_tab(ln_rep_idx).pretax_payment := lt_payment_tbl(ln_idx).payment_amount;
           --
-- 2010/01/06 Ver1.12 Mod Start
           lt_payment_tbl(ln_idx).payment_amount := 0;
--           -- 入金PL/SQL表から削除
--           lt_payment_tbl.DELETE(ln_idx);
-- 2010/01/06 Ver1.12 Mod End
           --
           -- ループを抜ける
           EXIT;
         END IF;
       END LOOP payment_loop;
     END LOOP rep_loop;
     --
     -- 納品実績に関連付けできなかった入金をヘッダ単位に合算する
     <<sum_payment_loop>>
     FOR ln_idx IN 1..lt_payment_tbl.COUNT LOOP
-- 2010/01/06 Ver1.12 Mod Start
       IF ( lt_payment_tbl(ln_idx).payment_amount > 0 ) THEN
         -- 入金額が0以上の場合
--       IF ( lt_payment_tbl.EXISTS(ln_idx) = TRUE ) THEN
-- 2010/01/06 Ver1.12 Mod End
         lv_pay_index := TO_CHAR( lt_payment_tbl(ln_idx).payment_date, cv_date_fmt )
                         || lt_payment_tbl(ln_idx).base_code
                         || lt_payment_tbl(ln_idx).customer_number
                         || lt_payment_tbl(ln_idx).hht_invoice_no;
         IF ( lt_ldv_pay_total_tbl.EXISTS(lv_pay_index) = TRUE ) THEN
           -- データがPL/SQL表に存在ある場合、合算する
           lt_ldv_pay_total_tbl(lv_pay_index) := lt_ldv_pay_total_tbl(lv_pay_index) + lt_payment_tbl(ln_idx).payment_amount;
         ELSE
           -- PL/SQL表に登録する
           lt_ldv_pay_total_tbl(lv_pay_index) := lt_payment_tbl(ln_idx).payment_amount;
         END IF;
       END IF;
     END LOOP alloc_payment_loop;
-- 2010/01/06 Ver1.12 Del Start
--    END IF;
-- 2010/01/06 Ver1.12 Del End
    --
    -- 納品に関連付けられない入金がある場合、訪問時間順に割り振る
-- 2010/01/06 Ver1.12 Add Start
    IF ( lt_ldv_pay_total_tbl.COUNT > 0 ) THEN
      -- 納品に関連付けられない入金がある場合
-- 2010/01/06 Ver1.12 Add End
    <<alloc_payment>>
    FOR ln_idx IN l_xxcos_rep_bus_report_tab.FIRST..l_xxcos_rep_bus_report_tab.LAST LOOP
      IF ( l_xxcos_rep_bus_report_tab(ln_idx).pretax_payment IS NULL ) THEN
        lv_pay_index := TO_CHAR( l_xxcos_rep_bus_report_tab(ln_idx).dlv_date, cv_date_fmt )
                        || l_xxcos_rep_bus_report_tab(ln_idx).base_code
                        || l_xxcos_rep_bus_report_tab(ln_idx).party_num
                        || l_xxcos_rep_bus_report_tab(ln_idx).hht_invoice_no;
        --
        -- 変数初期化
        ln_pretax_payment := NULL;
        --
        IF ( lt_ldv_pay_total_tbl.EXISTS(lv_pay_index) AND lt_ldv_pay_total_tbl(lv_pay_index) > 0 ) THEN
          -- 入金データがある場合
          IF ( lt_ldv_pay_total_tbl(lv_pay_index) > l_xxcos_rep_bus_report_tab(ln_idx).aftertax_sale ) THEN
            -- 入金額のほうが大きい場合
            ln_pretax_payment := l_xxcos_rep_bus_report_tab(ln_idx).aftertax_sale;
            lt_ldv_pay_total_tbl(lv_pay_index) := lt_ldv_pay_total_tbl(lv_pay_index) - l_xxcos_rep_bus_report_tab(ln_idx).aftertax_sale;
          ELSE
            -- 入金額のほうが小さい場合
            ln_pretax_payment := lt_ldv_pay_total_tbl(lv_pay_index);
            lt_ldv_pay_total_tbl(lv_pay_index) := 0;
          END IF;
        END IF;
        -- 入金額を設定
        l_xxcos_rep_bus_report_tab(ln_idx).pretax_payment := ln_pretax_payment;
      END IF;
    END LOOP alloc_payment;
    --
    -- 入金額が売上金額より多く入力された場合、訪問時間が古い納品実績に出力する
    <<lot_payment>>
    FOR ln_idx IN l_xxcos_rep_bus_report_tab.FIRST..l_xxcos_rep_bus_report_tab.LAST LOOP
      -- インデックスキー作成
      lv_pay_index := TO_CHAR( l_xxcos_rep_bus_report_tab(ln_idx).dlv_date, cv_date_fmt )
                      || l_xxcos_rep_bus_report_tab(ln_idx).base_code
                      || l_xxcos_rep_bus_report_tab(ln_idx).party_num
                      || l_xxcos_rep_bus_report_tab(ln_idx).hht_invoice_no;
      --
      IF ( ln_idx = l_xxcos_rep_bus_report_tab.FIRST ) THEN
        -- 1回目のループの場合
        lv_pre_index := lv_pay_index;
        ln_dlv_index := ln_idx;
      END IF;
      --
-- ********** 2010/02/04 1.13 N.Maeda MOD START ********** --
--      IF ( ( lv_pre_index != lv_pay_index ) 
--           OR
--           ( ln_idx = l_xxcos_rep_bus_report_tab.LAST )
--         )
--      THEN
--        -- インデックスがブレイク又は最終レコードの場合
--        IF ( ln_idx = l_xxcos_rep_bus_report_tab.LAST ) THEN
--          -- 最終レコードの場合、インデックスキーを再設定
--          lv_pre_index := lv_pay_index;
--          ln_dlv_index := ln_idx;
--        END IF;
      IF ( lv_pre_index != lv_pay_index ) THEN
      -- インデックスがブレイクした場合
-- ********** 2010/02/04 1.13 N.Maeda MOD  END  ********** --
        --
-- 2009/12/24 Ver1.11 Mod Start
        IF ( lt_ldv_pay_total_tbl.EXISTS(lv_pre_index) AND lt_ldv_pay_total_tbl(lv_pre_index) > 0 ) THEN
--        IF ( lt_ldv_pay_total_tbl.EXISTS(lv_pay_index) AND lt_ldv_pay_total_tbl(lv_pay_index) > 0 ) THEN
-- 2009/12/24 Ver1.11 Mod End
          -- 入金データがあり且つ残高がある場合
          l_xxcos_rep_bus_report_tab(ln_dlv_index).pretax_payment := l_xxcos_rep_bus_report_tab(ln_dlv_index).pretax_payment
                                                               + lt_ldv_pay_total_tbl(lv_pre_index);
        END IF;
      END IF;
      --
      lv_pre_index := lv_pay_index;
      ln_dlv_index := ln_idx;
--
    END LOOP lot_payment;
-- ********** 2010/02/04 1.13 N.Maeda ADD START ********** --
    IF ( lt_ldv_pay_total_tbl.EXISTS(lv_pre_index) AND lt_ldv_pay_total_tbl(lv_pre_index) > 0 ) THEN
    -- 最終インデックスのデータに売上額と入金額に差異がある場合
      l_xxcos_rep_bus_report_tab(ln_dlv_index).pretax_payment := l_xxcos_rep_bus_report_tab(ln_dlv_index).pretax_payment
                                                           + lt_ldv_pay_total_tbl(lv_pre_index);
    END IF;
-- ********** 2010/02/04 1.13 N.Maeda ADD  END  ********** --
-- 2009/12/24 Ver1.11 Add End
-- 2010/01/06 Ver1.12 Add Start
    END IF;    -- 納品に関連付けられない入金がない場合は、スキップ
    END IF;    -- 入金データがない場合は、スキップ
    END IF;    -- 納品データがない場合は、スキップ
-- 2010/01/06 Ver1.12 Add End
    BEGIN
      FORALL  lp_idx  IN  INDICES OF  l_xxcos_rep_bus_report_tab  SAVE EXCEPTIONS
        INSERT
        INTO    xxcos_rep_bus_report  
        VALUES  l_xxcos_rep_bus_report_tab(lp_idx);
    EXCEPTION
      WHEN OTHERS THEN
        <<bulk_insert_exceptions>>
--
        lv_errtbl :=  xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_rpt_wrk_tbl
                                              );
--
        FOR lp_idx_err  IN  1..SQL%BULK_EXCEPTIONS.COUNT  LOOP
          lp_idx_err_data :=  SQL%BULK_EXCEPTIONS(lp_idx_err).ERROR_INDEX;
--
          xxcos_common_pkg.makeup_key_info(
                                           ov_errbuf      => lv_errbuf           -- エラー・メッセージ
                                          ,ov_retcode     => lv_retcode          -- リターン・コード
                                          ,ov_errmsg      => lv_errmsg           -- ユーザー・エラー・メッセージ
                                          ,ov_key_info    => lv_key_info         -- キー情報
                                          ,iv_item_name1  => cv_str_hht_no_nm
                                          ,iv_data_value1 => l_xxcos_rep_bus_report_tab(lp_idx_err_data).hht_invoice_no
                                          );
          --  共通関数ステータスチェック
          IF  ( lv_retcode  <>  cv_status_normal  ) THEN
            RAISE global_api_expt;
          END IF;
--
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                                                iv_application => ct_xxcos_appl_short_name,
                                                iv_name        => ct_msg_insert_data_err,
                                                iv_token_name1 => cv_tkn_table,
                                                iv_token_value1=> lv_errtbl,
                                                iv_token_name2 => cv_tkn_key_data,
                                                iv_token_value2=> lv_key_info
                                                );
--
          -- 個別のエラーメッセージを取得（エラー時の個別トークンまでは取得できず）
          lv_errbuf :=  SQLERRM(-SQL%BULK_EXCEPTIONS(lp_idx_err).ERROR_CODE);
--
          -- エラーログ出力
          FND_FILE.PUT_LINE(
             which  =>  FND_FILE.LOG
            ,buff   =>  lv_key_info ||  ':' ||  lv_errbuf
          );
        END LOOP  bulk_insert_exceptions;
--
        ov_errmsg     :=  lv_errmsg;
        lv_errbuf     :=  SQLERRM;
        gn_error_cnt  :=  gn_error_cnt + SQL%BULK_EXCEPTIONS.COUNT;
        RAISE global_insert_data_expt;
    END;
--
--****************************** 2009/07/08 1.7 T.Tominaga ADD START ******************************--
    -- ===============================
    -- 税込入金を合計入金額（顧客コード・訪問時間単位）で更新する
    -- ===============================
    --  カーソルオープン
    OPEN  payment_total_cur;
--
    --  レコード読み込み
    FETCH payment_total_cur BULK COLLECT  INTO  l_payment_total_tab;
--
    --  カーソルクローズ
    CLOSE payment_total_cur;
--
    --  更新対象データがない場合は処理をスキップ
    IF  ( l_payment_total_tab.COUNT <>  0 ) THEN
      BEGIN
        <<payment_total_update>>
        FOR lp_idx_pay IN  l_payment_total_tab.FIRST..l_payment_total_tab.LAST  LOOP
          --  error index 退避
          lp_idx_err                          :=  lp_idx_pay;
--
          UPDATE  xxcos_rep_bus_report  rbre
          SET     pretax_payment              =   l_payment_total_tab(lp_idx_pay).total_payment,
                  last_updated_by             =   cn_last_updated_by,
                  last_update_date            =   cd_last_update_date,
                  last_update_login           =   cn_last_update_login,
                  program_update_date         =   cd_program_update_date
          WHERE   rbre.request_id             =   l_payment_total_tab(lp_idx_pay).request_id
          AND     rbre.employee_num           =   l_payment_total_tab(lp_idx_pay).employee_num
          AND     rbre.dlv_date               =   l_payment_total_tab(lp_idx_pay).dlv_date
          AND     rbre.party_num              =   l_payment_total_tab(lp_idx_pay).party_num
          AND     rbre.visit_time             =   l_payment_total_tab(lp_idx_pay).visit_time
          ;
        END LOOP  payment_total_update;
      EXCEPTION
        WHEN OTHERS THEN
          xxcos_common_pkg.makeup_key_info(
                                           ov_errbuf      => lv_errbuf           -- エラー・メッセージ
                                          ,ov_retcode     => lv_retcode          -- リターン・コード
                                          ,ov_errmsg      => lv_errmsg           -- ユーザー・エラー・メッセージ
                                          ,ov_key_info    => lv_key_info         -- キー情報
                                          ,iv_item_name1  => cv_str_employee_num
                                          ,iv_data_value1 => l_payment_total_tab(lp_idx_err).employee_num
                                          ,iv_item_name2  => cv_str_dlv_date
                                          ,iv_data_value2 => l_payment_total_tab(lp_idx_err).dlv_date
                                          ,iv_item_name3  => cv_str_party_num
                                          ,iv_data_value3 => l_payment_total_tab(lp_idx_err).party_num
                                          ,iv_item_name4  => cv_str_visit_time
                                          ,iv_data_value4 => l_payment_total_tab(lp_idx_err).visit_time
                                          );
          --  共通関数ステータスチェック
          IF  ( lv_retcode  <>  cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
--
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_rpt_wrk_tbl
                      );
--
          ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_insert_data_err,
                       iv_token_name1 => cv_tkn_table,
                       iv_token_value1=> lv_errmsg,
                       iv_token_name2 => cv_tkn_key_data,
                       iv_token_value2=> lv_key_info
                      );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt  :=  1;
        lv_errbuf     :=  SQLERRM;
        RAISE global_update_data_expt;
      END;
    END IF;
--****************************** 2009/07/08 1.7 T.Tominaga ADD END   ******************************--
--
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --*** データ更新例外ハンドラ ***
--****************************** 2009/07/08 1.7 T.Tominaga ADD START ******************************--
    WHEN global_update_data_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/07/08 1.7 T.Tominaga ADD END   ******************************--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
-- 2009/12/24 Ver1.11 Add Start
      IF ( get_payment_cur%ISOPEN ) THEN
        CLOSE get_payment_cur;
      END IF;
-- 2009/12/24 Ver1.11 Add End
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
-- 2009/12/24 Ver1.11 Add Start
      IF ( get_payment_cur%ISOPEN ) THEN
        CLOSE get_payment_cur;
      END IF;
-- 2009/12/24 Ver1.11 Add End
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
-- 2009/12/24 Ver1.11 Add Start
      IF ( get_payment_cur%ISOPEN ) THEN
        CLOSE get_payment_cur;
      END IF;
-- 2009/12/24 Ver1.11 Add End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/12/24 Ver1.11 Add Start
      IF ( get_payment_cur%ISOPEN ) THEN
        CLOSE get_payment_cur;
      END IF;
-- 2009/12/24 Ver1.11 Add End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delivery_data_entry;
--
  /**********************************************************************************
   * Procedure Name   : only_visit_data_entry
   * Description      : 訪問のみデータ抽出、訪問のみデータ挿入(A-4,A-5)
   ***********************************************************************************/
  PROCEDURE only_visit_data_entry(
    iv_delivery_date      IN      VARCHAR2,         --  1.納品日
    iv_delivery_base_code IN      VARCHAR2,         --  2.納品拠点
    iv_dlv_by_code        IN      VARCHAR2,         --  3.営業員（納品者）
    ov_errbuf             OUT     VARCHAR2,         --   エラー・メッセージ                  --# 固定 #
    ov_retcode            OUT     VARCHAR2,         --   リターン・コード                    --# 固定 #
    ov_errmsg             OUT     VARCHAR2)         --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'only_visit_data_entry'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    --  ===============================
    --  ユーザー宣言部
    --  ===============================
    --  *** ローカル定数 ***
--
    --  *** ローカル変数 ***
    --  パラメータ変換用
    ld_delivery_date                    DATE;
--
    --  ===============================
    --  ローカル・カーソル
    --  ===============================
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
    --  ===============================
    --  A-4.訪問のみデータ抽出、A-5.訪問のみデータ挿入
    --  ===============================
    ld_delivery_date  :=  TO_DATE(iv_delivery_date, cv_fmt_date_default);
--
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_report
              (
              record_id,
              dlv_date,
              base_code,
              base_name,
              group_no,
              group_in_sequence,
              employee_num,
              employee_name,
              dealings_class,
              dealings_content,
              visit_time,
              hht_invoice_no,
              line_no,
              dlv_invoice_class,
              party_num,
              party_name,
              performance_by_code,
              performance_by_name,
              aftertax_sale,
              pretax_payment,
              sale_discount,
              item_name1,
              quantity1,
              item_name2,
              quantity2,
              item_name3,
              quantity3,
              item_name4,
              quantity4,
              item_name5,
              quantity5,
              item_name6,
              quantity6,
              delay_visit_count,
              delay_valid_count,
              dlv_total_sale,
              dlv_total_rtn,
              dlv_total_discount,
              performance_total_sale,
              performance_total_rtn,
              performance_total_discount,
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
      SELECT
/* 2009/09/02 Ver1.8 Add Start */
               /*+
-- 2009/10/30 Ver1.9 Add Start
                 LEADING(rsid)
-- 2009/10/30 Ver1.9 Add End
                 LEADING(rsid.jrrx_n)
                 INDEX(rsid.jrgm_n jtf_rs_group_members_n2)
                 INDEX(rsid.jrgb_n jtf_rs_groups_b_u1)
                 INDEX(rsid.jrrx_n xxcso_jrre_n02)
                 USE_NL(rsid.papf_n)
                 USE_NL(rsid.pept_n)
                 USE_NL(rsid.paaf_n)
                 USE_NL(rsid.jrgm_n)
                 USE_NL(rsid.jrgb_n)
                 LEADING(rsid.jrrx_o)
                 INDEX(rsid.jrrx_o xxcso_jrre_n02)
                 INDEX(rsid.jrgm_o jtf_rs_group_members_n2)
                 INDEX(rsid.jrgb_o jtf_rs_groups_b_u1)
                 USE_NL(rsid.papf_o)
                 USE_NL(rsid.pept_o)
                 USE_NL(rsid.paaf_o)
                 USE_NL(rsid.jrgm_o)
                 USE_NL(rsid.jrgb_o)
                 USE_NL(rsid)
-- 2009/10/30 Ver1.9 Add Start
--                 INDEX(task.jtb jtf_tasks_b_n2)
                 USE_NL(base)
                 USE_NL(task)
                 USE_NL(rsid.jrrx_o rsid.jrgm_max.jrgm_m)
-- 2009/10/30 Ver1.9 Add End
              */
/* 2009/09/02 Ver1.8 Add End   */
              xxcos_rep_bus_report_s01.nextval          AS  record_id,
              TRUNC(task.actual_end_date)               AS  dlv_date,
              base.account_number                       AS  base_code,
--              SUBSTRB(base.account_name,  1,  cn_limit_base_name)
--                                                        AS  base_name,
              SUBSTRB(hzpb.party_name,    1,  cn_limit_base_name)
                                                        AS  base_name,
              rsid.group_code                           AS  group_no,
              rsid.group_in_sequence                    AS  group_in_sequence,
              rsid.employee_number                      AS  employee_num,
              SUBSTRB(rsid.employee_name, 1,  cn_limit_employee_name)
                                                        AS  employee_name,
              cv_only_visit                             AS  dealings_class,
              gv_only_visit_name                        AS  dealings_content,
              TO_CHAR(task.actual_end_date, cv_fmt_time_default)
                                                        AS  visit_time,
              NULL                                      AS  hht_invoice_no,
              cn_line_no_default                        AS  line_no,
              NULL                                      AS  dlv_invoice_class,
              hzca.account_number                       AS  party_num,
              SUBSTRB(hzpc.party_name,    1,  cn_limit_party_name)
                                                        AS  party_name,
              rsid.employee_number                      AS  performance_by_code,
              SUBSTRB(rsid.employee_name, 1,  cn_limit_employee_name)
                                                        AS  performance_by_name,
              0                                         AS  aftertax_sale,
              0                                         AS  pretax_payment,
              0                                         AS  sale_discount,
              NULL                                      AS  item_name1,
              NULL                                      AS  quantity1,
              NULL                                      AS  item_name2,
              NULL                                      AS  quantity2,
              NULL                                      AS  item_name3,
              NULL                                      AS  quantity3,
              NULL                                      AS  item_name4,
              NULL                                      AS  quantity4,
              NULL                                      AS  item_name5,
              NULL                                      AS  quantity5,
              NULL                                      AS  item_name6,
              NULL                                      AS  quantity6,
              0                                         AS  delay_visit_count,
              0                                         AS  delay_valid_count,
              0                                         AS  dlv_total_sale,
              0                                         AS  dlv_total_rtn,
              0                                         AS  dlv_total_discount,
              0                                         AS  performance_total_sale,
              0                                         AS  performance_total_rtn,
              0                                         AS  performance_total_discount,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
/* 2009/05/01 Ver1.4 Mod Start */
--      FROM    jtf_tasks_b                   task,
      FROM    xxcso_visit_actual_v          task,
/* 2009/05/01 Ver1.4 Mod End   */
              hz_cust_accounts              base,
              hz_parties                    hzpb,
              hz_cust_accounts              hzca,
              hz_parties                    hzpc,
-- 2009/10/30 Ver1.9 Mod Start
--              xxcos_rs_info_v               rsid
              xxcos_rs_info2_v              rsid
-- 2009/10/30 Ver1.9 Mod End
/* 2010/09/14 Ver1.14 Mod Start */
--      WHERE   task.actual_end_date          >=      ld_delivery_date
--      AND     task.actual_end_date          <       ld_delivery_date + 1
      WHERE   TRUNC(task.actual_end_date)   =       ld_delivery_date
/* 2010/09/14 Ver1.14 Mod End   */
/* 2009/05/01 Ver1.4 Del Start */
--      AND     task.source_object_type_code  =       ct_task_obj_type_party
--      AND     task.owner_type_code          =       ct_task_own_type_employee
--      AND     task.deleted_flag             =       cv_no
/* 2009/05/01 Ver1.4 Del End   */
      AND     task.attribute11              =       cv_task_dff11_visit
      AND     task.attribute12              =       cv_task_dff12_only_visit
/* 2009/05/01 Ver1.4 Mod Start */
--      AND     hzca.party_id                 =       task.source_object_id
--      AND     hzpc.party_id                 =       task.source_object_id
      AND     hzca.party_id                 =       task.party_id
      AND     hzpc.party_id                 =       task.party_id
/* 2009/05/01 Ver1.4 Mod Start */
      AND     base.account_number           =       iv_delivery_base_code
      AND     base.customer_class_code      =       ct_cust_class_base
      AND     hzpb.party_id                 =       base.party_id
      AND     rsid.base_code                =       iv_delivery_base_code
/* 2009/09/02 Ver1.8 Mod Start */
--      AND     rsid.employee_number          =       NVL(iv_dlv_by_code, rsid.employee_number)
      AND     (
                ( iv_dlv_by_code IS NULL )
                OR
                ( iv_dlv_by_code IS NOT NULL AND rsid.employee_number = iv_dlv_by_code )
              )
/* 2009/09/02 Ver1.8 Mod End   */
      AND     rsid.resource_id              =       task.owner_id
      AND     ld_delivery_date              BETWEEN rsid.effective_start_date
                                            AND     rsid.effective_end_date
      AND     ld_delivery_date              BETWEEN rsid.per_effective_start_date
                                            AND     rsid.per_effective_end_date
      AND     ld_delivery_date              BETWEEN rsid.paa_effective_start_date
                                            AND     rsid.paa_effective_end_date
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_rpt_wrk_tbl
                                              );
        ov_errmsg :=  xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_insert_data_err,
                                              iv_token_name1 => cv_tkn_table,
                                              iv_token_value1=> lv_errmsg,
                                              iv_token_name2 => cv_tkn_key_data,
                                              iv_token_value2=> NULL
                                              );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt  :=  1;
        lv_errbuf     :=  SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --  対象件数加算
    gn_target_cnt   :=  gn_target_cnt + SQL%ROWCOUNT;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END only_visit_data_entry;
--
--
  /**********************************************************************************
   * Procedure Name   : only_collecting_money_entry
   * Description      : 集金のみデータ抽出、集金のみデータ挿入(A-6,A-7)
   ***********************************************************************************/
  PROCEDURE only_collecting_money_entry(
    iv_delivery_date      IN      VARCHAR2,         --  1.納品日
    iv_delivery_base_code IN      VARCHAR2,         --  2.納品拠点
    iv_dlv_by_code        IN      VARCHAR2,         --  3.営業員（納品者）
    ov_errbuf             OUT     VARCHAR2,         --   エラー・メッセージ                  --# 固定 #
    ov_retcode            OUT     VARCHAR2,         --   リターン・コード                    --# 固定 #
    ov_errmsg             OUT     VARCHAR2)         --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'only_collecting_money_entry'; -- プログラム名
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
--  パラメータ変換用
    ld_delivery_date                    DATE;
--
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --  ===============================
    --  A-6.集金のみデータ抽出、A-7.集金のみデータ挿入
    --  ===============================
    ld_delivery_date  :=  TO_DATE(iv_delivery_date, cv_fmt_date_default);
--
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_report
              (
              record_id,
              dlv_date,
              base_code,
              base_name,
              group_no,
              group_in_sequence,
              employee_num,
              employee_name,
              dealings_class,
              dealings_content,
              visit_time,
              hht_invoice_no,
              line_no,
              dlv_invoice_class,
              party_num,
              party_name,
              performance_by_code,
              performance_by_name,
              aftertax_sale,
              pretax_payment,
              sale_discount,
              item_name1,
              quantity1,
              item_name2,
              quantity2,
              item_name3,
              quantity3,
              item_name4,
              quantity4,
              item_name5,
              quantity5,
              item_name6,
              quantity6,
              delay_visit_count,
              delay_valid_count,
              dlv_total_sale,
              dlv_total_rtn,
              dlv_total_discount,
              performance_total_sale,
              performance_total_rtn,
              performance_total_discount,
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
      SELECT
/* 2009/09/02 Ver1.8 Add Start */
              /*+
                INDEX(salr.fa fnd_application_u3)
                INDEX(base hz_cust_accounts_u2)
                INDEX(salr.efdfce ego_fnd_dsc_flx_ctx_ext_u2)
                INDEX(hzpb hz_parties_u1)
                INDEX(paym xxcos_payment_n03)
                INDEX(salr.hca hz_cust_accounts_u2)
                INDEX(salr.hp  hz_parties_u1)
                INDEX(salr.hopeb hz_org_profiles_ext_b_n1)
                INDEX(salr.jrre xxcoi_jrre_n01)
                INDEX(salr.papf per_people_f_pk)
                USE_NL(base salr.efdfce hzpb paym salr.hca salr.hp salr.hopeb salr.jrre salr.papf)
                LEADING(rsid.jrrx_n)
                INDEX(rsid.jrgm_n jtf_rs_group_members_n2)
                INDEX(rsid.jrgb_n jtf_rs_groups_b_u1)
                INDEX(rsid.jrrx_n xxcso_jrre_n02)
                USE_NL(rsid.papf_n)
                USE_NL(rsid.pept_n)
                USE_NL(rsid.paaf_n)
                USE_NL(rsid.jrgm_n)
                USE_NL(rsid.jrgb_n)
                LEADING(rsid.jrrx_o)
                INDEX(rsid.jrrx_o xxcso_jrre_n02)
                INDEX(rsid.jrgm_o jtf_rs_group_members_n2)
                INDEX(rsid.jrgb_o jtf_rs_groups_b_u1)
                USE_NL(rsid.papf_o)
                USE_NL(rsid.pept_o)
                USE_NL(rsid.paaf_o)
                USE_NL(rsid.jrgm_o)
                USE_NL(rsid.jrgb_o)
                USE_NL(rsid)
             */
/* 2009/09/02 Ver1.8 Add End   */
              xxcos_rep_bus_report_s01.nextval          AS  record_id,
              paym.payment_date                         AS  dlv_date,
              paym.base_code                            AS  base_code,
              SUBSTRB(hzpb.party_name, 1,  cn_limit_base_name)
                                                        AS  base_name,
              rsid.group_code                           AS  group_no,
              rsid.group_in_sequence                    AS  group_in_sequence,
              rsid.employee_number                      AS  employee_num,
              SUBSTRB(rsid.employee_name, 1,  cn_limit_employee_name)
                                                        AS  employee_name,
              cv_only_collecting                        AS  dealings_class,
              gv_only_collecting_name                   AS  dealings_content,
              NULL                                      AS  visit_time,
              paym.hht_invoice_no                       AS  hht_invoice_no,
              cn_line_no_default                        AS  line_no,
              NULL                                      AS  dlv_invoice_class,
              paym.customer_number                      AS  party_num,
              SUBSTRB(salr.party_name, 1,  cn_limit_party_name)
                                                        AS  party_name,
              salr.employee_number                      AS  performance_by_code,
              SUBSTRB(salr.kanji_last ||  ' ' ||  salr.kanji_first, 1,  cn_limit_employee_name)
                                                        AS  performance_by_name,
              0                                         AS  aftertax_sale,
              paym.payment_amount                       AS  pretax_payment,
              0                                         AS  sale_discount,
              NULL                                      AS  item_name1,
              NULL                                      AS  quantity1,
              NULL                                      AS  item_name2,
              NULL                                      AS  quantity2,
              NULL                                      AS  item_name3,
              NULL                                      AS  quantity3,
              NULL                                      AS  item_name4,
              NULL                                      AS  quantity4,
              NULL                                      AS  item_name5,
              NULL                                      AS  quantity5,
              NULL                                      AS  item_name6,
              NULL                                      AS  quantity6,
              0                                         AS  delay_visit_count,
              0                                         AS  delay_valid_count,
              0                                         AS  dlv_total_sale,
              0                                         AS  dlv_total_rtn,
              0                                         AS  dlv_total_discount,
              0                                         AS  performance_total_sale,
              0                                         AS  performance_total_rtn,
              0                                         AS  performance_total_discount,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    xxcos_payment             paym,
              hz_cust_accounts          base,
              hz_parties                hzpb,
              xxcos_salesreps_v         salr,
              xxcos_rs_info_v           rsid
      WHERE   paym.base_code            =       iv_delivery_base_code
      AND     paym.payment_date         =       ld_delivery_date
      AND     base.account_number       =       iv_delivery_base_code
      AND     base.customer_class_code  =       ct_cust_class_base
      AND     hzpb.party_id             =       base.party_id
      AND     salr.account_number       =       paym.customer_number
      AND     ld_delivery_date          BETWEEN NVL(salr.effective_start_date,  ld_delivery_date)
                                        AND     NVL(salr.effective_end_date,    ld_delivery_date)
      AND     rsid.base_code            =       iv_delivery_base_code
/* 2009/09/02 Ver1.8 Add Start */
      AND     (
                ( iv_dlv_by_code IS NULL )
                OR
                ( iv_dlv_by_code IS NOT NULL AND rsid.employee_number = iv_dlv_by_code )
              )
/* 2009/09/02 Ver1.8 Add End   */
      AND     rsid.employee_number      =       salr.employee_number
      AND     ld_delivery_date          BETWEEN rsid.effective_start_date
                                        AND     rsid.effective_end_date
      AND     ld_delivery_date          BETWEEN rsid.per_effective_start_date
                                        AND     rsid.per_effective_end_date
      AND     ld_delivery_date          BETWEEN rsid.paa_effective_start_date
                                        AND     rsid.paa_effective_end_date
      AND NOT EXISTS(
                    SELECT  saeh.ROWID
                    FROM    xxcos_sales_exp_headers     saeh,
                            xxcos_lookup_values_v       xlvm
                    WHERE   saeh.dlv_invoice_number     =       paym.hht_invoice_no
                    AND     saeh.delivery_date          =       paym.payment_date
                    AND     saeh.ship_to_customer_code  =       paym.customer_number
                    AND     saeh.sales_base_code        =       paym.base_code
                    AND     xlvm.lookup_type            =       ct_qct_org_cls_type
                    AND     xlvm.lookup_code            LIKE    ct_qcc_org_cls_type
                    AND     ld_delivery_date            BETWEEN NVL(xlvm.start_date_active, ld_delivery_date)
                                                        AND     NVL(xlvm.end_date_active,   ld_delivery_date)
                    AND     xlvm.meaning                =       saeh.create_class
                    AND     ROWNUM                      =       1
                    )
      ;
    EXCEPTION
      WHEN OTHERS THEN
--
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_rpt_wrk_tbl
                                              );
        ov_errmsg :=  xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_insert_data_err,
                                              iv_token_name1 => cv_tkn_table,
                                              iv_token_value1=> lv_errmsg,
                                              iv_token_name2 => cv_tkn_key_data,
                                              iv_token_value2=> NULL
                                              );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt  :=  1;
        lv_errbuf     :=  SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --  対象件数加算
    gn_target_cnt   :=  gn_target_cnt + SQL%ROWCOUNT;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
--
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END only_collecting_money_entry;
--
  /**********************************************************************************
   * Procedure Name   : calculation_total_update
   * Description      : 営業報告日報帳票ワークテーブル更新（合計金額）(A-8)
   ***********************************************************************************/
  PROCEDURE calculation_total_update(
    ov_errbuf             OUT     VARCHAR2,         --   エラー・メッセージ                  --# 固定 #
    ov_retcode            OUT     VARCHAR2,         --   リターン・コード                    --# 固定 #
    ov_errmsg             OUT     VARCHAR2)         --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calculation_total_update'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    --  ===============================
    --  ユーザー宣言部
    --  ===============================
    --  *** ローカル定数 ***
--
    --  *** ローカル変数 ***
    lv_table_name                       VARCHAR2(5000);
--
    -- キー情報
    lv_key_info                         VARCHAR2(5000);
    --  配列index定義
    lp_idx                              PLS_INTEGER;
    lp_idx_err                          PLS_INTEGER;
--
    --  合計金額情報 テーブル型
    l_calculation_tab                   g_calculation_ttype;
-- ******************** 2009/07/08 Var.1.7 T.Tominaga DEL START  ******************************************
--    --  伝票合計金額情報 テーブル型
--    l_invoice_total_tab                 g_invoice_total_ttype;
-- ******************** 2009/07/08 Var.1.7 T.Tominaga DEL END    ******************************************
    --  ===============================
    --  ローカル・カーソル
    --  ===============================
--
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --  ===============================
    --  A-8.営業報告日報帳票ワークテーブル更新（合計金額）
    --  ===============================
--
    --  カーソルオープン
    OPEN  calculation_cur;
--
    --  レコード読み込み
    FETCH calculation_cur BULK COLLECT  INTO  l_calculation_tab;
--
    --  カーソルクローズ
    CLOSE calculation_cur;
--
    --  更新対象データがない場合は処理をスキップ
    IF  ( l_calculation_tab.COUNT <>  0 ) THEN
      --  営業員別、合計金額更新
      BEGIN
        <<calculation_total_update>>
        FOR lp_idx IN  l_calculation_tab.FIRST..l_calculation_tab.LAST  LOOP
          --  error index 退避
          lp_idx_err                          :=  lp_idx;
--
          UPDATE  xxcos_rep_bus_report  rbre
          SET     dlv_total_sale              =   l_calculation_tab(lp_idx).dlv_total_sale,
                  dlv_total_rtn               =   l_calculation_tab(lp_idx).dlv_total_rtn,
                  dlv_total_discount          =   l_calculation_tab(lp_idx).dlv_total_discount,
                  performance_total_sale      =   l_calculation_tab(lp_idx).performance_total_sale,
                  performance_total_rtn       =   l_calculation_tab(lp_idx).performance_total_rtn,
                  performance_total_discount  =   l_calculation_tab(lp_idx).performance_total_discount,
                  last_updated_by             =   cn_last_updated_by,
                  last_update_date            =   cd_last_update_date,
                  last_update_login           =   cn_last_update_login,
                  program_update_date         =   cd_program_update_date
          WHERE   rbre.request_id             =   l_calculation_tab(lp_idx).request_id
          AND     rbre.employee_num           =   l_calculation_tab(lp_idx).employee_num
          AND     rbre.dlv_date               =   l_calculation_tab(lp_idx).dlv_date
          ;
        END LOOP  calculation_total_update;
      EXCEPTION
        WHEN OTHERS THEN
          xxcos_common_pkg.makeup_key_info(
                                           ov_errbuf      => lv_errbuf           -- エラー・メッセージ
                                          ,ov_retcode     => lv_retcode          -- リターン・コード
                                          ,ov_errmsg      => lv_errmsg           -- ユーザー・エラー・メッセージ
                                          ,ov_key_info    => lv_key_info         -- キー情報
                                          ,iv_item_name1  => cv_str_employee_num
                                          ,iv_data_value1 => l_calculation_tab(lp_idx_err).employee_num
                                          );
          --  共通関数ステータスチェック
          IF  ( lv_retcode  <>  cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
--
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_rpt_wrk_tbl
                      );
--
          ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_insert_data_err,
                       iv_token_name1 => cv_tkn_table,
                       iv_token_value1=> lv_errmsg,
                       iv_token_name2 => cv_tkn_key_data,
                       iv_token_value2=> lv_key_info
                      );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt  :=  1;
        lv_errbuf     :=  SQLERRM;
        RAISE global_update_data_expt;
      END;
    END IF;
--
-- ******************** 2009/07/08 Var.1.7 T.Tominaga DEL START  ******************************************
--    --  カーソルオープン
--    OPEN  invoice_total_cur;
----
--    --  レコード読み込み
--    FETCH invoice_total_cur BULK COLLECT  INTO  l_invoice_total_tab;
----
--    --  カーソルクローズ
--    CLOSE invoice_total_cur;
----
--    --  更新対象データがない場合は処理をスキップ
--    IF  ( l_invoice_total_tab.COUNT <>  0 ) THEN
--      --  伝票合計金額更新（SVFのグルーピング制御用）
--      --  本処理によりaftertax_saleの金額は、営業報告日報上の明細数次第で多重計上となるが
--      --  営業員フッタ用の金額項目は直近の処理にて集計済みであるため
--      --  帳票に出力される金額には問題なし。（１明細目の金額のみ帳票明細に出力される）
--      BEGIN
--        <<invoice_total_update>>
--        FOR lp_idx IN  l_invoice_total_tab.FIRST..l_invoice_total_tab.LAST  LOOP
--          --  error index 退避
--          lp_idx_err                          :=  lp_idx;
----
--          UPDATE  xxcos_rep_bus_report  rbre
--          SET     aftertax_sale               =   l_invoice_total_tab(lp_idx).invoice_total_sale,
--                  last_updated_by             =   cn_last_updated_by,
--                  last_update_date            =   cd_last_update_date,
--                  last_update_login           =   cn_last_update_login,
--                  program_update_date         =   cd_program_update_date
--          WHERE   rbre.request_id             =   l_invoice_total_tab(lp_idx).request_id
--          AND     rbre.employee_num           =   l_invoice_total_tab(lp_idx).employee_num
--          AND     rbre.dlv_date               =   l_invoice_total_tab(lp_idx).dlv_date
--          AND     rbre.hht_invoice_no         =   l_invoice_total_tab(lp_idx).hht_invoice_no
----****************************** 2009/06/03 1.5 T.Kitajima ADD START ******************************--
--          AND     rbre.party_num              =   l_invoice_total_tab(lp_idx).party_num
----****************************** 2009/06/03 1.5 T.Kitajima ADD  END  ******************************--
--          ;
--        END LOOP  invoice_total_update;
--      EXCEPTION
--        WHEN OTHERS THEN
--          xxcos_common_pkg.makeup_key_info(
--                                           ov_errbuf      => lv_errbuf           -- エラー・メッセージ
--                                          ,ov_retcode     => lv_retcode          -- リターン・コード
--                                          ,ov_errmsg      => lv_errmsg           -- ユーザー・エラー・メッセージ
--                                          ,ov_key_info    => lv_key_info         -- キー情報
--                                          ,iv_item_name1  => cv_str_hht_no_nm
--                                          ,iv_data_value1 => l_invoice_total_tab(lp_idx_err).hht_invoice_no
--                                          );
--          --  共通関数ステータスチェック
--          IF  ( lv_retcode  <>  cv_status_normal ) THEN
--            RAISE global_api_expt;
--          END IF;
----
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application => ct_xxcos_appl_short_name,
--                       iv_name        => ct_msg_rpt_wrk_tbl
--                      );
----
--          ov_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application => ct_xxcos_appl_short_name,
--                       iv_name        => ct_msg_insert_data_err,
--                       iv_token_name1 => cv_tkn_table,
--                       iv_token_value1=> lv_errmsg,
--                       iv_token_name2 => cv_tkn_key_data,
--                       iv_token_value2=> lv_key_info
--                      );
--        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
--        gn_error_cnt  :=  1;
--        lv_errbuf     :=  SQLERRM;
--        RAISE global_update_data_expt;
--      END;
--    END IF;
-- ******************** 2009/07/08 Var.1.7 T.Tominaga DEL END    ******************************************
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ更新例外ハンドラ ***
    WHEN global_update_data_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END calculation_total_update;
--
  /**********************************************************************************
   * Procedure Name   : business_performance_update
   * Description      : 営業報告日報帳票ワークテーブル更新（営業実績）(A-9)
   ***********************************************************************************/
  PROCEDURE business_performance_update(
    iv_delivery_date      IN      VARCHAR2,         --  1.納品日
    iv_delivery_base_code IN      VARCHAR2,         --  2.納品拠点
    iv_dlv_by_code        IN      VARCHAR2,         --  3.営業員（納品者）
    ov_errbuf             OUT     VARCHAR2,         --   エラー・メッセージ                  --# 固定 #
    ov_retcode            OUT     VARCHAR2,         --   リターン・コード                    --# 固定 #
    ov_errmsg             OUT     VARCHAR2)         --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'business_performance_update'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    --  ===============================
    --  ユーザー宣言部
    --  ===============================
    --  *** ローカル定数 ***
--
    --  *** ローカル変数 ***
    lv_table_name                       VARCHAR2(5000);
--
    -- キー情報
    lv_key_info                         VARCHAR2(5000);
--
    --  配列index定義
    lp_idx                              PLS_INTEGER;
    lp_idx_err                          PLS_INTEGER;
--
    --  営業実績 テーブル型
    l_business_performance_tab          g_business_performance_ttype;
--
    --  ===============================
    --  ローカル・カーソル
    --  ===============================
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
    --  ===============================
    --  A-9.営業報告日報帳票ワークテーブル更新（営業実績）
    --  ===============================
--
    --  カーソルオープン
    OPEN  business_performance_cur(
                                  TO_DATE(iv_delivery_date, cv_fmt_date_default),
                                  iv_delivery_base_code,
                                  iv_dlv_by_code
                                  );
--
    -- レコード読み込み
    FETCH business_performance_cur  BULK COLLECT  INTO  l_business_performance_tab;
--
    -- カーソルクローズ
    CLOSE business_performance_cur;
--
    --  更新対象データがない場合は処理をスキップ
    IF  ( l_business_performance_tab.COUNT  <>  0 ) THEN
--
      --  営業員別、営業実績更新
      BEGIN
        <<business_performance_update>>
        FOR lp_idx IN  l_business_performance_tab.FIRST..l_business_performance_tab.LAST  LOOP
          --  error index 退避
          lp_idx_err                          :=  lp_idx;
--
          UPDATE  xxcos_rep_bus_report  rbre
          SET     rbre.delay_visit_count      =   l_business_performance_tab(lp_idx).delay_visit_count,
                  rbre.delay_valid_count      =   l_business_performance_tab(lp_idx).delay_valid_count,
                  rbre.last_updated_by        =   cn_last_updated_by,
                  rbre.last_update_date       =   cd_last_update_date,
                  rbre.last_update_login      =   cn_last_update_login,
                  rbre.program_update_date    =   cd_program_update_date
          WHERE   rbre.request_id             =   cn_request_id
          AND     rbre.employee_num           =   l_business_performance_tab(lp_idx).employee_num
          ;
        END LOOP  business_performance_update;
      EXCEPTION
        WHEN OTHERS THEN
          xxcos_common_pkg.makeup_key_info(
                                           ov_errbuf      => lv_errbuf           -- エラー・メッセージ
                                          ,ov_retcode     => lv_retcode          -- リターン・コード
                                          ,ov_errmsg      => lv_errmsg           -- ユーザー・エラー・メッセージ
                                          ,ov_key_info    => lv_key_info         -- キー情報
                                          ,iv_item_name1  => cv_str_employee_num
                                          ,iv_data_value1 => l_business_performance_tab(lp_idx_err).employee_num
                                          );
          --  共通関数ステータスチェック
          IF  ( lv_retcode  <>  cv_status_normal  ) THEN
            RAISE global_api_expt;
          END IF;
--
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                                                iv_application => ct_xxcos_appl_short_name,
                                                iv_name        => ct_msg_rpt_wrk_tbl
                                                );
--
          ov_errmsg :=  xxccp_common_pkg.get_msg(
                                                iv_application => ct_xxcos_appl_short_name,
                                                iv_name        => ct_msg_insert_data_err,
                                                iv_token_name1 => cv_tkn_table,
                                                iv_token_value1=> lv_errmsg,
                                                iv_token_name2 => cv_tkn_key_data,
                                                iv_token_value2=> lv_key_info
                                                );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt  :=  1;
        lv_errbuf     :=  SQLERRM;
        RAISE global_update_data_expt;
      END;
    END IF;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ更新例外ハンドラ ***
    WHEN global_update_data_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END business_performance_update;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : ＳＶＦ起動(A-10)
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
    lv_api_name      VARCHAR2(5000);
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
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.明細0件用メッセージ取得
    --==================================
    lv_nodata_msg             :=  xxccp_common_pkg.get_msg(
                                                          iv_application          => ct_xxcos_appl_short_name,
                                                          iv_name                 => ct_msg_nodata_err
                                                          );
    --出力ファイル編集
    lv_file_name              :=  cv_file_id
                              ||  TO_CHAR(SYSDATE, cv_fmt_date)
                              ||  TO_CHAR(cn_request_id)
                              ||  cv_extension_pdf
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
    IF  ( lv_retcode  <>  cv_status_normal  ) THEN
      --  管理者用メッセージ退避
      lv_errbuf               :=  SUBSTRB(lv_errmsg ||  lv_errbuf, 5000);
--
      --  ユーザー用メッセージ取得
      lv_api_name             :=  xxccp_common_pkg.get_msg(
                                                          iv_application        => ct_xxcos_appl_short_name,
                                                          iv_name               => ct_msg_svf_api
                                                          );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
                                                          iv_application        => ct_xxcos_appl_short_name,
                                                          iv_name               => ct_msg_call_api_err,
                                                          iv_token_name1        => cv_tkn_api_name,
                                                          iv_token_value1       => lv_api_name
                                                          );
      RAISE global_api_expt;
    END IF;
--
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END execute_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : 帳票ワークテーブル削除(A-11)
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
--
    BEGIN
      --  ロック用カーソルオープン
      OPEN  lock_cur;
      --  ロック用カーソルクローズ
      CLOSE lock_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  テーブル名取得
        lv_table_name           :=  xxccp_common_pkg.get_msg(
                                                            iv_application        => ct_xxcos_appl_short_name,
                                                            iv_name               => ct_msg_rpt_wrk_tbl
                                                            );
--
        ov_errmsg               :=  xxccp_common_pkg.get_msg(
                                                            iv_application        => ct_xxcos_appl_short_name,
                                                            iv_name               => ct_msg_lock_err,
                                                            iv_token_name1        => cv_tkn_table,
                                                            iv_token_value1       => lv_table_name
                                                            );
        RAISE global_data_lock_expt;
    END;
--
--
    --==================================
    -- 2.帳票ワークテーブル削除
    --==================================
    BEGIN
      DELETE
      FROM    xxcos_rep_bus_report      rbre
      WHERE   rbre.request_id           =       cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --要求ID文字列取得
        lv_key_info           :=  xxccp_common_pkg.get_msg(
                                                          iv_application        => ct_xxcos_appl_short_name,
                                                          iv_name               => ct_msg_request,
                                                          iv_token_name1        => cv_tkn_request,
                                                          iv_token_value1       => TO_CHAR(cn_request_id)
                                                          );
        --  共通関数ステータスチェック
        IF  ( lv_retcode  <>  cv_status_normal  ) THEN
          RAISE global_api_expt;
        END IF;
--
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_rpt_wrk_tbl
                                              );
--
        ov_errmsg :=  xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_delete_data_err,
                                              iv_token_name1 => cv_tkn_table,
                                              iv_token_value1=> lv_errmsg,
                                              iv_token_name2 => cv_tkn_key_data,
                                              iv_token_value2=> lv_key_info
                                              );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt  :=  1;
        lv_errbuf     :=  SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
  EXCEPTION
    WHEN global_data_lock_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    --*** データ更新例外ハンドラ ***
    WHEN global_delete_data_expt THEN
--
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END delete_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_delivery_date      IN      VARCHAR2,         --  1.納品日
    iv_delivery_base_code IN      VARCHAR2,         --  2.納品拠点
    iv_dlv_by_code        IN      VARCHAR2,         --  3.営業員（納品者）
    ov_errbuf             OUT     VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT     VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg             OUT     VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
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
/* 2009/06/19 Ver1.6 Add Start */
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ(SVF実行結果保持用)
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード(SVF実行結果保持用)
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ(SVF実行結果保持用)
/* 2009/06/19 Ver1.6 Add End   */
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
    --  ===============================
    --  <処理部、ループ部名> (処理結果によって後続処理を制御する場合)
    --  ===============================
    init(
      iv_delivery_date
      ,iv_delivery_base_code
      ,iv_dlv_by_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  納品実績データ抽出、納品実績データ挿入(A-2,A-3)
    --  ===============================
    delivery_data_entry(
      iv_delivery_date
      ,iv_delivery_base_code
      ,iv_dlv_by_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
--
      --  データカーソルクローズ
      IF  ( delivery_cur%ISOPEN ) THEN
        CLOSE delivery_cur;
      END IF;
-- ******************** 2009/07/08 Var.1.7 T.Tominaga ADD START  ******************************************
      --  データカーソルクローズ
      IF  ( payment_total_cur%ISOPEN  ) THEN
        CLOSE payment_total_cur;
      END IF;
-- ******************** 2009/07/08 Var.1.7 T.Tominaga ADD END    ******************************************
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  訪問のみデータ抽出、訪問のみデータ挿入(A-4,A-5)
    --  ===============================
    only_visit_data_entry(
      iv_delivery_date
      ,iv_delivery_base_code
      ,iv_dlv_by_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  集金のみデータ抽出、集金のみデータ挿入(A-6,A-7)
    --  ===============================
    only_collecting_money_entry(
      iv_delivery_date
      ,iv_delivery_base_code
      ,iv_dlv_by_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  営業報告日報帳票ワークテーブル更新（合計金額）(A-8)
    --  ===============================
    calculation_total_update(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
--
      --  データカーソルクローズ
      IF  ( calculation_cur%ISOPEN  ) THEN
        CLOSE calculation_cur;
      END IF;
--
-- ******************** 2009/07/08 Var.1.7 T.Tominaga DEL START  ******************************************
--      --  データカーソルクローズ
--      IF  ( invoice_total_cur%ISOPEN  ) THEN
--        CLOSE calculation_cur;
--      END IF;
-- ******************** 2009/07/08 Var.1.7 T.Tominaga DEL END    ******************************************
--
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 営業報告日報帳票ワークテーブル更新（営業実績）(A-9)
    -- ===============================
    business_performance_update(
      iv_delivery_date
      ,iv_delivery_base_code
      ,iv_dlv_by_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
--
      --  データカーソルクローズ
      IF  ( business_performance_cur%ISOPEN )  THEN
        CLOSE business_performance_cur;
      END IF;
--
      RAISE global_process_expt;
    END IF;
--
    --  コミット発行
    COMMIT;
--
    -- ===============================
    -- ＳＶＦ起動(A-10)
    -- ===============================
    execute_svf(
      lv_errbuf    -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
/* 2009/06/19 Ver1.6 Mod Start */
--    IF  ( lv_retcode = cv_status_error  ) THEN
--      --(エラー処理)
--      RAISE global_process_expt;
--    END IF;
    --エラーでもワークテーブルを削除する為、エラー情報を保持
    lv_errbuf_svf  := lv_errbuf;
    lv_retcode_svf := lv_retcode;
    lv_errmsg_svf  := lv_errmsg;
/* 2009/06/19 Ver1.6 Mod End   */
--
    -- ===============================
    -- 帳票ワークテーブル削除(A-11)
    -- ===============================
    delete_rpt_wrk_data(
      lv_errbuf    -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF  ( lv_retcode = cv_status_error  ) THEN
      --(エラー処理)
--
      --  ロックカーソルクローズ
      IF  ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
--
      RAISE global_process_expt;
    END IF;
--
/* 2009/06/19 Ver1.6 Add Start */
    --エラーの場合、ロールバックするのでここでコミット
    COMMIT;
--
    --SVF実行結果確認
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
/* 2009/06/19 Ver1.6 Add Start */
--
    --  帳票は対象件数＝正常件数とする
    gn_normal_cnt :=  gn_target_cnt;
--
    --明細０件時の警告終了制御
    IF ( gn_target_cnt = 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
    errbuf                OUT     VARCHAR2,         --   エラー・メッセージ  --# 固定 #
    retcode               OUT     VARCHAR2,         --   リターン・コード    --# 固定 #
    iv_delivery_date      IN      VARCHAR2,         --  1.納品日
    iv_delivery_base_code IN      VARCHAR2,         --  2.納品拠点
    iv_dlv_by_code        IN      VARCHAR2          --  3.営業員（納品者）
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
/*
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_log
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
*/
--###########################  固定部 END   #############################
--
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_delivery_date
      ,iv_delivery_base_code
      ,iv_dlv_by_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
END XXCOS002A02R;
/
