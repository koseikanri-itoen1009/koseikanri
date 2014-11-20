CREATE OR REPLACE PACKAGE BODY xxwsh400001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH400001C(body)
 * Description      : 引取計画からのリーフ出荷依頼自動作成
 * MD.050/070       : 出荷依頼                              (T_MD050_BPO_400)
 *                    引取計画からのリーフ出荷依頼自動作成  (T_MD070_BPO_40A)
 * Version          : 1.24
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  pro_err_list_make          P エラーリスト作成
 *  pro_get_cus_option         P 関連データ取得                     (A-1)
 *  pro_param_chk              P 入力パラメータチェック             (A-2)
 *  pro_get_to_plan            P 引取計画情報抽出                   (A-3)
 *  pro_ship_max_kbn           P 出荷予定日/最大配送区分算出        (A-4)
 *  pro_lines_chk              P 明細項目チェック                   (A-5)
 *  pro_xsr_chk                P 物流構成アドオンマスタ存在チェック (A-6)
 *  pro_total_we_ca            P 合計重量/合計容積算出              (A-7)
 *  pro_ship_y_n_chk           P 出荷可否チェック                   (A-8)
 *  pro_lines_create           P 受注明細アドオンレコード生成       (A-9)
 *  pro_duplication_item_chk   P 品目重複チェック                   (A-13)  -- 2008/10/09 H.Itou Add 統合テスト指摘118
 *  pro_load_eff_chk           P 積載効率チェック                   (A-10)
 *  pro_headers_create         P 受注ヘッダアドオンレコード生成     (A-11)
 *  pro_ship_order             P 出荷依頼登録処理                   (A-12)
 *  pro_no_item_category_chk   P 品目カテゴリ設定チェック           (A-15)
 *  submain                    P メイン処理プロシージャ
 *  main                       P コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/03/04    1.0   Tatsuya Kurata     新規作成
 *  2008/04/17    1.1   Tatsuya Kurata     内部変更要求#40,#42,#45対応
 *  2008/04/30    1.2   Tatsuya Kurata     内部変更要求#65対応
 *  2008/06/04    1.3   椎名  昭圭         不具合修正
 *  2008/06/10    1.4   石渡  賢和         不具合修正(エラーリストでスペース埋めを削除）
 *                                         xxwsh_common910_pkgの帰り値判定を修正
 *  2008/06/19    1.5   Y.Shindou          内部変更要求#143対応
 *  2008/06/27    1.6   石渡  賢和         不具合修正(着荷日がずれる、TRUNC対応）
 *  2008/07/04    1.7   上原  正好         ST不具合#392対応(運賃区分、物流担当確認依頼区分、
 *                                         契約外運賃区分のデフォルト値設定)
 *  2008/07/09    1.8   Oracle 山根一浩    I_S_192対応
 *  2008/07/30    1.9   Oracle 山根一浩    ST指摘28,課題No32,変更要求178,T_S_476対応
 *  2008/08/06    1.10  Oracle 山根一浩    出荷追加_2
 *  2008/08/13    1.11  Oracle 伊藤ひとみ  出荷追加_1
 *  2008/08/18    1.12  Oracle 伊藤ひとみ  出荷追加_1のバグ エラー出力順を明細順に変更
 *  2008/08/19    1.13  Oracle 伊藤ひとみ  T_S_611 出荷元保管場所より代表運送業者を取得し、設定する。
 *                                         結合指摘#87 出荷停止日エラーログの日付フォーマット修正
 *  2008/10/09    1.14  Oracle 伊藤ひとみ  統合テスト指摘118 1依頼に重複品目がある場合はエラー終了とする。
 *                                         統合テスト指摘240 積載効率チェック(合計値算出)のINパラメータに基準日を追加。
 *  2008/10/16    1.15  Oracle 丸下        管轄拠点をCSVファイルのコード値を使用するように修正
 *  2008/11/19    1.16  Oracle 伊藤ひとみ  統合テスト指摘683対応
 *  2008/11/20    1.17  Oracle 伊藤ひとみ  統合テスト指摘141,658対応
 *  2009/01/08    1.18  SCS    伊藤ひとみ  本番障害#894対応
 *  2009/01/30    1.19  SCS    伊藤ひとみ  本番障害#994対応
 *  2009/06/25    1.20  SCS    伊藤ひとみ  本番障害#1436対応
 *  2009/07/08    1.21  SCS    伊藤ひとみ  本番障害#1525対応
 *  2009/07/13    1.22  SCS    伊藤ひとみ  本番障害#1525対応
 *  2009/12/09    1.23  SCS    宮川真理子  本番障害#267対応
 *  2010/01/21    1.24  SCS    宮川真理子  本番障害#601対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
--
--################################  固定部 END   ###############################
--
  -- ==================================================
  -- ユーザー定義グローバル型
  -- ==================================================
  -- 入力Ｐ格納用レコード変数
  TYPE rec_param_data  IS RECORD 
    (
      yyyymm           VARCHAR2(6)    -- 対象年月
     ,base             VARCHAR2(4)   -- 管轄拠点
    );
--
  -- 引取計画情報取得データ格納用レコード変数
  TYPE rec_to_plan IS RECORD
    (
      for_name    mrp_forecast_designators.forecast_designator%TYPE  -- フォーキャスト名
     ,ktn         mrp_forecast_designators.attribute3%TYPE           -- 拠点
     ,for_date    mrp_forecast_dates.forecast_date%TYPE              -- 着荷予定日
     ,ship_t_no   xxcmn_cust_acct_sites_v.ship_to_no%TYPE            -- 配送先
     ,p_s_site    xxcmn_cust_acct_sites_v.party_site_id%TYPE         -- 配送先ID
     ,par_num     xxcmn_cust_accounts_v.party_number%TYPE            -- 顧客
     ,par_id      xxcmn_cust_accounts_v.party_id%TYPE                -- 顧客ID
     ,ship_fr     mrp_forecast_designators.attribute2%TYPE           -- 出荷元
     ,ship_id     xxcmn_item_locations_v.inventory_location_id%TYPE  -- 出荷元ID
     ,item_no     xxcmn_item_mst2_v.item_no%TYPE                     -- 品目
     ,item_id     xxcmn_item_mst2_v.inventory_item_id%TYPE           -- 品目ID
     ,amount      mrp_forecast_dates.original_forecast_quantity%TYPE -- 数量
     ,item_um     xxcmn_item_mst2_v.item_um%TYPE                     -- 単位
     ,case_am     xxcmn_item_mst2_v.num_of_cases%TYPE                -- 入数
     ,ship_am     xxcmn_item_mst2_v.num_of_deliver%TYPE              -- 出荷入数
     ,skbn        xxcmn_item_categories5_v.prod_class_code%TYPE      -- 商品区分
     ,wei_kbn     xxcmn_item_mst2_v.weight_capacity_class%TYPE       -- 重量容積区分
     ,out_kbn     xxcmn_item_mst2_v.ship_class%TYPE                  -- 出荷区分
     ,item_kbn    xxcmn_item_categories5_v.item_class_code%TYPE      -- 品目区分
     ,sale_kbn    xxcmn_item_mst2_v.sales_div%TYPE                   -- 売上対象区分
     ,end_kbn     xxcmn_item_mst2_v.obsolete_class%TYPE              -- 廃止区分
     ,rit_kbn     xxcmn_item_mst2_v.rate_class%TYPE                  -- 率区分
     ,no_flg      xxcmn_cust_accounts_v.cust_enable_flag%TYPE        -- 中止客申請フラグ
     ,conv_unit   xxcmn_item_mst2_v.conv_unit%TYPE                   -- 入出庫換算単位
     ,a_p_flg     xxcmn_item_locations_v.allow_pickup_flag%TYPE      -- 出荷引当対象フラグ
-- 2008/08/18 H.Itou Add Start
     ,we_loading_msg_seq NUMBER                                      -- 積載効率(重量)メッセージ格納SEQ
     ,ca_loading_msg_seq NUMBER                                      -- 積載効率(容積)メッセージ格納SEQ
-- 2008/08/18 H.Itou Add End
-- 2008/10/09 H.Itou Add Start 統合テスト指摘240
     ,dup_item_msg_seq   NUMBER                                      -- 品目重複メッセージ格納SEQ
-- 2008/10/09 H.Itou Add End
-- 2008/08/19 H.Itou Add Start T_S_611
     ,career_id            xxwsh_order_headers_all.career_id%TYPE             -- 運送業者ID
     ,freight_carrier_code xxwsh_order_headers_all.freight_carrier_code%TYPE  -- 運送業者
-- 2008/08/19 H.Itou Add End
    );
  TYPE tab_data_to_plan IS TABLE OF rec_to_plan INDEX BY PLS_INTEGER;
--
  -- エラーメッセージ出力用
  TYPE rec_err_msg IS RECORD 
    (
      err_msg     VARCHAR2(10000)
    );
  TYPE tab_data_err_msg IS TABLE OF rec_err_msg INDEX BY BINARY_INTEGER;
--
  ---------------------------------------------------
  --      受注明細アドオン登録用項目テーブル型     --
  ---------------------------------------------------
  -- 受注明細アドオンID
  TYPE l_order_line_id               IS TABLE OF
                xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- 受注ヘッダアドオンID
  TYPE l_order_header_id             IS TABLE OF
                xxwsh_order_lines_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 明細番号
  TYPE l_order_line_number           IS TABLE OF
                xxwsh_order_lines_all.order_line_number%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼No
  TYPE l_request_no                  IS TABLE OF
                xxwsh_order_lines_all.request_no%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷品目ID
  TYPE l_shipping_inv_item_id        IS TABLE OF
                xxwsh_order_lines_all.shipping_inventory_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷品目
  TYPE l_shipping_item_code          IS TABLE OF
                xxwsh_order_lines_all.shipping_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- 数量
  TYPE l_quantity                    IS TABLE OF
                xxwsh_order_lines_all.quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 単位
  TYPE l_uom_code                    IS TABLE OF
                xxwsh_order_lines_all.uom_code%TYPE INDEX BY BINARY_INTEGER;
  -- 拠点依頼数量
  TYPE l_based_request_quantity      IS TABLE OF
                xxwsh_order_lines_all.based_request_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼品目ID
  TYPE l_request_item_id             IS TABLE OF
                xxwsh_order_lines_all.request_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼品目   
  TYPE l_request_item_code           IS TABLE OF
                xxwsh_order_lines_all.request_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- 重量
  TYPE l_weight                      IS TABLE OF
                xxwsh_order_lines_all.weight%TYPE INDEX BY BINARY_INTEGER;
  -- 容積
  TYPE l_capacity                    IS TABLE OF
                xxwsh_order_lines_all.capacity%TYPE INDEX BY BINARY_INTEGER;
  -- パレット重量
  TYPE l_pallet_weight               IS TABLE OF
                xxwsh_order_lines_all.pallet_weight%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_delete_flag                 IS TABLE OF
                xxwsh_order_lines_all.delete_flag%TYPE INDEX BY BINARY_INTEGER;
-- 2009/12/09 M.Miyagawa Add Start 本番障害#267
  --出荷依頼インタフェース済フラグ
  TYPE l_shipping_request_if_flg     IS TABLE OF
                xxwsh_order_lines_all.shipping_request_if_flg%TYPE INDEX BY BINARY_INTEGER;
  --出荷実績インタフェース済フラグ
  TYPE l_shipping_result_if_flg      IS TABLE OF
                xxwsh_order_lines_all.shipping_result_if_flg%TYPE INDEX BY BINARY_INTEGER;
-- 2009/12/09 M.Miyagawa Add End 本番障害#267
  TYPE l_created_by                  IS TABLE OF
                xxwsh_order_lines_all.created_by%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_creation_date               IS TABLE OF
                xxwsh_order_lines_all.creation_date%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_last_updated_by             IS TABLE OF
                xxwsh_order_lines_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_last_update_date            IS TABLE OF
                xxwsh_order_lines_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_last_update_login           IS TABLE OF
                xxwsh_order_lines_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_request_id                  IS TABLE OF
                xxwsh_order_lines_all.request_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_program_application_id      IS TABLE OF
                xxwsh_order_lines_all.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_program_id                  IS TABLE OF
                xxwsh_order_lines_all.program_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE l_program_update_date         IS TABLE OF
                xxwsh_order_lines_all.program_update_date%TYPE INDEX BY BINARY_INTEGER;
  ---------------------------------------------------
  --    受注ヘッダアドオン登録用項目テーブル型    ---
  ---------------------------------------------------
  -- 受注ヘッダアドオンID
  TYPE h_order_header_id             IS TABLE OF
                xxwsh_order_headers_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 受注タイプID
  TYPE h_order_type_id               IS TABLE OF
                xxwsh_order_headers_all.order_type_id%TYPE INDEX BY BINARY_INTEGER;
  -- 組織ID
  TYPE h_organization_id             IS TABLE OF
                xxwsh_order_headers_all.organization_id%TYPE INDEX BY BINARY_INTEGER;
  -- 最新フラグ
  TYPE h_latest_external_flag        IS TABLE OF
                xxwsh_order_headers_all.latest_external_flag%TYPE INDEX BY BINARY_INTEGER;
  -- 受注日
  TYPE h_ordered_date                IS TABLE OF
                xxwsh_order_headers_all.ordered_date%TYPE INDEX BY BINARY_INTEGER;
  -- 顧客ID
  TYPE h_customer_id                 IS TABLE OF
                xxwsh_order_headers_all.customer_id%TYPE INDEX BY BINARY_INTEGER;
  -- 顧客
  TYPE h_customer_code               IS TABLE OF
                xxwsh_order_headers_all.customer_code%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷先ID
  TYPE h_deliver_to_id               IS TABLE OF
                xxwsh_order_headers_all.deliver_to_id%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷先
  TYPE h_deliver_to                  IS TABLE OF
                xxwsh_order_headers_all.deliver_to%TYPE INDEX BY BINARY_INTEGER;
-- 2008/08/19 H.Itou Add Start T_S_611
  -- 運送業者ID
  TYPE h_career_id                  IS TABLE OF
                xxwsh_order_headers_all.career_id%TYPE INDEX BY BINARY_INTEGER;
  -- 運送業者
  TYPE h_freight_carrier_code       IS TABLE OF
                xxwsh_order_headers_all.freight_carrier_code%TYPE INDEX BY BINARY_INTEGER;
-- 2008/08/19 H.Itou Add End
  -- 配送区分
  TYPE h_shipping_method_code        IS TABLE OF
                xxwsh_order_headers_all.shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼No
  TYPE h_request_no                  IS TABLE OF
                xxwsh_order_headers_all.request_no%TYPE INDEX BY BINARY_INTEGER;
  -- ステータス
  TYPE h_req_status                  IS TABLE OF
                xxwsh_order_headers_all.req_status%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷予定日
  TYPE h_schedule_ship_date          IS TABLE OF
                xxwsh_order_headers_all.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷予定日
  TYPE h_schedule_arrival_date       IS TABLE OF
                xxwsh_order_headers_all.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;
  -- 通知ステータス
  TYPE h_notif_status                IS TABLE OF
                xxwsh_order_headers_all.notif_status%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷元ID
  TYPE h_deliver_from_id             IS TABLE OF
                xxwsh_order_headers_all.deliver_from_id%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷元保管場所
  TYPE h_deliver_from                IS TABLE OF
                xxwsh_order_headers_all.deliver_from%TYPE INDEX BY BINARY_INTEGER;
  -- 管轄拠点
  TYPE h_Head_sales_branch           IS TABLE OF
                xxwsh_order_headers_all.Head_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- 入力拠点
  TYPE h_input_sales_branch          IS TABLE OF
                xxwsh_order_headers_all.input_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- 商品区分
  TYPE h_prod_class                  IS TABLE OF
                xxwsh_order_headers_all.prod_class%TYPE INDEX BY BINARY_INTEGER;
  -- 合計数量
  TYPE h_sum_quantity                IS TABLE OF
                xxwsh_order_headers_all.sum_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 小口個数
  TYPE h_small_quantity              IS TABLE OF
                xxwsh_order_headers_all.small_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- ラベル枚数
  TYPE h_label_quantity              IS TABLE OF
                xxwsh_order_headers_all.label_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 重量積載効率
  TYPE h_loading_eff_weight          IS TABLE OF
                xxwsh_order_headers_all.loading_efficiency_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 容積積載効率
  TYPE h_loading_eff_capacity        IS TABLE OF
                xxwsh_order_headers_all.loading_efficiency_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- 基本重量
  TYPE h_based_weight                IS TABLE OF
                xxwsh_order_headers_all.based_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 基本容積
  TYPE h_based_capacity              IS TABLE OF
                xxwsh_order_headers_all.based_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- 積載重量合計
  TYPE h_sum_weight                  IS TABLE OF
                xxwsh_order_headers_all.sum_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 積載容積合計
  TYPE h_sum_capacity                IS TABLE OF
                xxwsh_order_headers_all.sum_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- 合計パレット重量
  TYPE h_sum_pallet_weight           IS TABLE OF
                xxwsh_order_headers_all.sum_pallet_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 重量容積区分
  TYPE h_weight_capacity_class       IS TABLE OF
                xxwsh_order_headers_all.weight_capacity_class%TYPE INDEX BY BINARY_INTEGER;
  -- 実績計上済区分
  TYPE h_actual_confirm_class        IS TABLE OF
                xxwsh_order_headers_all.actual_confirm_class%TYPE INDEX BY BINARY_INTEGER;
  -- 新規修正フラグ
  TYPE h_new_modify_flg              IS TABLE OF
                xxwsh_order_headers_all.new_modify_flg%TYPE INDEX BY BINARY_INTEGER;
  -- 成績管理部署
  TYPE h_per_management_dept         IS TABLE OF
                xxwsh_order_headers_all.performance_management_dept%TYPE INDEX BY BINARY_INTEGER;
  -- 画面更新日時
  TYPE h_screen_update_date          IS TABLE OF
                xxwsh_order_headers_all.screen_update_date%TYPE INDEX BY BINARY_INTEGER;
-- add start 1.7 uehara
  -- 物流担当確認依頼区分
  TYPE h_confirm_request_class       IS TABLE OF
                xxwsh_order_headers_all.confirm_request_class%TYPE INDEX BY BINARY_INTEGER;
  -- 運賃区分
  TYPE h_freight_charge_class        IS TABLE OF
                xxwsh_order_headers_all.freight_charge_class%TYPE INDEX BY BINARY_INTEGER;
  -- 契約外運賃区分
  TYPE h_no_cont_freight_class       IS TABLE OF
                xxwsh_order_headers_all.no_cont_freight_class%TYPE INDEX BY BINARY_INTEGER;
-- add end 1.7 uehara
  TYPE h_created_by                  IS TABLE OF
                xxwsh_order_headers_all.created_by%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_creation_date               IS TABLE OF
                xxwsh_order_headers_all.creation_date%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_last_updated_by             IS TABLE OF
                xxwsh_order_headers_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_last_update_date            IS TABLE OF 
               xxwsh_order_headers_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_last_update_login           IS TABLE OF
                xxwsh_order_headers_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_request_id                  IS TABLE OF
                xxwsh_order_headers_all.request_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_program_application_id      IS TABLE OF
                xxwsh_order_headers_all.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_program_id                  IS TABLE OF
                xxwsh_order_headers_all.program_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE h_program_update_date         IS TABLE OF
                xxwsh_order_headers_all.program_update_date%TYPE INDEX BY BINARY_INTEGER;
-- 2009/07/08 H.Itou Add Start 本番障害#1525
  TYPE ref_cursor                    IS REF CURSOR ; -- カーソル型
-- 2009/07/08 H.Itou Add End
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;
  gn_normal_cnt    NUMBER;
  gn_error_cnt     NUMBER;
  gn_warn_cnt      NUMBER;
--
--################################  固定部 END   ###############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  err_header_expt          EXCEPTION;               -- 共通関数エラー
--
  -- ==================================================
  -- ユーザー定義グローバル定数
  -- ==================================================
-- 2008/11/20 H.Itou Add Start 統合テスト指摘658
  -- 共通関数戻り値判定
  gn_status_normal   CONSTANT NUMBER := 0; -- 正常
  gn_status_error    CONSTANT NUMBER := 1; -- 異常
-- 2008/11/20 H.Itou Add End
  gv_pkg_name        CONSTANT VARCHAR2(15) := 'xxwsh400001c';          -- パッケージ名
  -- プロファイル
  gv_prf_m_org       CONSTANT VARCHAR2(50) := 'XXCMN_MASTER_ORG_ID';   -- XXCMN:マスタ組織
  gv_prf_tran        CONSTANT VARCHAR2(50) := 'XXWSH_TRAN_TYPE_PLAN';  -- XXWSH:出庫形態_引取計画
  -- エラーコード
  gv_application     CONSTANT VARCHAR2(5)  := 'XXWSH';                 -- アプリケーション
  gv_err_ktn         CONSTANT VARCHAR2(20) := 'APP-XXWSH-11001';
                                                          -- マスタチェックエラーメッセージ
  gv_err_yymm        CONSTANT VARCHAR2(20) := 'APP-XXWSH-11002';
                                                          -- マスタ書式エラーメッセージ
  gv_err_para        CONSTANT VARCHAR2(20) := 'APP-XXWSH-11004';
                                                          -- 必須入力Ｐ未設定エラーメッセージ
  gv_err_pro         CONSTANT VARCHAR2(20) := 'APP-XXWSH-11005';
                                                          -- プロファイル取得エラーメッセージ
  gv_err_ord         CONSTANT VARCHAR2(20) := 'APP-XXWSH-11006';
                                                          -- 受注タイプ取得エラーメッセージ
  gv_err_cik         CONSTANT VARCHAR2(20) := 'APP-XXCMN-10121';
                                                          -- クイックコード取得エラーメッセージ
-- 2009/07/08 H.Itou Add Start 本番障害#1525
  gv_err_item        CONSTANT VARCHAR2(20) := 'APP-XXWSH-10026';
                                                          -- 品目カテゴリ割当未設定エラーメッセージ
-- 2009/07/08 H.Itou Add End
--
  gv_tkn_msg_org     CONSTANT VARCHAR2(20) := 'XXCMN:マスタ組織';
  gv_tkn_msg_tran    CONSTANT VARCHAR2(25) := 'XXWSH:出庫形態_引取計画';
  gv_tkn_msg_yymm    CONSTANT VARCHAR2(8)  := '対象年月';
  gv_tkn_msg_ktn     CONSTANT VARCHAR2(8)  := '管轄拠点';
  -- トークン
  gv_tkn_in_parm     CONSTANT VARCHAR2(10) := 'IN_PARAM';
  gv_tkn_prof_name   CONSTANT VARCHAR2(10) := 'PROF_NAME';
  gv_tkn_yymm        CONSTANT VARCHAR2(10) := 'YYMM';
  gv_tkn_kyoten      CONSTANT VARCHAR2(10) := 'KYOTEN';
  gv_tkn_order_type  CONSTANT VARCHAR2(10) := 'ORDER_TYPE';
  gv_tkn_lookup_type CONSTANT VARCHAR2(15) := 'LOOKUP_TYPE';
  gv_tkn_meaning     CONSTANT VARCHAR2(10) := 'MEANING';
-- 2009/07/08 H.Itou Add Start 本番障害#1525
  gv_tkn_item_no     CONSTANT VARCHAR2(10) := 'ITEM_NO';
-- 2009/07/08 H.Itou Add End
  -- エラーメッセージリスト項目
  gv_tkn_msg_hfn     CONSTANT VARCHAR2(1)  := '-';
  gv_tkn_msg_err     CONSTANT VARCHAR2(6)  := 'エラー';
  gv_tkn_msg_war     CONSTANT VARCHAR2(4)  := '警告';
  gv_tkn_msg_1       CONSTANT VARCHAR2(50) := '「売上対象区分」に「1」以外がセットされています';
  -- 2008/07/30 Mod ↓
--  gv_tkn_msg_2       CONSTANT VARCHAR2(50) := '「廃止区分」に「D」がセットされています';
  gv_tkn_msg_2       CONSTANT VARCHAR2(50) := '「廃止区分」に「1」がセットされています';
  -- 2008/07/30 Mod ↓
  gv_tkn_msg_3       CONSTANT VARCHAR2(50) := '「率区分」に「0」以外がセットされています';
  gv_tkn_msg_5       CONSTANT VARCHAR2(60) := '「中止客申請フラグ」に「0」以外がセットされています';
  gv_tkn_msg_6       CONSTANT VARCHAR2(50) := '稼働日チェックエラー';
  gv_tkn_msg_7       CONSTANT VARCHAR2(50) := 'リードタイム算出';
  gv_tkn_msg_8       CONSTANT VARCHAR2(50) := '配送リードタイムを満たせません';
  gv_tkn_msg_9       CONSTANT VARCHAR2(50) := '引取変更リードタイムを満たせません';
  gv_tkn_msg_10      CONSTANT VARCHAR2(50) := '最大配送区分取得エラー';
  gv_tkn_msg_11      CONSTANT VARCHAR2(50) := '在庫会計期間クローズエラー';
  gv_tkn_msg_12      CONSTANT VARCHAR2(50) := '出荷可能品目ではありません(出荷区分＝「否」)';
  gv_tkn_msg_13      CONSTANT VARCHAR2(50) := '物流構成として登録されていません';
  gv_tkn_msg_14      CONSTANT VARCHAR2(50) := '出荷数制限(商品部)エラー：';
  gv_tkn_msg_15      CONSTANT VARCHAR2(50) := '出荷数制限(物流部)エラー：';
  gv_tkn_msg_16      CONSTANT VARCHAR2(50) := '出荷数制限(商品部)数量オーバーエラー';
  gv_tkn_msg_17      CONSTANT VARCHAR2(50) := '出荷数制限(物流部)数量オーバーエラー';
  gv_tkn_msg_18      CONSTANT VARCHAR2(50) := '出荷数制限(物流部)出荷停止日エラー';
  gv_tkn_msg_19      CONSTANT VARCHAR2(50) := '「『数量』が『出荷入数』の整数倍ではありません」';
  gv_tkn_msg_20      CONSTANT VARCHAR2(50) := '積載オーバーエラー';
  gv_tkn_msg_21      CONSTANT VARCHAR2(50) := '「『数量』が『入数』の整数倍ではありません」';
  gv_tkn_msg_22      CONSTANT VARCHAR2(50) := '依頼No採番エラー：';
  gv_tkn_msg_23      CONSTANT VARCHAR2(50) := '引当対象外の出庫元倉庫です';
--
  -- 2008/07/30 Add ↓
  gv_tkn_msg_24      CONSTANT VARCHAR2(50) := 'ケース入数に0より大きい値を設定して下さい。';
  -- 2008/07/30 Add ↑
-- 2008/10/09 H.Itou Add Start 統合テスト指摘118
  gv_tkn_msg_25      CONSTANT VARCHAR2(50) := '１依頼内に同一品目が重複しています';
-- 2008/10/09 H.Itou Add End
-- 2008/11/20 H.Itou Add Start 統合テスト指摘658
  gv_tkn_msg26       CONSTANT VARCHAR2(50)   := '稼働日取得エラー';
-- 2008/11/20 H.Itou Add End
-- クイックコード
  gv_ship_method     CONSTANT VARCHAR2(20) := 'XXCMN_SHIP_METHOD';
  gv_tr_status       CONSTANT VARCHAR2(25) := 'XXWSH_TRANSACTION_STATUS';
  gv_notif_status    CONSTANT VARCHAR2(20) := 'XXWSH_NOTIF_STATUS';
--
  gv_all_item        CONSTANT VARCHAR2(7)  := 'ZZZZZZZ'; -- 全品目
--
  gv_yes             CONSTANT VARCHAR2(1)  := 'Y';
  gv_no              CONSTANT VARCHAR2(1)  := 'N';
  gv_0               CONSTANT VARCHAR2(1)  := '0';
  gv_1               CONSTANT VARCHAR2(1)  := '1';
  gv_2               CONSTANT VARCHAR2(1)  := '2';
  gv_3               CONSTANT VARCHAR2(1)  := '3';
  gv_4               CONSTANT VARCHAR2(1)  := '4';
  gv_6               CONSTANT VARCHAR2(1)  := '6';
  gv_9               CONSTANT VARCHAR2(1)  := '9';
--
  -- 2008/07/30 Mod ↓
--  gv_delete          CONSTANT VARCHAR2(1)  := 'D';
  gv_delete          CONSTANT VARCHAR2(1)  := '1';
  -- 2008/07/30 Mod ↑
  gv_h_plan          CONSTANT VARCHAR2(2)  := '01';
--
  gv_ship_st         CONSTANT VARCHAR2(6)  := '入力中';
  gv_notice_st       CONSTANT VARCHAR2(6)  := '未通知';
  -- エラーリスト項目名
  gv_name_kind       CONSTANT VARCHAR2(4)  := '種別';
  gv_name_dec        CONSTANT VARCHAR2(4)  := '確定';
  gv_name_req_no     CONSTANT VARCHAR2(8)  := '依頼Ｎｏ';
  gv_name_kyoten     CONSTANT VARCHAR2(8)  := '管轄拠点';
  gv_name_item_a     CONSTANT VARCHAR2(4)  := '品目';
  gv_name_qty        CONSTANT VARCHAR2(4)  := '数量';
  gv_name_ship_date  CONSTANT VARCHAR2(6)  := '出庫日';
  gv_name_arr_date   CONSTANT VARCHAR2(4)  := '着日';
  gv_name_err_msg    CONSTANT VARCHAR2(16) := 'エラーメッセージ';
  gv_name_err_clm    CONSTANT VARCHAR2(10) := 'エラー項目';
  gv_line            CONSTANT VARCHAR2(25) := '-------------------------';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_sysdate         DATE;              -- システム現在日付
  gd_yyyymm          DATE;              -- 対象年月
  gv_name_m_org      VARCHAR2(20);      -- マスタ組織
  gv_name_item       VARCHAR2(20);      -- 商品区分
  gv_name_tran       VARCHAR2(20);      -- 出庫形態_引取計画
  gv_name_ktn        VARCHAR2(20);      -- 管轄拠点
  gv_err_flg         VARCHAR2(1);       -- エラー確認用フラグ
  gv_err_sts         VARCHAR2(1);       -- 共通エラーメッセージ 終了ST確認用F
--
  gd_work_day        DATE;              -- 稼働日
  gd_ship_day        DATE;              -- 出荷予定日
  gd_past_day        DATE;              -- 過去日
  gv_req_no          VARCHAR2(12);      -- 採番したNo
  gv_leadtime        VARCHAR2(20);      -- 生産物流LT/引取変更LT
  gv_delivery_lt     VARCHAR2(20);      -- 配送リードタイム
  gv_max_kbn         VARCHAR2(2);       -- 最大配送区分
  gv_opm_c_p         VARCHAR2(6);       -- OPM在庫会計期間 CLOSE最大年月
  gv_over_kbn        VARCHAR2(1);       -- 積載オーバー区分
  gv_ship_way        VARCHAR2(2);       -- 出荷方法
  gv_mix_ship        VARCHAR2(2);       -- 混載配送区分
  gn_drink_we        NUMBER;            -- ドリンク積載重量
  gn_leaf_we         NUMBER;            -- リーフ積載重量
  gn_drink_ca        NUMBER;            -- ドリンク積載容積
  gn_leaf_ca         NUMBER;            -- リーフ積載容積
  gn_prt_max         NUMBER;            -- パレット最大枚数
  gn_retrun          NUMBER;            -- 返り値
  gn_ttl_we          NUMBER;            -- 合計重量
  gn_ttl_ca          NUMBER;            -- 合計容積
  gn_ttl_prt_we      NUMBER;            -- 合計パレット重量
  gn_detail_we       NUMBER;            -- 明細重量
  gn_detail_ca       NUMBER;            -- 明細容積
  gn_ship_amount     NUMBER;            -- 出荷単位換算数
  gn_we_loading      NUMBER;            -- 重量積載効率
  gn_ca_loading      NUMBER;            -- 容積積載効率
  gn_we_dammy        NUMBER;            -- 重量積載効率(ダミー)
  gn_ca_dammy        NUMBER;            -- 容積積載効率(ダミー)
--
  gn_i               NUMBER;            -- LOOPカウント用
  gn_headers_seq     NUMBER;            -- 受注ヘッダアドオンID_SEQ
  gn_lines_seq       NUMBER;            -- 受注明細アドオンID_SEQ
--
  -- WHOカラム取得用
  gn_created_by      NUMBER;            -- 作成者
  gd_creation_date   DATE;              -- 作成日
  gd_last_upd_date   DATE;              -- 最終更新日
  gn_last_upd_by     NUMBER;            -- 最終更新者
  gn_last_upd_login  NUMBER;            -- 最終更新ログイン
  gn_request_id      NUMBER;            -- 要求ID
  gn_prog_appl_id    NUMBER;            -- プログラムアプリケーションID
  gn_prog_id         NUMBER;            -- プログラムID
  gd_prog_upd_date   DATE;              -- プログラム更新日
--
  gv_err_report      VARCHAR2(5000);
--
  gn_cut             NUMBER DEFAULT 0;  -- エラーメッセージ用カウント
  gn_line_number     NUMBER DEFAULT 0;  -- 明細番号
  gn_ttl_amount      NUMBER DEFAULT 0;  -- 合計数量
  gn_ttl_ship_am     NUMBER DEFAULT 0;  -- 出荷単位換算数
  gn_h_ttl_weight    NUMBER DEFAULT 0;  -- 積載重量合計
  gn_h_ttl_capa      NUMBER DEFAULT 0;  -- 積載容積合計
  gn_h_ttl_pallet    NUMBER DEFAULT 0;  -- 合計パレット重量
--
  gn_item_cnt        NUMBER DEFAULT 0;  -- 対象引取計画件数(品目単位)
  gn_req_cnt         NUMBER DEFAULT 0;  -- 出荷依頼作成件数(依頼Ｎｏ単位)
  gn_line_cnt        NUMBER DEFAULT 0;  -- 出荷依頼作成明細件数(依頼明細単位)
--
  gn_l_cnt           NUMBER DEFAULT 0;  -- 受注明細アドオン作成用レコード用カウント
  gn_h_cnt           NUMBER DEFAULT 0;  -- 受注ヘッダアドオン作成用レコード用カウント
--
  gv_odr_type        xxwsh_oe_transaction_types2_v.transaction_type_id%TYPE; -- 受注タイプＩＤ
  gv_ktn             mrp_forecast_designators.attribute3%TYPE;               -- 拠点
  gv_ship_fr         mrp_forecast_designators.attribute2%TYPE;               -- 出荷元
  gv_for_date        mrp_forecast_dates.forecast_date%TYPE;                  -- 着荷予定日
  gv_wei_kbn         xxcmn_item_mst2_v.weight_capacity_class%TYPE;           -- 重量容積区分
  gr_ship_st         xxcmn_lookup_values2_v.lookup_code%TYPE;                -- 出荷依頼ステータス
  gr_notice_st       xxcmn_lookup_values2_v.lookup_code%TYPE;                -- 通知ステータス
--
  gr_param           rec_param_data;    -- 入力パラメータ
  gt_to_plan         tab_data_to_plan;  -- 引取計画情報取得データ
  gt_err_msg         tab_data_err_msg;  -- エラーメッセージ出力用
--
  -- 受注明細アドオン登録用項目
  gt_l_order_line_id           l_order_line_id;          -- 受注明細アドオンID
  gt_l_order_header_id         l_order_header_id;        -- 受注ヘッダアドオンID
  gt_l_order_line_number       l_order_line_number;      -- 明細番号
  gt_l_request_no              l_request_no;             -- 依頼No
  gt_l_shipping_inv_item_id    l_shipping_inv_item_id;   -- 出荷品目ID
  gt_l_shipping_item_code      l_shipping_item_code;     -- 出荷品目
  gt_l_quantity                l_quantity;               -- 数量
  gt_l_uom_code                l_uom_code;               -- 単位
  gt_l_based_request_quantity  l_based_request_quantity; -- 拠点依頼数量
  gt_l_request_item_id         l_request_item_id;        -- 依頼品目ID
  gt_l_request_item_code       l_request_item_code;      -- 依頼品目
  gt_l_weight                  l_weight;                 -- 重量
  gt_l_capacity                l_capacity;               -- 容積   
  gt_l_pallet_weight           l_pallet_weight;          -- パレット重量
  gt_l_delete_flag             l_delete_flag;
-- 2009/12/09 M.Miyagawa Add Start 本番障害#267
  gt_l_shipping_request_if_flg l_shipping_request_if_flg;--出荷依頼インタフェース済フラグ
  gt_l_shipping_result_if_flg  l_shipping_result_if_flg; --出荷実績インタフェース済フラグ
-- 2009/12/09 M.Miyagawa Add End 本番障害#267
  gt_l_created_by              l_created_by;
  gt_l_creation_date           l_creation_date;
  gt_l_last_updated_by         l_last_updated_by;
  gt_l_last_update_date        l_last_update_date;
  gt_l_last_update_login       l_last_update_login;
  gt_l_request_id              l_request_id;
  gt_l_program_application_id  l_program_application_id;
  gt_l_program_id              l_program_id;
  gt_l_program_update_date     l_program_update_date;
  -- 受注ヘッダアドオン登録用項目
  gt_h_order_header_id         h_order_header_id;        -- 受注ヘッダアドオンID
  gt_h_order_type_id           h_order_type_id;          -- 受注タイプID
  gt_h_organization_id         h_organization_id;        -- 組織ID
  gt_h_latest_external_flag    h_latest_external_flag;   -- 最新フラグ
  gt_h_ordered_date            h_ordered_date;           -- 受注日
  gt_h_customer_id             h_customer_id;            -- 顧客ID
  gt_h_customer_code           h_customer_code;          -- 顧客
  gt_h_deliver_to_id           h_deliver_to_id;          -- 配送先ID
  gt_h_deliver_to              h_deliver_to;             -- 配送先
-- 2008/08/19 H.Itou Add Start T_S_611
  gt_h_career_id               h_career_id;              -- 運送業者ID
  gt_h_freight_carrier_code    h_freight_carrier_code;   -- 運送業者
-- 2008/08/19 H.Itou Add End
  gt_h_shipping_method_code    h_shipping_method_code;   -- 配送区分
  gt_h_request_no              h_request_no;             -- 依頼No
  gt_h_req_status              h_req_status;             -- ステータス
  gt_h_schedule_ship_date      h_schedule_ship_date;     -- 出荷予定日
  gt_h_schedule_arrival_date   h_schedule_arrival_date;  -- 着荷予定日
  gt_h_notif_status            h_notif_status;           -- 通知ステータス
  gt_h_deliver_from_id         h_deliver_from_id;        -- 出荷元ID
  gt_h_deliver_from            h_deliver_from;           -- 出荷元保管場所
  gt_h_Head_sales_branch       h_Head_sales_branch;      -- 管轄拠点
  gt_h_input_sales_branch      h_input_sales_branch;     -- 入力拠点
  gt_h_prod_class              h_prod_class;             -- 商品区分
  gt_h_sum_quantity            h_sum_quantity;           -- 合計数量
  gt_h_small_quantity          h_small_quantity;         -- 小口個数
  gt_h_label_quantity          h_label_quantity;         -- ラベル枚数
  gt_h_loading_eff_weight      h_loading_eff_weight;     -- 重量積載効率
  gt_h_loading_eff_capacity    h_loading_eff_capacity;   -- 容積積載効率
  gt_h_based_weight            h_based_weight;           -- 基本重量
  gt_h_based_capacity          h_based_capacity;         -- 基本容積
  gt_h_sum_weight              h_sum_weight;             -- 積載重量合計
  gt_h_sum_capacity            h_sum_capacity;           -- 積載容積合計
  gt_h_sum_pallet_weight       h_sum_pallet_weight;      -- 合計パレット重量
  gt_h_weight_capacity_class   h_weight_capacity_class;  -- 重量容積区分
  gt_h_actual_confirm_class    h_actual_confirm_class ;  -- 実績計上済区分
  gt_h_new_modify_flg          h_new_modify_flg;         -- 新規修正フラグ
  gt_h_per_management_dept     h_per_management_dept;    -- 成績管理部署
  gt_h_screen_update_date      h_screen_update_date;     -- 画面更新日時
-- add start 1.7 uehara
  gt_h_confirm_request_class   h_confirm_request_class;  -- 物流担当確認依頼区分
  gt_h_freight_charge_class    h_freight_charge_class;   -- 運賃区分
  gt_h_no_cont_freight_class   h_no_cont_freight_class;  -- 契約外運賃区分
-- add end 1.7 uehara
  gt_h_created_by              h_created_by;
  gt_h_creation_date           h_creation_date;
  gt_h_last_updated_by         h_last_updated_by;
  gt_h_last_update_date        h_last_update_date;
  gt_h_last_update_login       h_last_update_login;
  gt_h_request_id              h_request_id;
  gt_h_program_application_id  h_program_application_id;
  gt_h_program_id              h_program_id;
  gt_h_program_update_date     h_program_update_date;
--
--#####################  固定共通例外宣言部 START   ####################
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
--###########################  固定部 END   ############################
--
  /**********************************************************************************
   * Procedure Name   : pro_err_list_make
   * Description      : エラーリスト作成
   ***********************************************************************************/
  PROCEDURE pro_err_list_make
    (
      iv_kind          IN VARCHAR2     --   エラー種別
     ,iv_dec           IN VARCHAR2     --   確定処理でのチェック
     ,iv_req_no        IN VARCHAR2     --   依頼No
     ,iv_kyoten        IN VARCHAR2     --   管轄拠点
     ,iv_item          IN VARCHAR2     --   品目
     ,in_qty           IN NUMBER       --   数量
     ,iv_ship_date     IN VARCHAR2     --   出庫日
     ,iv_arrival_date  IN VARCHAR2     --   着日
     ,iv_err_msg       IN VARCHAR2     --   エラーメッセージ
     ,iv_err_clm       IN VARCHAR2     --   エラー項目
-- 2008/08/18 H.Itou Add Start
     ,in_msg_seq       IN NUMBER DEFAULT NULL -- メッセージ格納SEQ
-- 2008/08/18 H.Itou Add End
     ,ov_errbuf       OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode      OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg       OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_err_list_make'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_err_msg      VARCHAR2(5000);
    ln_qty          NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 数量がNULLの場合、０表示
    IF (in_qty IS NULL) THEN
      ln_qty := NVL(in_qty,0);
    ELSE
      ln_qty := in_qty;
    END IF;
--
    ---------------------------------
    -- 共通エラーメッセージの作成  --
    ---------------------------------
-- 2008/08/18 H.Itou Del Start エラーメッセージ格納直前に移動
--    -- テーブルカウント
--    gn_cut := gn_cut + 1;
-- 2008/08/18 H.Itou Del End
--
    lv_err_msg := iv_kind         || CHR(9) || iv_dec     || CHR(9) || iv_req_no    || CHR(9) ||
                  iv_kyoten       || CHR(9) || iv_item    || CHR(9) ||
                  TO_CHAR(ln_qty,'FM999,999,990.000') || CHR(9) || iv_ship_date || CHR(9) ||
                  iv_arrival_date || CHR(9) || iv_err_msg || CHR(9) || iv_err_clm;
--
-- 2008/08/18 H.Itou Add Start
    -- メッセージ格納SEQに値がある場合、指定箇所にメッセージをセット
    IF (in_msg_seq IS NOT NULL) THEN
      gt_err_msg(in_msg_seq).err_msg  := lv_err_msg;
--
    -- それ以外は、テーブルカウントを進めてセット
    ELSE
      -- テーブルカウント
      gn_cut := gn_cut + 1;
-- 2008/08/18 H.Itou Add End
      -- 共通エラーメッセージ格納
      gt_err_msg(gn_cut).err_msg  := lv_err_msg;
-- 2008/08/18 H.Itou Add Start
    END IF;
-- 2008/08/18 H.Itou Add End
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_err_list_make;
--
  /**********************************************************************************
   * Procedure Name   : pro_get_cus_option
   * Description      : 関連データ取得 (A-1)
   ***********************************************************************************/
  PROCEDURE pro_get_cus_option
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_cus_option'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- WHOカラム取得
    gn_created_by     := FND_GLOBAL.USER_ID;           -- 作成者
--    gd_creation_date  := gd_sysdate;                   -- 作成日
    gd_creation_date  := SYSDATE;                   -- 作成日
    gn_last_upd_by    := FND_GLOBAL.USER_ID;           -- 最終更新日
--    gd_last_upd_date  := gd_sysdate;                   -- 最終更新者
    gd_last_upd_date  := SYSDATE;                   -- 最終更新者
    gn_last_upd_login := FND_GLOBAL.LOGIN_ID;          -- 最終更新ログイン
    gn_request_id     := FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
    gn_prog_appl_id   := FND_GLOBAL.PROG_APPL_ID;      -- プログラムアプリケーションID
    gn_prog_id        := FND_GLOBAL.CONC_PROGRAM_ID;   -- プログラムID
--    gd_prog_upd_date  := gd_sysdate;                   -- プログラム更新日
    gd_prog_upd_date  := SYSDATE;                   -- プログラム更新日
--
    --------------------------------------------------
    -- クイックコードから出荷依頼ステータス情報取得 --
    --------------------------------------------------
    BEGIN
--
      -- 出荷依頼ステータス[入力中]コード抽出
      SELECT xlvv.lookup_code
      INTO   gr_ship_st
      FROM   xxcmn_lookup_values_v  xlvv  -- クイックコード情報 V
      WHERE  xlvv.lookup_type = gv_tr_status
      AND    xlvv.meaning     = gv_ship_st;
--
    EXCEPTION
      -- クイックコードが存在しない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( 'XXCMN'
                                                       ,gv_err_cik          -- クイックＣ取得エラー
                                                       ,gv_tkn_lookup_type  -- トークン
                                                       ,gv_tr_status
                                                       ,gv_tkn_meaning      -- トークン
                                                       ,gv_ship_st
                                                      )
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
    END;
--
    --------------------------------------------------
    -- クイックコードから通知ステータス情報取得 --
    --------------------------------------------------
    BEGIN
--
      -- 通知ステータス[未通知]コード抽出
      SELECT xlvv.lookup_code
      INTO   gr_notice_st
      FROM   xxcmn_lookup_values_v  xlvv  -- クイックコード情報 V
      WHERE  xlvv.lookup_type = gv_notif_status
      AND    xlvv.meaning     = gv_notice_st;
--
    EXCEPTION
      -- クイックコードが存在しない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( 'XXCMN'
                                                       ,gv_err_cik          -- クイックＣ取得エラー
                                                       ,gv_tkn_lookup_type  -- トークン
                                                       ,gv_notif_status
                                                       ,gv_tkn_meaning      -- トークン
                                                       ,gv_notice_st
                                                      )
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
    END;
--
    ------------------------------------------
    -- プロファイルからマスタ組織取得
    ------------------------------------------
    gv_name_m_org := SUBSTRB(FND_PROFILE.VALUE(gv_prf_m_org),1,20);
    -- 取得エラー時
    IF (gv_name_m_org IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application    -- 'XXWSH'
                                                     ,gv_err_pro        -- プロファイル取得エラー
                                                     ,gv_tkn_prof_name  -- トークン
                                                     ,gv_tkn_msg_org    -- メッセージ
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------------
    -- プロファイルから出庫形態_引取計画取得
    ------------------------------------------
    gv_name_tran := SUBSTRB(FND_PROFILE.VALUE(gv_prf_tran),1,30);
--
    -- 取得エラー時
    IF (gv_name_tran IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application    -- 'XXWSH'
                                                     ,gv_err_pro        -- プロファイル取得エラー
                                                     ,gv_tkn_prof_name  -- トークン
                                                     ,gv_tkn_msg_tran   -- メッセージ
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- 取得した場合は受注タイプ情報VIEWから受注タイプIDを抽出する
    BEGIN
--
      SELECT xettv.transaction_type_id           -- 引取タイプID
      INTO   gv_odr_type                         -- 受注タイプID
      FROM   xxwsh_oe_transaction_types_v  xettv    -- 受注タイプ情報 V
      WHERE  xettv.transaction_type_name  = gv_name_tran;
--
    EXCEPTION
      -- 受注タイプIDが取得不可な場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application    -- 'XXWSH'
                                                       ,gv_err_ord        -- 受注タイプ取得エラー
                                                       ,gv_tkn_order_type -- トークン
                                                       ,gv_name_tran      -- プロファイル
                                                      )
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
    END;
-- 2009/01/30 H.Itou Add Start 本番障害#994対応 クローズ最大年月は変わらないので、A-1で取得する。
    ----------------------------------------------
    -- クローズの最大年月取得
    ----------------------------------------------
    gv_opm_c_p := xxcmn_common_pkg.get_opminv_close_period;
-- 2009/01/30 H.Itou Add End
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_get_cus_option;
--
  /**********************************************************************************
   * Procedure Name   : pro_param_chk
   * Description      : 入力パラメータチェック   (A-2)
   ***********************************************************************************/
  PROCEDURE pro_param_chk
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_param_chk'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_cnt    NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------------------
    -- 入力Ｐ「対象年月」の取得
    ------------------------------------------
    -- 取得エラー時
    IF (gr_param.yyyymm IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                     ,gv_err_para        -- 必須入力Ｐ未設定エラー
                                                     ,gv_tkn_in_parm     -- トークン
                                                     ,gv_tkn_msg_yymm    -- メッセージ
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- 入力Ｐ「対象年月」の書式変換(YYYYMM)
    gd_yyyymm := FND_DATE.STRING_TO_DATE(gr_param.yyyymm,'YYYYMM');
    -- 変換エラー時
    IF (gd_yyyymm IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                     ,gv_err_yymm        -- マスタ書式エラー
                                                     ,gv_tkn_yymm        -- トークン
                                                     ,gr_param.yyyymm    -- 入力Ｐ[対象年月]
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------------
    -- 入力Ｐ「管轄拠点」の取得
    ------------------------------------------
/* 2008/07/30 Del ↓
    -- 取得エラー時
    IF (gr_param.base IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                     ,gv_err_para        -- 必須入力Ｐ未設定エラー
                                                     ,gv_tkn_in_parm     -- トークン
                                                     ,gv_tkn_msg_ktn     -- メッセージ
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
2008/07/30 Del ↑ */
--
    -- 2008/07/30 Add ↓
    -- 入力Ｐ「管轄拠点」が入力されていたら
    IF (gr_param.base IS NOT NULL) THEN
    -- 2008/07/30 Add ↑
--
      ------------------------------------------------------------------------
      -- 顧客マスタ・パーティマスタに拠点が登録されているかどうかの判定
      ------------------------------------------------------------------------
      SELECT COUNT(account_number)
      INTO   ln_cnt
      FROM   xxcmn_parties_v    -- パーティ情報 V
      WHERE  account_number      = gr_param.base  -- 入力Ｐ[管轄拠点]
      AND    customer_class_code = gv_1           -- '拠点'を示す「コード区分」
      AND    ROWNUM              = 1;
--
      -- 入力Ｐ[管轄拠点]が顧客マスタに存在しない場合
      IF (ln_cnt = 0) THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                       ,gv_err_ktn         -- マスタ書式エラー
                                                       ,gv_tkn_kyoten      -- トークン
                                                       ,gr_param.base      -- 入力Ｐ[管轄拠点]
                                                      )
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    -- 2008/07/30 Add ↓
    END IF;
    -- 2008/07/30 Add ↑
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_param_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_get_to_plan
   * Description      : 引取計画情報抽出  (A-3)
   ***********************************************************************************/
  PROCEDURE pro_get_to_plan
    (
      ot_to_plan    OUT NOCOPY tab_data_to_plan   --   取得レコード群
     ,ov_errbuf     OUT VARCHAR2                  --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2                  --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2                  --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_to_plan'; -- プログラム名
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
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    CURSOR cur_get_to_plan
    IS
      SELECT mfds.forecast_designator       AS for_name   -- フォーキャスト名
            ,mfds.attribute3                AS ktn        -- 拠点
            ,mfd.forecast_date              AS for_date   -- 着荷予定日
            ,xcasv.ship_to_no               AS ship_t_no  -- 配送先
            ,xcasv.party_site_id            AS p_s_site   -- 配送先ID
            ,xcav.party_number              AS par_num    -- 顧客
            ,xcav.party_id                  AS par_id     -- 顧客ID
            ,mfds.attribute2                AS ship_fr    -- 出荷元
            ,xilv.inventory_location_id     AS ship_id    -- 出荷元ID
            ,ximv.item_no                   AS item_no    -- 品目
            ,ximv.inventory_item_id         AS item_id    -- 品目ID
            ,mfd.original_forecast_quantity AS amount     -- 数量
            ,ximv.item_um                   AS item_um    -- 単位
            ,ximv.num_of_cases              AS case_am    -- 入数
            ,TO_NUMBER(ximv.num_of_deliver) AS ship_am    -- 出荷入数
            ,xicv.prod_class_code           AS skbn       -- 商品区分
            ,ximv.weight_capacity_class     AS wei_kbn    -- 重量容積区分
            ,ximv.ship_class                AS out_kbn    -- 出荷区分
            ,xicv.item_class_code           AS item_kbn   -- 品目区分
            ,ximv.sales_div                 AS sale_kbn   -- 売上対象区分
            ,ximv.obsolete_class            AS end_kbn    -- 廃止区分
            ,ximv.rate_class                AS rit_kbn    -- 率区分
            ,xcav.cust_enable_flag          AS no_flg     -- 中止客申請フラグ
            ,ximv.conv_unit                 AS conv_unit  -- 入出庫換算単位
            ,xilv.allow_pickup_flag         AS a_p_flg    -- 出荷引当対象フラグ
-- 2008/08/18 H.Itou Add Start
            ,NULL                                         -- 積載効率(重量)メッセージ格納SEQ
            ,NULL                                         -- 積載効率(容積)メッセージ格納SEQ
-- 2008/08/18 H.Itou Add End
-- 2008/10/09 H.Itou Add Start 統合テスト指摘240
            ,NULL                                         -- 品目重複メッセージ格納SEQ
-- 2008/10/09 H.Itou Add End
-- 2008/08/19 H.Itou Add T_S_611
            ,xcv.party_id                   AS career_id            -- 運送業者ID
            ,xcv.party_number               AS freight_carrier_code -- 運送業者
-- 2008/08/19 H.Itou Add End
      FROM  mrp_forecast_designators  mfds   -- フォーキャスト名        T
-- 2009/01/30 H.Itou Add Start 本番障害#994対応 品目IDはフォーキャスト日付から取得できるため、削除。
--           ,mrp_forecast_items        mfi    -- フォーキャスト品目      T
-- 2009/01/30 H.Itou Add End
           ,mrp_forecast_dates        mfd    -- フォーキャスト日付      T
           ,xxcmn_item_locations_v   xilv    -- OPM保管場所情報         V
           ,xxcmn_cust_accounts_v    xcav    -- 顧客情報                V
           ,xxcmn_cust_acct_sites_v  xcasv   -- 顧客サイト情報          V
           ,xxcmn_item_categories5_v  xicv   -- OPM品目カテゴリ割当情報 V
           ,xxcmn_item_mst2_v         ximv   -- OPM品目情報             V
-- 2008/08/19 H.Itou Add T_S_611
           ,xxcmn_carriers_v          xcv    -- 運送業者情報            V
-- 2008/08/19 H.Itou Add End
      WHERE mfds.attribute1                     = gv_h_plan                -- 引取計画 '01'
-- 2008/07/30 Mod ↓
/*
      AND   mfds.attribute3                     = gr_param.base            -- 入力Ｐ[管轄拠点]
*/
      AND  ((gr_param.base IS NULL)
       OR   (mfds.attribute3                    = gr_param.base))          -- 入力Ｐ[管轄拠点]
-- 2008/07/30 Mod ↓
      AND   mfds.attribute2                     = xilv.segment1            -- 保管倉庫コード
      AND   mfds.forecast_designator            = mfd.forecast_designator  -- フォーキャスト名
-- 2009/01/30 H.Itou Del Start 本番障害#994対応
--      AND   mfi.forecast_designator             = mfds.forecast_designator -- フォーキャスト名
-- 2009/01/30 H.Itou Del End
      AND   TO_CHAR(mfd.forecast_date,'YYYYMM') = gr_param.yyyymm          -- 入力Ｐ[対象年月]
      AND   mfd.organization_id                 = mfds.organization_id     -- 組織ID
-- 2009/01/30 H.Itou Del Start 本番障害#994対応
--      AND   mfds.organization_id                = mfi.organization_id      -- 組織ID
--      AND   mfd.inventory_item_id               = mfi.inventory_item_id    -- 品目ID
-- 2009/01/30 H.Itou Del End
-- 2009/01/30 H.Itou Mod Start 本番障害#994対応
--      AND   ximv.inventory_item_id              = mfi.inventory_item_id    -- 品目ID
      AND   ximv.inventory_item_id              = mfd.inventory_item_id    -- 品目ID
-- 2009/01/30 H.Itou Mod End 本番障害#994対応
      AND   xcav.account_number                 = mfds.attribute3          -- 拠点
      AND   xcav.customer_class_code            = gv_1                     -- 顧客区分
      AND   xcav.order_auto_code                = gv_1                     -- 出荷依頼自動作成区分
      AND   xcav.cust_account_id                = xcasv.cust_account_id    -- 顧客ID
      AND   xcasv.primary_flag                  = gv_yes                   -- 主フラグ 'Y'
      AND   xcav.party_id                       = xcasv.party_id           -- パーティID
      AND   xicv.item_id                        = ximv.item_id             -- 品目ID
      AND   xicv.prod_class_code                = gv_1                     -- 'リーフ'
      AND   ximv.start_date_active             <= gd_sysdate
      AND   ximv.end_date_active               >= gd_sysdate
-- 2008/08/19 H.Itou Add T_S_611
      AND   xilv.frequent_mover                 = xcv.party_number(+)      -- 代表運送会社
-- 2008/08/19 H.Itou Add End
      ORDER BY mfds.attribute3             -- 拠点
              ,mfds.attribute2             -- 出荷元
              ,mfd.forecast_date           -- 着荷予定日
              ,ximv.weight_capacity_class  -- 重量容積区分
              ,ximv.item_no                -- 品目
      ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    --   引取計画情報を抽出
    -- ====================================================
    -- カーソルオープン
    OPEN cur_get_to_plan;
    -- バルクフェッチ
    FETCH cur_get_to_plan BULK COLLECT INTO ot_to_plan;
    -- カーソルクローズ
    CLOSE cur_get_to_plan;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルオープン時、クローズへ
      IF (cur_get_to_plan%ISOPEN) THEN
        CLOSE cur_get_to_plan;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルオープン時、クローズへ
      IF (cur_get_to_plan%ISOPEN) THEN
        CLOSE cur_get_to_plan;
      END IF;
--
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルオープン時、クローズへ
      IF (cur_get_to_plan%ISOPEN) THEN
        CLOSE cur_get_to_plan;
      END IF;
--
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_get_to_plan;
--
  /**********************************************************************************
   * Procedure Name   : pro_ship_max_kbn
   * Description      : 出荷予定日/最大配送区分算出  (A-4)
   ***********************************************************************************/
  PROCEDURE pro_ship_max_kbn
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_ship_max_kbn'; -- プログラム名
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
    ln_result    NUMBER;
--
    -- *** ローカル変数 ***
    lv_errmsg_code  VARCHAR2(30);  -- エラー・メッセージ・コード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2009/01/30 H.Itou Add Start 本番障害#994対応
    -- 明細番号[1]の場合のみヘッダ単位チェックの数値を取得する。2明細目以降は1明細目の値を参照。
    IF (gn_line_number = 1) THEN
-- 2009/01/30 H.Itou Add End
      -----------------------------------------------------------------------------------
      -- 1.共通関数「稼働日算出関数」にて『着荷予定日』が稼働日かであるかチェック      --
      -----------------------------------------------------------------------------------
      ln_result := xxwsh_common_pkg.get_oprtn_day
                                  (
                                    gt_to_plan(gn_i).for_date   -- 日付           in 着荷予定日
                                   ,NULL                        -- 保管倉庫コード in NULL
                                   ,gt_to_plan(gn_i).ship_t_no  -- 配送先コード   in 配送先
                                   ,0                           -- リードタイム   in 0
                                   ,gt_to_plan(gn_i).skbn       -- 商品区分       in 商品区分(リーフ)
                                   ,gd_work_day                 -- 稼働日日付    out 稼働日
-- 2009/06/25 H.Itou Add Start 本番障害#1436対応 出荷予定日算出で渡す日付が稼働日でないと-1日されてしまうため、直後の稼働日を取得する。
                                   ,1                           -- 1:日付＋LT     in TYPE 
-- 2009/06/25 H.Itou Add End
                                  );
--
-- 2008/11/20 H.Itou Add Start 統合テスト指摘658
      -- 共通関数エラー時、エラー
      IF (ln_result = gn_status_error) THEN
  --
        -- エラーリスト作成
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_err            --  in 種別   'エラー'
           ,iv_dec          => gv_tkn_msg_hfn            --  in 確定   '-'
           ,iv_req_no       => gv_req_no                 --  in 依頼No
           ,iv_kyoten       => gt_to_plan(gn_i).ktn      --  in 管轄拠点
           ,iv_item         => gt_to_plan(gn_i).item_no  --  in 品目
           ,in_qty          => gt_to_plan(gn_i).amount   --  in 数量
           ,iv_ship_date    => gv_tkn_msg_hfn            --  in 出庫日  '-'
           ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                         --  in 着日
           ,iv_err_msg      => lv_errmsg                 --  in エラーメッセージ
           ,iv_err_clm      => gv_tkn_msg26              --  in エラー項目
           ,ov_errbuf       => lv_errbuf                 -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                 -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了ST エラー登録
        gv_err_sts := gv_status_error;
--
        RAISE err_header_expt;
      END IF;
-- 2008/11/20 H.Itou Add End
-- 2009/01/30 H.Itou Add Start 本番障害#994対応
    END IF;
-- 2009/01/30 H.Itou Add End
--
    -- 稼働日ではない場合、ワーニング
-- 2008/11/20 H.Itou Mod Start 統合テスト指摘658
--    IF (gd_work_day IS NULL) THEN
    IF (gd_work_day <> gt_to_plan(gn_i).for_date) THEN
-- 2008/11/20 H.Itou Mod End
--
      -- エラーリスト作成
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war            --  in 種別   '警告'
         ,iv_dec          => gv_tkn_msg_war            --  in 確定   '警告'
         ,iv_req_no       => gv_req_no                 --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn      --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no  --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount   --  in 数量
         ,iv_ship_date    => gv_tkn_msg_hfn            --  in 出庫日  '-'
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                       --  in 着日
         ,iv_err_msg      => gv_tkn_msg_6              --  in エラーメッセージ
         ,iv_err_clm      => gv_tkn_msg_hfn            --  in エラー項目 '-'
         ,ov_errbuf       => lv_errbuf                 -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                 -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -----------------------------------------------------------------------------------------------
    -- 2.共通関数「リードタイム算出」にて『引取変更リードタイム』『配送リードタイム』取得        --
    -----------------------------------------------------------------------------------------------
-- 2009/01/30 H.Itou Add Start 本番障害#994対応
    -- 明細番号[1]の場合のみヘッダ単位チェックの数値を取得する。2明細目以降は1明細目の値を参照。
    IF (gn_line_number = 1) THEN
-- 2009/01/30 H.Itou Add End
      xxwsh_common910_pkg.calc_lead_time
                                  (
                                    gv_4                       -- コード区分From   in 倉庫'4'
                                   ,gt_to_plan(gn_i).ship_fr   -- 入出庫区分From   in 出荷元
                                   ,gv_9                       -- コード区分To     in 配送先'9'
                                   ,gt_to_plan(gn_i).ship_t_no -- 入出庫区分To     in 配送先
                                   ,gt_to_plan(gn_i).skbn      -- 商品区分         in 商品区分(リーフ)
                                   ,gv_odr_type                -- 出庫形態ID       in 受注タイプID
                                   ,gt_to_plan(gn_i).for_date  -- 基準日           in 着荷予定日
                                   ,lv_retcode                 -- リターン・コード
                                   ,lv_errmsg_code             -- エラー・メッセージ・コード
                                   ,lv_errmsg                  -- ユーザー・エラー・メッセージ
                                   ,gv_leadtime                -- 生産物流LT/引取変更LT
                                   ,gv_delivery_lt             -- 配送リードタイム
                                  );
--
      -- 共通関数エラー時、エラー
      IF (lv_retcode = gv_1) THEN
--
        -- エラーリスト作成
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_err            --  in 種別   'エラー'
           ,iv_dec          => gv_tkn_msg_hfn            --  in 確定   '-'
           ,iv_req_no       => gv_req_no                 --  in 依頼No
           ,iv_kyoten       => gt_to_plan(gn_i).ktn      --  in 管轄拠点
           ,iv_item         => gt_to_plan(gn_i).item_no  --  in 品目
           ,in_qty          => gt_to_plan(gn_i).amount   --  in 数量
           ,iv_ship_date    => gv_tkn_msg_hfn            --  in 出庫日  '-'
           ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                         --  in 着日
           ,iv_err_msg      => lv_errmsg                 --  in エラーメッセージ
           ,iv_err_clm      => gv_tkn_msg_7              --  in エラー項目
           ,ov_errbuf       => lv_errbuf                 -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                 -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了ST エラー登録
        gv_err_sts := gv_status_error;
--
        RAISE err_header_expt;
      END IF;
-- 2009/01/30 H.Itou Add Start 本番障害#994対応
    END IF;
-- 2009/01/30 H.Itou Add End
--
    ----------------------------------------------------------------------------
    -- 3.共通関数「稼働日算出関数」にて『出荷予定日』算出                     --
    ----------------------------------------------------------------------------
-- 2009/01/30 H.Itou Add Start 本番障害#994対応
    -- 明細番号[1]の場合のみヘッダ単位チェックの数値を取得する。2明細目以降は1明細目の値を参照。
    IF (gn_line_number = 1) THEN
-- 2009/01/30 H.Itou Add End
-- 2009/06/25 H.Itou Add Start 本番障害#1436対応 配送LTが0の場合は出荷予定日＝着荷予定日なので算出しない。
      -- 配送LTが0の場合
      IF (gv_delivery_lt = 0) THEN
        -- 出荷予定日＝着荷予定日
        gd_ship_day := gt_to_plan(gn_i).for_date;
--
      -- 配送LTが0でない場合
      ELSE
-- 2009/06/25 H.Itou Add End
        ln_result := xxwsh_common_pkg.get_oprtn_day
                                      (
-- 2009/06/25 H.Itou Add Start 本番障害#1436対応 渡す日付が稼働日でないと-1日されてしまうため、直後の稼働日をで算出する。
--                                      gt_to_plan(gn_i).for_date -- 日付           in 着荷予定日
                                        gd_work_day               -- 日付           in 着荷予定日(稼働日でない場合は、直後の稼働日)
-- 2009/06/25 H.Itou Add End
                                       ,gt_to_plan(gn_i).ship_fr  -- 保管倉庫コード in 出荷元
                                       ,NULL                      -- 配送先コード   in NULL
                                       ,gv_delivery_lt            -- リードタイム   in 配送リードタイム
                                       ,gt_to_plan(gn_i).skbn     -- 商品区分       in 商品区分(リーフ)
                                       ,gd_ship_day               -- 稼働日日付    out 出荷予定日
                                      );
--
-- 2008/11/20 H.Itou Add Start 統合テスト指摘658
        -- 共通関数エラー時、エラー
        IF (ln_result = gn_status_error) THEN
--
          -- エラーリスト作成
          pro_err_list_make
            (
              iv_kind         => gv_tkn_msg_err            --  in 種別   'エラー'
             ,iv_dec          => gv_tkn_msg_hfn            --  in 確定   '-'
             ,iv_req_no       => gv_req_no                 --  in 依頼No
             ,iv_kyoten       => gt_to_plan(gn_i).ktn      --  in 管轄拠点
             ,iv_item         => gt_to_plan(gn_i).item_no  --  in 品目
             ,in_qty          => gt_to_plan(gn_i).amount   --  in 数量
             ,iv_ship_date    => gv_tkn_msg_hfn            --  in 出庫日  '-'
             ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                           --  in 着日
             ,iv_err_msg      => lv_errmsg                 --  in エラーメッセージ
             ,iv_err_clm      => gv_tkn_msg26              --  in エラー項目
             ,ov_errbuf       => lv_errbuf                 -- out エラー・メッセージ
             ,ov_retcode      => lv_retcode                -- out リターン・コード
             ,ov_errmsg       => lv_errmsg                 -- out ユーザー・エラー・メッセージ
            );
          -- 共通エラーメッセージ 終了ST エラー登録
          gv_err_sts := gv_status_error;
--
          RAISE err_header_expt;
        END IF;
-- 2008/11/20 H.Itou Add End
-- 2009/06/25 H.Itou Add Start 本番障害#1436対応
      END IF;
-- 2009/06/25 H.Itou Add End
-- 2009/01/30 H.Itou Add Start 本番障害#994対応
    END IF;
-- 2009/01/30 H.Itou Add End
--
    ----------------------------------------------------------------------------
    -- 4.稼働日日付(出荷予定日)がシステム日付より過去かどうかの判定           --
    ----------------------------------------------------------------------------
    IF (gd_sysdate > gd_ship_day) THEN
      -- 過去の場合、配送リードタイムを満たしていない。ワーニング
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in 種別   '警告'
         ,iv_dec          => gv_tkn_msg_err                     --  in 確定   'エラー'
         ,iv_req_no       => gv_req_no                          --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in 着日
         ,iv_err_msg      => gv_tkn_msg_8                       --  in エラーメッセージ
         ,iv_err_clm      => gv_delivery_lt                     --  in エラー項目 [配送リードタイム]
         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                         -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    ----------------------------------------------------------------------------
    -- 5.共通関数「稼働日算出関数」にて『過去稼働日』算出                     --
    ----------------------------------------------------------------------------
-- 2009/01/30 H.Itou Add Start 本番障害#994対応
    -- 明細番号[1]の場合のみヘッダ単位チェックの数値を取得する。2明細目以降は1明細目の値を参照。
    IF (gn_line_number = 1) THEN
-- 2009/01/30 H.Itou Add End
      ln_result := xxwsh_common_pkg.get_oprtn_day
                            (
                              gd_ship_day                -- 日付           in 出荷予定日
                             ,NULL                       -- 保管倉庫コード in NULL
                             ,gt_to_plan(gn_i).ship_t_no -- 配送先コード   in 配送先
-- 2008/11/20 H.Itou Add Start 統合テスト指摘141
--                             ,gv_delivery_lt             -- リードタイム   in 生産物流LT/引取変更LT
                             ,gv_leadtime                -- リードタイム   in 生産物流LT/引取変更LT
-- 2008/11/20 H.Itou Add End
                             ,gt_to_plan(gn_i).skbn      -- 商品区分       in 商品区分(リーフ)
                             ,gd_past_day                -- 稼働日日付    out 引取変更LTの過去日
                             );
--
-- 2008/11/20 H.Itou Add Start 統合テスト指摘658
      -- 共通関数エラー時、エラー
      IF (ln_result = gn_status_error) THEN
--
        -- エラーリスト作成
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_err            --  in 種別   'エラー'
           ,iv_dec          => gv_tkn_msg_hfn            --  in 確定   '-'
           ,iv_req_no       => gv_req_no                 --  in 依頼No
           ,iv_kyoten       => gt_to_plan(gn_i).ktn      --  in 管轄拠点
           ,iv_item         => gt_to_plan(gn_i).item_no  --  in 品目
           ,in_qty          => gt_to_plan(gn_i).amount   --  in 数量
           ,iv_ship_date    => gv_tkn_msg_hfn            --  in 出庫日  '-'
           ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                         --  in 着日
           ,iv_err_msg      => lv_errmsg                 --  in エラーメッセージ
           ,iv_err_clm      => gv_tkn_msg26              --  in エラー項目
           ,ov_errbuf       => lv_errbuf                 -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                 -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了ST エラー登録
        gv_err_sts := gv_status_error;
--
        RAISE err_header_expt;
      END IF;
-- 2008/11/20 H.Itou Add End
-- 2009/01/30 H.Itou Add Start 本番障害#994対応
    END IF;
-- 2009/01/30 H.Itou Add End
    ----------------------------------------------------------------------------
    -- 6.稼働日日付(引取変更LTの過去日)がシステム日付より過去かどうかの判定   --
    ----------------------------------------------------------------------------
-- 2008/11/20 H.Itou Add Start 統合テスト指摘141 生産物流LT／引取変更LTチェックは、当日出荷の場合があるので、稼働日＋1 でチェックを行う。
--    IF (gd_sysdate > gd_past_day) THEN
    IF (gd_sysdate > gd_past_day + 1) THEN
-- 2008/11/20 H.Itou Add End
      -- 過去の場合、引取リードタイムを満たしていない。ワーニング
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in 種別   '警告'
         ,iv_dec          => gv_tkn_msg_err                     --  in 確定   'エラー'
         ,iv_req_no       => gv_req_no                          --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in 着日
         ,iv_err_msg      => gv_tkn_msg_9                       --  in エラーメッセージ
         ,iv_err_clm      => gv_leadtime                        --  in エラー項目  [引取変更LT]
         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                         -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    ----------------------------------------------------------------------------
    -- 7.共通関数「最大配送区分算出関数」にて『最大配送区分』算出             --
    ----------------------------------------------------------------------------
-- 2009/01/30 H.Itou Add Start 本番障害#994対応
    -- 明細番号[1]の場合のみヘッダ単位チェックの数値を取得する。2明細目以降は1明細目の値を参照。
    IF (gn_line_number = 1) THEN
-- 2009/01/30 H.Itou Add End
      ln_result := xxwsh_common_pkg.get_max_ship_method
                               (
                                 gv_4                        -- コード区分1       in 倉庫'4'
                                ,gt_to_plan(gn_i).ship_fr    -- 入出庫場所コード1 in 出荷元
                                ,gv_9                        -- コード区分2       in 配送先'9'
                                ,gt_to_plan(gn_i).ship_t_no  -- 入出庫場所コード2 in 配送先
                                ,gt_to_plan(gn_i).skbn       -- 商品区分          in 商品区分(リーフ)
                                ,gt_to_plan(gn_i).wei_kbn    -- 重量容積区分      in 重量容積区分
                                ,NULL                        -- 自動配車対象区分  in NULL
                                ,gd_ship_day                 -- 基準日            in 出荷予定日
                                ,gv_max_kbn                  -- 最大配送区分     out 最大配送区分
                                ,gn_drink_we                 -- ドリンク積載重量 out ドリンク積載重量
                                ,gn_leaf_we                  -- リーフ積載重量   out リーフ積載重量
                                ,gn_drink_ca                 -- ドリンク積載容積 out ドリンク積載容積
                                ,gn_leaf_ca                  -- リーフ積載容積   out リーフ積載容積
                                ,gn_prt_max                  -- パレット最大枚数 out パレット最大枚数
                               );
--
      -- 最大配送区分算出関数が正常ではない場合、エラー
      IF (ln_result = 1) THEN
--
        -- エラーリスト作成
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_err                     --  in 種別   'エラー'
           ,iv_dec          => gv_tkn_msg_hfn                     --  in 確定   '-'
           ,iv_req_no       => gv_req_no                          --  in 依頼No
           ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
           ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
           ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
           ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
           ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                  --  in 着日
           ,iv_err_msg      => gv_tkn_msg_10                      --  in エラーメッセージ
           ,iv_err_clm      => gv_tkn_msg_hfn                     --  in エラー項目  '-'
           ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                         -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了ST  エラー登録
        gv_err_sts := gv_status_error;
--
        RAISE err_header_expt;
      END IF;
-- 2009/01/30 H.Itou Add Start 本番障害#994対応
    END IF;
-- 2009/01/30 H.Itou Add End
--
    ----------------------------------------------------------------------------
    -- 8.共通関数「OPM在庫会計期間 CLOSE年月取得関数」にて                    --
    --   『出荷予定日』の会計期間がOpenされているかチェック                   --
    ----------------------------------------------------------------------------
-- 2009/01/30 H.Itou Del Start 本番障害#994対応 クローズ最大年月は変わらないので、A-1で取得する。
--    -- クローズの最大年月取得
--    gv_opm_c_p := xxcmn_common_pkg.get_opminv_close_period;
-- 2009/01/30 H.Itou Del End
--
    -- 出荷予定日がOPM在庫会計期間でクローズの場合
-- 2008/10/09 H.Itou Mod Start クローズ年月と同じ年月の場合もエラー
--    IF (gv_opm_c_p > TO_CHAR(gd_ship_day,'YYYYMM')) THEN
    IF (gv_opm_c_p >= TO_CHAR(gd_ship_day,'YYYYMM')) THEN
-- 2008/10/09 H.Itou Mod End
--
      -- エラーリスト作成
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_tkn_msg_hfn                     --  in 確定   '-'
         ,iv_req_no       => gv_req_no                          --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in 着日
         ,iv_err_msg      => gv_tkn_msg_11                      --  in エラーメッセージ
--         ,iv_err_clm      => gd_ship_day                        --  in エラー項目  [出荷予定日]
         ,iv_err_clm      => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in エラー項目 [出荷予定日]
         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                         -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
-- 2008/10/09 H.Itou Del Start 在庫会計期間クローズの場合、後続の明細項目チェックを行うため、例外処理を行わない
--      RAISE err_header_expt;
-- 2008/10/09 H.Itou Del End
    END IF;
--
  EXCEPTION
    -- *** 共通関数 警告・エラー ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_ship_max_kbn;
--
  /**********************************************************************************
   * Procedure Name   : pro_lines_chk
   * Description      : 明細項目チェック (A-5)
   ***********************************************************************************/
  PROCEDURE pro_lines_chk
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_lines_chk'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 「出荷区分」が『否』の場合、ワーニング
    IF (gt_to_plan(gn_i).out_kbn = gv_0) THEN
--
      -- エラーリスト作成
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
         ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
         ,iv_req_no       => gv_req_no                          --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in 着日
         ,iv_err_msg      => gv_tkn_msg_12                      --  in エラーメッセージ
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in エラー項目  '-'
         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                         -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- 「売上対象区分」が「1」以外の場合、ワーニング
    IF (gt_to_plan(gn_i).sale_kbn <> gv_1) THEN
--
      -- エラーリスト作成
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
         ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
         ,iv_req_no       => gv_req_no                          --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in 着日
         ,iv_err_msg      => gv_tkn_msg_1                       --  in エラーメッセージ
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in エラー項目  '-'
         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                         -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- 「廃止区分」が「1」の場合、ワーニング
    IF (gt_to_plan(gn_i).end_kbn = gv_delete) THEN
--
      -- エラーリスト作成
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
         ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
         ,iv_req_no       => gv_req_no                          --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in 着日
         ,iv_err_msg      => gv_tkn_msg_2                       --  in エラーメッセージ
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in エラー項目  '-'
         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                         -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- 「率区分」が「0」以外の場合、ワーニング
    IF (gt_to_plan(gn_i).rit_kbn <> gv_0) THEN
--
      -- エラーリスト作成
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
         ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
         ,iv_req_no       => gv_req_no                          --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in 着日
         ,iv_err_msg      => gv_tkn_msg_3                       --  in エラーメッセージ
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in エラー項目  '-'
         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                         -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- 「中止客申請フラグ」が「0」以外の場合、ワーニング
    IF (gt_to_plan(gn_i).no_flg <> gv_0) THEN
--
      -- エラーリスト作成
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
         ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
         ,iv_req_no       => gv_req_no                          --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in 着日
         ,iv_err_msg      => gv_tkn_msg_5                       --  in エラーメッセージ
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in エラー項目  '-'
         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                         -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- 「出荷引当対象フラグ」が引当不可「0」、ワーニング
    IF (gt_to_plan(gn_i).a_p_flg = gv_0) THEN
--
      -- エラーリスト作成
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
         ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
         ,iv_req_no       => gv_req_no                          --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in 着日
         ,iv_err_msg      => gv_tkn_msg_23                      --  in エラーメッセージ
         ,iv_err_clm      => gt_to_plan(gn_i).ship_fr           --  in エラー項目  出荷元
         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                         -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_lines_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_xsr_chk
   * Description      : 物流構成アドオンマスタ存在チェック (A-6)
   ***********************************************************************************/
  PROCEDURE pro_xsr_chk
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_xsr_chk'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_cnt      NUMBER;
    lv_yn_flg   VARCHAR2(1);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 存在チェックフラグ、カウント変数初期化
    ln_cnt    := 0;
    lv_yn_flg := gv_no;
--
-- 2009/01/08 H.Itou Mod Start 本番障害#894
--    ------------------------------------------------------------------
--    -- 1.品目/配送先/出荷先にて物流構成アドオンへの存在チェック     --
--    ------------------------------------------------------------------
--    SELECT COUNT (xsr.item_code)
--    INTO   ln_cnt
--    FROM   xxcmn_sourcing_rules  xsr   -- 物流構成アドオンマスタ T
--    WHERE  xsr.item_code          = gt_to_plan(gn_i).item_no
--    AND    xsr.ship_to_code       = gt_to_plan(gn_i).ship_t_no
--    AND    xsr.delivery_whse_code = gt_to_plan(gn_i).ship_fr
--    AND    xsr.start_date_active <= gd_ship_day
--    AND    xsr.end_date_active   >= gd_ship_day
--    AND    ROWNUM                 = 1
--    ;
----
--    IF (ln_cnt > 0) THEN
--      lv_yn_flg := gv_yes;
--    END IF;
----
--    ------------------------------------------------------------------
--    -- 2.品目/拠点/出荷元にて物流構成アドオンへの存在チェック       --
--    ------------------------------------------------------------------
--    -- 上記1にて0件の場合
--    IF (lv_yn_flg = gv_no) THEN
--      SELECT COUNT (xsr.item_code)
--      INTO   ln_cnt
--      FROM   xxcmn_sourcing_rules  xsr  -- 物流構成アドオンマスタ T
--      WHERE  xsr.item_code          = gt_to_plan(gn_i).item_no
--      AND    xsr.base_code          = gt_to_plan(gn_i).ktn
--      AND    xsr.delivery_whse_code = gt_to_plan(gn_i).ship_fr
--      AND    xsr.start_date_active <= gd_ship_day
--      AND    xsr.end_date_active   >= gd_ship_day
--      AND    ROWNUM                 = 1
--      ;
----
--      IF (ln_cnt > 0) THEN
--        lv_yn_flg := gv_yes;
--      END IF;
--    END IF;
----
--    ------------------------------------------------------------------
--    -- 3.全品目/配送先/出荷元にて物流構成アドオンへの存在チェック   --
--    ------------------------------------------------------------------
--    -- 上記2にて0件の場合
--    IF (lv_yn_flg = gv_no) THEN
--      SELECT COUNT (xsr.item_code)
--      INTO   ln_cnt
--      FROM   xxcmn_sourcing_rules  xsr  -- 物流構成アドオンマスタ T
--      WHERE  xsr.item_code          = gv_all_item
--      AND    xsr.ship_to_code       = gt_to_plan(gn_i).ship_t_no
--      AND    xsr.delivery_whse_code = gt_to_plan(gn_i).ship_fr
--      AND    xsr.start_date_active <= gd_ship_day
--      AND    xsr.end_date_active   >= gd_ship_day
--      AND    ROWNUM                 = 1
--      ;
----
--      IF (ln_cnt > 0) THEN
--        lv_yn_flg := gv_yes;
--      END IF;
--    END IF;
----
--    ------------------------------------------------------------------
--    -- 4.全品目/拠点/出荷元にて物流構成アドオンへの存在チェック     --
--    ------------------------------------------------------------------
--    -- 上記3にて0件の場合
--    IF (lv_yn_flg = gv_no) THEN
--      SELECT COUNT (xsr.item_code)
--      INTO   ln_cnt
--      FROM   xxcmn_sourcing_rules  xsr  -- 物流構成アドオンマスタ T
--      WHERE  xsr.item_code          = gv_all_item
--      AND    xsr.base_code          = gt_to_plan(gn_i).ktn
--      AND    xsr.delivery_whse_code = gt_to_plan(gn_i).ship_fr
--      AND    xsr.start_date_active <= gd_ship_day
--      AND    xsr.end_date_active   >= gd_ship_day
--      AND    ROWNUM                 = 1
--      ;
----
--      IF (ln_cnt > 0) THEN
--        lv_yn_flg := gv_yes;
--      END IF;
--    END IF;
--
    -- 物流構成存在チェック関数
    lv_retcode := xxwsh_common_pkg.chk_sourcing_rules(
                    it_item_code          => gt_to_plan(gn_i).item_no    -- 1.品目コード
                   ,it_base_code          => gt_to_plan(gn_i).ktn        -- 2.管轄拠点
                   ,it_ship_to_code       => gt_to_plan(gn_i).ship_t_no  -- 3.配送先
                   ,it_delivery_whse_code => gt_to_plan(gn_i).ship_fr    -- 4.出庫倉庫
                   ,id_standard_date      => gd_ship_day                 -- 5.基準日(適用日基準日)
                  );
--
-- 2009/01/08 H.Itou Mod End
--
-- 2009/01/08 H.Itou Mod Start 本番障害#894
--    -- 上記4にて0件の場合、ワーニング
--    IF (lv_yn_flg = gv_no) THEN
     -- 戻り値が正常でない場合、ワーニング
     IF (lv_retcode <> gv_status_normal) THEN
-- 2009/01/08 H.Itou Mod End
--
      -- エラーリスト作成
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
         ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
         ,iv_req_no       => gv_req_no                          --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in 着日
         ,iv_err_msg      => gv_tkn_msg_13                      --  in エラーメッセージ
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in エラー項目  '-'
         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                         -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_xsr_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_total_we_ca
   * Description      : 合計重量/合計容積算出 (A-7)
   ***********************************************************************************/
  PROCEDURE pro_total_we_ca
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_total_we_ca'; -- プログラム名
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
    lv_kougti    CONSTANT VARCHAR2(6)  := '%小口%';
--
    -- *** ローカル変数 ***
    ln_cnt         NUMBER;
    lv_errmsg_code VARCHAR2(30);  -- エラー・メッセージ・コード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -----------------------------------------------------------------------------------
    -- 共通関数「積載効率チェック(合計値算出)」にて『合計重量/合計容積』を算出       --
    -----------------------------------------------------------------------------------
    xxwsh_common910_pkg.calc_total_value
                               (
                                 gt_to_plan(gn_i).item_no -- 品目              in 品目
                                ,gt_to_plan(gn_i).amount  -- 数量              in 数量
                                ,lv_retcode               -- リターン・コード
                                ,lv_errmsg_code           -- エラー・メッセージ・コード
                                ,lv_errmsg                -- エラー・メッセージ
                                ,gn_ttl_we                -- 合計重量         out 合計重量
                                ,gn_ttl_ca                -- 合計容積         out 合計容積
                                ,gn_ttl_prt_we            -- 合計パレット重量 out 合計パレット重量
-- 2008/10/09 H.Itou Add Start 統合テスト指摘240
                                ,gd_ship_day              -- 基準日            in 出荷予定日
-- 2008/10/09 H.Itou Add End
                               );
--
-- 2008/07/30 Mod ↓
/*
    -------------------------------------------------------------------------------
    -- ｢最大配送区分｣に紐づく｢小口区分｣が対象かどうかチェック                    --
    -------------------------------------------------------------------------------
    SELECT count (xlvv.meaning)
    INTO   ln_cnt
    FROM   xxcmn_lookup_values_v  xlvv  -- クイックコード情報 V
    WHERE  xlvv.lookup_type = gv_ship_method
    AND    xlvv.lookup_code = gv_max_kbn
    AND    xlvv.attribute6  = gv_1          -- 対象
    AND    xlvv.meaning  LIKE lv_kougti;
--
    -- ｢明細重量｣｢明細容積｣算出
    IF (ln_cnt = 1) THEN
      -- 『対象』の場合
      gn_detail_we := NVL(gn_ttl_we,0);                       -- 明細重量
      gn_detail_ca := NVL(gn_ttl_ca,0);                       -- 明細容積
    ELSE
      -- 上記以外の場合
      gn_detail_we := NVL(gn_ttl_we,0) + NVL(gn_ttl_prt_we,0);  -- 明細重量
      gn_detail_ca := NVL(gn_ttl_ca,0) + NVL(gn_ttl_prt_we,0);  -- 明細容積
    END IF;
*/
    gn_detail_we := NVL(gn_ttl_we,0);                       -- 明細重量
    gn_detail_ca := NVL(gn_ttl_ca,0);                       -- 明細容積
-- 2008/07/30 Mod ↑
--
    -- 共通関数にて、リターンコードがエラー時、エラー
    IF (lv_retcode = gv_1) THEN
--
      -- エラーリスト作成
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_err            --  in 種別  'エラー'
         ,iv_dec          => gv_tkn_msg_hfn            --  in 確定  '-'
         ,iv_req_no       => gv_req_no                 --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn      --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no  --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount   --  in 数量
         ,iv_ship_date    => gv_tkn_msg_hfn            --  in 出庫日 '-'
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                       --  in 着日
         ,iv_err_msg      => lv_errmsg                 --  in エラーメッセージ
         ,iv_err_clm      => gv_tkn_msg_hfn            --  in エラー項目  '-'
         ,ov_errbuf       => lv_errbuf                 -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                 -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
  EXCEPTION
    -- *** 共通関数 警告・エラー ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_2;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_total_we_ca;
--
  /**********************************************************************************
   * Procedure Name   : pro_ship_y_n_chk
   * Description      : 出荷可否チェック (A-8)
   ***********************************************************************************/
  PROCEDURE pro_ship_y_n_chk
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_ship_y_n_chk'; -- プログラム名
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
    ln_result   NUMBER;
--
    -- *** ローカル変数 ***
    lv_errmsg_code VARCHAR2(30);  -- エラー・メッセージ・コード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -----------------------------------------------------------------------------------
    -- 共通関数「出荷可否チェック」にて出荷実績数量・出荷予測数量が                  --
    --   計画数量をOVERしていないかのチェック                                        --
    -----------------------------------------------------------------------------------
    -----------------------------------
    -- 出荷数制限(商品部) チェック   --
    -----------------------------------
    xxwsh_common910_pkg.check_shipping_judgment
                                  (
                                    gv_2                      -- チェック方法区分 in 『2』:商品部
                                   ,gt_to_plan(gn_i).ktn      -- 拠点             in 拠点
                                   ,gt_to_plan(gn_i).item_id  -- 品目ID           in 品目ID
                                   ,gt_to_plan(gn_i).amount   -- 数量             in 数量
                                   ,gt_to_plan(gn_i).for_date -- 対象日           in 着荷予定日
                                   ,gt_to_plan(gn_i).ship_id  -- 出荷元ID         in 出荷元ID
                                   ,NULL
                                   ,lv_retcode                -- リターン・コード
                                   ,lv_errmsg_code            -- エラー・メッセージ・コード
                                   ,lv_errmsg                 -- ユーザー・エラー・メッセージ
                                   ,ln_result                 -- 処理結果
                                  );
--
    -- 出荷数制限(商品部) 出荷可否チェック 異常終了の場合、エラー
    IF (lv_retcode = gv_1) THEN
--
      -- エラーリスト作成
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_err                     --  in 種別  'エラー'
         ,iv_dec          => gv_tkn_msg_hfn                     --  in 確定  '-'
         ,iv_req_no       => gv_req_no                          --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in 着日
         ,iv_err_msg      => gv_tkn_msg_14 || lv_errmsg         --  in エラーメッセージ
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in エラー項目  '-'
         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                         -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- 出荷数制限(商品部)チェックにて「処理結果」='1'(数量オーバーエラー)時、ワーニング
    IF (ln_result = 1) THEN
--
      -- エラーリスト作成
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
         ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
         ,iv_req_no       => gv_req_no                          --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in 着日
         ,iv_err_msg      => gv_tkn_msg_16                      --  in エラーメッセージ
         ,iv_err_clm      => gt_to_plan(gn_i).amount            --  in エラー項目  [数量]
         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                         -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -----------------------------------
    -- 出荷数制限(物流部) チェック   --
    -----------------------------------
    xxwsh_common910_pkg.check_shipping_judgment(
                                    gv_3                     -- チェック方法区分 in 『3』:物流部
                                   ,gt_to_plan(gn_i).ktn     -- 拠点             in 拠点
                                   ,gt_to_plan(gn_i).item_id -- 品目ID           in 品目ID
                                   ,gt_to_plan(gn_i).amount  -- 数量             in 数量
                                   ,gd_ship_day              -- 対象日           in 出荷予定日
                                   ,gt_to_plan(gn_i).ship_id -- 出荷元ID         in 出荷元ID
                                   ,NULL
                                   ,lv_retcode               -- リターン・コード
                                   ,lv_errmsg_code           -- エラー・メッセージ・コード
                                   ,lv_errmsg                -- ユーザー・エラー・メッセージ
                                   ,ln_result                -- 処理結果
                                  );
--
    -- 出荷数制限(物流部) 出荷可否チェック 異常終了の場合、エラー
    IF (lv_retcode = gv_1) THEN
--
      -- エラーリスト作成
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_err                     --  in 種別  'エラー'
         ,iv_dec          => gv_tkn_msg_hfn                     --  in 確定  '-'
         ,iv_req_no       => gv_req_no                          --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in 着日
         ,iv_err_msg      => gv_tkn_msg_15 || lv_errmsg         --  in エラーメッセージ
         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in エラー項目  '-'
         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                         -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- 出荷数制限(物流部)チェックにて「処理結果」='1'(数量オーバーエラー)時、ワーニング
    IF (ln_result = 1) THEN
--
      -- エラーリスト作成
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
         ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
         ,iv_req_no       => gv_req_no                          --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in 着日
         ,iv_err_msg      => gv_tkn_msg_17                      --  in エラーメッセージ
         ,iv_err_clm      => gt_to_plan(gn_i).amount            --  in エラー項目  [数量]
         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                         -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- 出荷数制限(物流部)チェックにて「処理結果」='2'(出荷停止日エラー)時、ワーニング
    IF (ln_result = 2) THEN
--
      -- エラーリスト作成
      pro_err_list_make
        (
          iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
         ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
         ,iv_req_no       => gv_req_no                          --  in 依頼No
         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                --  in 着日
         ,iv_err_msg      => gv_tkn_msg_18                      --  in エラーメッセージ
-- 2008/08/19 H.Itou Mod Start 結合指摘#87
--         ,iv_err_clm      => gt_to_plan(gn_i).amount            --  in エラー項目  [数量]
         ,iv_err_clm      => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in エラー項目  [出荷予定日]
-- 2008/08/19 H.Itou Mod End
         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                         -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** 共通関数 警告・エラー ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_2;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_ship_y_n_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_lines_create
   * Description      : 受注明細アドオンレコード生成 (A-9)
   ***********************************************************************************/
  PROCEDURE pro_lines_create
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_lines_create'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル変数 ***
    ln_mod_chk      NUMBER DEFAULT 0;      -- 整数倍チェック
    lv_dsc          VARCHAR2(6);           -- エラーメッセージ内容項目
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -----------------------------
    -- 1.明細番号の採番        --
    -----------------------------
    -- ｢拠点｣｢出荷元｣｢着荷予定日｣｢重量容積区分｣の判定
    IF ((gv_ktn      = gt_to_plan(gn_i).ktn)
    AND (gv_ship_fr  = gt_to_plan(gn_i).ship_fr)
    AND (gv_for_date = gt_to_plan(gn_i).for_date)
    AND (gv_wei_kbn  = gt_to_plan(gn_i).wei_kbn))
    THEN
      -- 明細番号カウント＋１
      gn_line_number := gn_line_number + 1;
    -- 初回レコード時、｢拠点｣｢出荷元｣｢着荷予定日｣｢重量容積区分｣のうち、１つでも異なる場合
    -- 明細番号は[1]セット
    ELSE
      gn_line_number := 1;
    END IF;
--
    ------------------------------------------------------
    -- 2.受注明細アドオン作成用レコード変数へ格納       --
    ------------------------------------------------------
    gn_l_cnt := gn_l_cnt + 1;
--
    gt_l_order_line_id(gn_l_cnt)          := gn_lines_seq;             -- 受注明細アドオンID
    gt_l_order_header_id(gn_l_cnt)        := gn_headers_seq;           -- 受注ヘッダアドオンID
    gt_l_order_line_number(gn_l_cnt)      := gn_line_number;           -- 明細番号
    gt_l_request_no(gn_l_cnt)             := gv_req_no;                -- 依頼No
    gt_l_shipping_inv_item_id(gn_l_cnt)   := gt_to_plan(gn_i).item_id; -- 出荷品目ID
    gt_l_shipping_item_code(gn_l_cnt)     := gt_to_plan(gn_i).item_no; -- 出荷品目
    gt_l_quantity(gn_l_cnt)               := gt_to_plan(gn_i).amount;  -- 数量
    gt_l_uom_code(gn_l_cnt)               := gt_to_plan(gn_i).item_um; -- 単位
    gt_l_based_request_quantity(gn_l_cnt) := gt_to_plan(gn_i).amount;  -- 拠点依頼数量
    gt_l_request_item_id(gn_l_cnt)        := gt_to_plan(gn_i).item_id; -- 依頼品目ID
    gt_l_request_item_code(gn_l_cnt)      := gt_to_plan(gn_i).item_no; -- 依頼品目
    gt_l_weight(gn_l_cnt)                 := NVL(gn_detail_we,0);      -- 重量
    gt_l_capacity(gn_l_cnt)               := NVL(gn_detail_ca,0);      -- 容積
    gt_l_pallet_weight(gn_l_cnt)          := NVL(gn_ttl_prt_we,0);     -- パレット重量
    gt_l_delete_flag(gn_l_cnt)            := 'N';                      -- 削除フラグ
-- 2009/12/09 M.Miyagawa Add Start 本番障害#267
    gt_l_shipping_request_if_flg(gn_l_cnt):= 'N';                      -- 出荷依頼インタフェース済フラグ
    gt_l_shipping_result_if_flg(gn_l_cnt) := 'N';                      -- 出荷実績インタフェース済フラグ
-- 2009/12/09 M.Miyagawa Add End 本番障害#267
    gt_l_created_by(gn_l_cnt)             := gn_created_by;            -- 作成者
    gt_l_creation_date(gn_l_cnt)          := gd_creation_date;         -- 作成日
    gt_l_last_updated_by(gn_l_cnt)        := gn_last_upd_by;           -- 最終更新者
    gt_l_last_update_date(gn_l_cnt)       := gd_last_upd_date;         -- 最終更新日
    gt_l_last_update_login(gn_l_cnt)      := gn_last_upd_login;        -- 最終更新ログイン
    gt_l_request_id(gn_l_cnt)             := gn_request_id;            -- 要求ID
    gt_l_program_application_id(gn_l_cnt) := gn_prog_appl_id;          -- プログラムアプリID
    gt_l_program_id(gn_l_cnt)             := gn_prog_id;               -- プログラムID
    gt_l_program_update_date(gn_l_cnt)    := gd_prog_upd_date;         -- プログラム更新日
--
    -- 出荷依頼作成明細件数(依頼明細単位) カウント
    gn_line_cnt := gn_line_cnt + 1;
--
    ---------------------------------------------------
    -- 3.出荷単位換算数の算出                        --
    ---------------------------------------------------
-- 2008/07/30 Mod ↓
    -- (1).｢出荷入数｣が > '0'の場合
    IF (gt_to_plan(gn_i).ship_am > 0) THEN
      gn_ship_amount := CEIL(gt_to_plan(gn_i).amount / gt_to_plan(gn_i).ship_am);
--
      -- 受注ヘッダアドオン項目用変数 加算
      gn_ttl_amount   := gn_ttl_amount   + NVL(gt_to_plan(gn_i).amount,0);  -- 合計数量
      gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;                  -- 出荷単位換算数
      gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_detail_we,0);             -- 積載重量合計
      gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_detail_ca,0);             -- 積載容積合計
      gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);            -- 合計パレット重量
--
      -- ｢数量｣が｢出荷入数｣の整数倍ではない場合、ワーニング
      ln_mod_chk := MOD(gt_to_plan(gn_i).amount,gt_to_plan(gn_i).ship_am);
      IF (ln_mod_chk <> 0) THEN
--
      -- エラーリスト作成
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_war                    --  in 種別  '警告'
           ,iv_dec          => gv_tkn_msg_err                    --  in 確定  'エラー'
           ,iv_req_no       => gv_req_no                         --  in 依頼No
           ,iv_kyoten       => gt_to_plan(gn_i).ktn              --  in 管轄拠点
           ,iv_item         => gt_to_plan(gn_i).item_no          --  in 品目
           ,in_qty          => gt_to_plan(gn_i).amount           --  in 数量
           ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD') --  in 出庫日 [出荷予定日]
           ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')  --  in 着日
           ,iv_err_msg      => gv_tkn_msg_19                     --  in エラーメッセージ
           ,iv_err_clm      => gv_tkn_msg_hfn                    --  in エラー項目  '-'
           ,ov_errbuf       => lv_errbuf                         -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                        -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                         -- out ユーザー・エラー・ﾒｯｾｰｼﾞ
          );
        -- 共通エラーメッセージ 終了STの判定
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
--
    -- (2).｢出荷入数｣が = '0',NULLの場合
    ELSE
      -- (2-1).入出庫換算単位が設定されている場合
      IF (gt_to_plan(gn_i).conv_unit IS NOT NULL) THEN
--
        -- (2-1-1).｢ケース入数｣が > '0'の場合
        IF (gt_to_plan(gn_i).case_am > 0) THEN
          gn_ship_amount := CEIL(gt_to_plan(gn_i).amount / gt_to_plan(gn_i).case_am);
--
          -- 受注ヘッダアドオン項目用変数 加算
          gn_ttl_amount   := gn_ttl_amount   + NVL(gt_to_plan(gn_i).amount,0);  -- 合計数量
          gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;                  -- 出荷単位換算数
          gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_detail_we,0);             -- 積載重量合計
          gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_detail_ca,0);             -- 積載容積合計
          gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);            -- 合計パレット重量
--
          -- ｢数量｣が｢入数｣の整数倍ではない場合。ワーニング
          ln_mod_chk := MOD(gt_to_plan(gn_i).amount,gt_to_plan(gn_i).case_am);
          IF (ln_mod_chk <> 0) THEN
            -- 入出庫換算単位の判定
            IF (gt_to_plan(gn_i).conv_unit IS NOT NULL) THEN
              -- 入出庫換算単位が設定されている場合、確定項目 'エラー'
              lv_dsc := gv_tkn_msg_err;
            ELSE
              -- 入出庫換算単位が未設定の場合、確定項目 '－'
              lv_dsc := gv_tkn_msg_hfn;
            END IF;
--
            -- エラーリスト作成
            pro_err_list_make
              (
                iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
               ,iv_dec          => lv_dsc                             --  in 確定
               ,iv_req_no       => gv_req_no                          --  in 依頼No
               ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
               ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
               ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
               ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
               ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')  --  in 着日
               ,iv_err_msg      => gv_tkn_msg_21                      --  in エラーメッセージ
               ,iv_err_clm      => gv_tkn_msg_hfn                     --  in エラー項目  '-'
               ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
               ,ov_retcode      => lv_retcode                         -- out リターン・コード
               ,ov_errmsg       => lv_errmsg                          -- out ユーザー・ｴﾗｰ・ﾒｯｾｰｼﾞ
              );
            -- 共通エラーメッセージ 終了STの判定
            IF (gv_err_sts <> gv_status_error) THEN
              gv_err_sts := gv_status_warn;
            END IF;
--
            RAISE err_header_expt;
          END IF;
--
        -- (2-1-2).｢ケース入数｣が = '0',NULLの場合
        ELSE
--
          -- エラーリスト作成
          pro_err_list_make
            (
              iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
             ,iv_dec          => lv_dsc                             --  in 確定
             ,iv_req_no       => gv_req_no                          --  in 依頼No
             ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
             ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
             ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
             ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
             ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')  --  in 着日
             ,iv_err_msg      => gv_tkn_msg_24                      --  in エラーメッセージ
             ,iv_err_clm      => gv_tkn_msg_hfn                     --  in エラー項目  '-'
             ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
             ,ov_retcode      => lv_retcode                         -- out リターン・コード
             ,ov_errmsg       => lv_errmsg                          -- out ユーザー・ｴﾗｰ・ﾒｯｾｰｼﾞ
            );
          -- 共通エラーメッセージ 終了STの判定
          IF (gv_err_sts <> gv_status_error) THEN
            gv_err_sts := gv_status_warn;
          END IF;
--
          gn_ship_amount  := gt_to_plan(gn_i).amount;
--
          -- 受注ヘッダアドオン項目用変数 加算
          gn_ttl_amount   := gn_ttl_amount   + NVL(gt_to_plan(gn_i).amount,0);  -- 合計数量
          gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;                  -- 出荷単位換算数
          gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_detail_we,0);             -- 積載重量合計
          gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_detail_ca,0);             -- 積載容積合計
          gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);            -- 合計パレット重量
        END IF;
--
      -- (2-2).入出庫換算単位が設定されていない場合
      ELSE
        gn_ship_amount  := gt_to_plan(gn_i).amount;
--
        -- 受注ヘッダアドオン項目用変数 加算
        gn_ttl_amount   := gn_ttl_amount   + NVL(gt_to_plan(gn_i).amount,0);  -- 合計数量
        gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;                  -- 出荷単位換算数
        gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_detail_we,0);             -- 積載重量合計
        gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_detail_ca,0);             -- 積載容積合計
        gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);            -- 合計パレット重量
      END IF;
    END IF;
--
-- 2008/10/09 H.Itou Del Start
---- 2008/08/18 H.Itou Add Start 積載効率(重量)・積載効率(容積)メッセージ用にダミーエラーメッセージ作成。
--    -- テーブルカウント
--    gn_cut := gn_cut + 1;
--    gt_err_msg(gn_cut).err_msg  := NULL;
--    gt_to_plan(gn_i).we_loading_msg_seq := gn_cut; -- 積載効率(重量)メッセージ格納SEQ
----
--    -- テーブルカウント
--    gn_cut := gn_cut + 1;
--    gt_err_msg(gn_cut).err_msg  := NULL;
--    gt_to_plan(gn_i).ca_loading_msg_seq := gn_cut; -- 積載効率(容積)メッセージ格納SEQ
----
---- 2008/08/18 H.Itou Add End
-- 2008/10/09 H.Itou Del End
--
/*
    ---------------------------------------------------
    -- 3.出荷単位換算数の算出                        --
    ---------------------------------------------------
    -- (1).｢出荷入数｣が設定されている場合、「数量」/「出荷入数」(小数点以下四捨五入)
    IF (gt_to_plan(gn_i).ship_am IS NOT NULL) THEN
      -- 0除算判定
      IF (gt_to_plan(gn_i).ship_am = 0) THEN
        gn_ship_amount := 0;
      ELSE
        gn_ship_amount := ROUND(gt_to_plan(gn_i).amount / gt_to_plan(gn_i).ship_am,0);
      END IF;
--
      -- 受注ヘッダアドオン項目用変数 加算
      gn_ttl_amount   := gn_ttl_amount   + NVL(gt_to_plan(gn_i).amount,0);  -- 合計数量
      gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;                  -- 出荷単位換算数
      gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_detail_we,0);             -- 積載重量合計
      gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_detail_ca,0);             -- 積載容積合計
      gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);            -- 合計パレット重量
--
      -- ｢数量｣が｢出荷入数｣の整数倍ではない場合、ワーニング
      ln_mod_chk := MOD(gt_to_plan(gn_i).amount,gt_to_plan(gn_i).ship_am);
      IF (ln_mod_chk <> 0) THEN
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_war                    --  in 種別  '警告'
           ,iv_dec          => gv_tkn_msg_err                    --  in 確定  'エラー'
           ,iv_req_no       => gv_req_no                         --  in 依頼No
           ,iv_kyoten       => gt_to_plan(gn_i).ktn              --  in 管轄拠点
           ,iv_item         => gt_to_plan(gn_i).item_no          --  in 品目
           ,in_qty          => gt_to_plan(gn_i).amount           --  in 数量
           ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD') --  in 出庫日 [出荷予定日]
           ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                 --  in 着日
           ,iv_err_msg      => gv_tkn_msg_19                     --  in エラーメッセージ
           ,iv_err_clm      => gv_tkn_msg_hfn                    --  in エラー項目  '-'
           ,ov_errbuf       => lv_errbuf                         -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                        -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                         -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了STの判定
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
--
    -- (2).(1)以外、｢入数｣が設定されている場合、「数量」/「入数」(小数点以下四捨五入)
    ELSIF (gt_to_plan(gn_i).case_am IS NOT NULL) THEN
      -- 0除算判定
      IF (gt_to_plan(gn_i).case_am = 0) THEN
        gn_ship_amount := 0;
      ELSE
        gn_ship_amount := ROUND(gt_to_plan(gn_i).amount / gt_to_plan(gn_i).case_am,0);
      END IF;
--
      -- 受注ヘッダアドオン項目用変数 加算
      gn_ttl_amount   := gn_ttl_amount   + NVL(gt_to_plan(gn_i).amount,0);  -- 合計数量
      gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;                  -- 出荷単位換算数
      gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_detail_we,0);             -- 積載重量合計
      gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_detail_ca,0);             -- 積載容積合計
      gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);            -- 合計パレット重量
--
      -- ｢数量｣が｢入数｣の整数倍ではない場合。ワーニング
      ln_mod_chk := MOD(gt_to_plan(gn_i).amount,gt_to_plan(gn_i).case_am);
      IF (ln_mod_chk <> 0) THEN
        -- 入出庫換算単位の判定
        IF (gt_to_plan(gn_i).conv_unit IS NOT NULL) THEN
          -- 入出庫換算単位が設定されている場合、確定項目 'エラー'
          lv_dsc := gv_tkn_msg_err;
        ELSE
          -- 入出庫換算単位が未設定の場合、確定項目 '－'
          lv_dsc := gv_tkn_msg_hfn;
        END IF;
--
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
           ,iv_dec          => lv_dsc                             --  in 確定
           ,iv_req_no       => gv_req_no                          --  in 依頼No
           ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
           ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
           ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
           ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
           ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                                  --  in 着日
           ,iv_err_msg      => gv_tkn_msg_21                      --  in エラーメッセージ
           ,iv_err_clm      => gv_tkn_msg_hfn                     --  in エラー項目  '-'
           ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                         -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了STの判定
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
--
        RAISE err_header_expt;
      END IF;
--
    -- (3).(2)以外、「数量」設定
    ELSE
      gn_ship_amount := gt_to_plan(gn_i).amount;
--
      -- 受注ヘッダアドオン項目用変数 加算
      gn_ttl_amount   := gn_ttl_amount   + NVL(gt_to_plan(gn_i).amount,0);  -- 合計数量
      gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;                  -- 出荷単位換算数
      gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_detail_we,0);             -- 積載重量合計
      gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_detail_ca,0);             -- 積載容積合計
      gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);            -- 合計パレット重量
--
    END IF;
*/
-- 2008/07/30 Mod ↑
--
  EXCEPTION
    -- *** 共通関数 警告・エラー ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_2;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_lines_create;
--
-- 2008/10/09 H.Itou Add Start 統合テスト指摘118
  /**********************************************************************************
   * Procedure Name   : pro_duplication_item_chk
   * Description      : 品目重複チェック (A-13)
   ***********************************************************************************/
  PROCEDURE pro_duplication_item_chk
    (
      in_plan_cnt   IN  NUMBER       -- 対象としているForecastの件数
     ,ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_duplication_item_chk'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_dup_item_err_flg VARCHAR2(1);  -- 品目重複エラーフラグ
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<line_loop>>  -- ヘッダに紐付く明細全件ループ
    FOR ln_line_loop_cnt IN in_plan_cnt - gn_line_number + 1..in_plan_cnt LOOP
      <<chk_loop>>  -- 品目重複エラーチェックループ
      FOR ln_chk_loop_cnt IN in_plan_cnt - gn_line_number + 1..in_plan_cnt LOOP
        -- 同一品目がある場合、品目重複エラー
        IF ((ln_line_loop_cnt <> ln_chk_loop_cnt)
        AND (gt_to_plan(ln_line_loop_cnt).item_no  = gt_to_plan(ln_chk_loop_cnt).item_no)) THEN
          -- エラーリスト作成
          pro_err_list_make
            (
              iv_kind         => gv_tkn_msg_err                                --  in 種別   'エラー'
             ,iv_dec          => gv_tkn_msg_hfn                                --  in 確定   '-'
             ,iv_req_no       => gv_req_no                                     --  in 依頼No
             ,iv_kyoten       => gt_to_plan(ln_line_loop_cnt).ktn              --  in 管轄拠点
             ,iv_item         => gt_to_plan(ln_line_loop_cnt).item_no          --  in 品目
             ,in_qty          => gt_to_plan(ln_line_loop_cnt).amount           --  in 数量
             ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')             --  in 出庫日 [出荷予定日]
             ,iv_arrival_date => TO_CHAR(gt_to_plan(ln_line_loop_cnt).for_date, 'YYYY/MM/DD')
                                                                               --  in 着日
             ,iv_err_msg      => gv_tkn_msg_25                                 --  in エラーメッセージ
             ,iv_err_clm      => gv_tkn_msg_hfn                                --  in エラー項目  '-'
             ,in_msg_seq      => gt_to_plan(ln_line_loop_cnt).dup_item_msg_seq --  in 品目重複メッセージ格納SEQ
             ,ov_errbuf       => lv_errbuf                                     -- out エラー・メッセージ
             ,ov_retcode      => lv_retcode                                    -- out リターン・コード
             ,ov_errmsg       => lv_errmsg                                     -- out ユーザー・エラー・メッセージ
            );
--
          -- 品目重複エラーフラグ：エラーあり
          lv_dup_item_err_flg := gv_status_error;
--
          -- 品目重複エラーをみつけたら、品目重複エラーチェックループ終了
          EXIT;
        END IF;
      END LOOP chk_loop;
    END LOOP line_loop;
--
    -- 品目重複エラーがあった場合
    IF (lv_dup_item_err_flg = gv_status_error) THEN
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
      RAISE err_header_expt;
    END IF;
--
  EXCEPTION
--
    -- *** 共通関数 警告・エラー ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_duplication_item_chk;
-- 2008/10/09 H.Itou Add End
--
  /**********************************************************************************
   * Procedure Name   : pro_load_eff_chk
   * Description      : 積載効率チェック (A-10)
   ***********************************************************************************/
  PROCEDURE pro_load_eff_chk
    (
      in_plan_cnt   IN  NUMBER       -- 対象としているForecastの件数 --2008/08/06 Add
     ,ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_load_eff_chk'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_errmsg_code VARCHAR2(30);  -- エラー・メッセージ・コード
--
    ln_cnt     NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    ln_cnt := in_plan_cnt;
--
   -- 共通関数｢積載効率チェック(積載効率算出)｣にてチェック (明細重量の場合)
    xxwsh_common910_pkg.calc_load_efficiency
                            (
                              gn_h_ttl_weight             -- 合計重量         in 積載重量合計
                             ,NULL                        -- 合計容積         in NULL
                             ,gv_4                        -- コード区分From   in 倉庫'4'
/* 2008/08/06 Mod ↓
                             ,gt_to_plan(gn_i).ship_fr    -- 入出庫区分From   in 出荷元
2008/08/06 Mod ↑ */
                             ,gt_to_plan(ln_cnt).ship_fr  -- 入出庫区分From   in 出荷元
                             ,gv_9                        -- コード区分To     in 配送先'9'
/* 2008/08/06 Mod ↓
                             ,gt_to_plan(gn_i).ship_t_no  -- 入出庫区分To     in 配送先
2008/08/06 Mod ↑ */
                             ,gt_to_plan(ln_cnt).ship_t_no -- 入出庫区分To     in 配送先
                             ,gv_max_kbn                  -- 最大配送区分     in 最大配送区分
/* 2008/08/06 Mod ↓
                             ,gt_to_plan(gn_i).skbn       -- 商品区分         in 商品区分(リーフ)
2008/08/06 Mod ↑ */
                             ,gt_to_plan(ln_cnt).skbn     -- 商品区分         in 商品区分(リーフ)
                             ,NULL                        -- 自動配車対象区分 in NULL
                             ,gd_ship_day                 -- 基準日           in 出荷予定日
                             ,lv_retcode                  -- リターン・コード
                             ,lv_errmsg_code              -- エラー・メッセージ・コード
                             ,lv_errmsg                   -- エラー・メッセージ
                             ,gv_over_kbn                 -- 積載オーバー区分 0:正常,1:オーバー
                             ,gv_ship_way                 -- 出荷方法
                             ,gn_we_loading               -- 重量積載効率
                             ,gn_ca_dammy                 -- 容積積載効率
                             ,gv_mix_ship                 -- 混載配送区分
                            );
--
    -- リターンコードがエラー時、エラー
    IF (lv_retcode = gv_1) THEN
--
-- 2008/08/13 H.Itou ADD START 出荷追加_1 積載効率エラーのワーニングは明細ごとに出力
      <<err_loop>>
      FOR i IN ln_cnt - gn_line_number + 1..ln_cnt LOOP
-- 2008/08/13 H.Itou ADD END
      -- エラーリスト作成
-- 2008/08/13 H.Itou MOD START
--      pro_err_list_make
--        (
--          iv_kind         => gv_tkn_msg_err                     --  in 種別  'エラー'
--         ,iv_dec          => gv_tkn_msg_hfn                     --  in 確定  '-'
--         ,iv_req_no       => gv_req_no                          --  in 依頼No
--/* 2008/08/06 Mod ↓
--         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
--2008/08/06 Mod ↑ */
--         ,iv_kyoten       => gt_to_plan(ln_cnt).ktn             --  in 管轄拠点
--/* 2008/08/06 Mod ↓
--         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
--2008/08/06 Mod ↑ */
--         ,iv_item         => gt_to_plan(ln_cnt).item_no         --  in 品目
--/* 2008/08/06 Mod ↓
--         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
--2008/08/06 Mod ↑ */
--         ,in_qty          => gt_to_plan(ln_cnt).amount          --  in 数量
--         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
--/* 2008/08/06 Mod ↓
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
--2008/08/06 Mod ↑ */
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(ln_cnt).for_date,'YYYY/MM/DD')
--                                                                --  in 着日
--         ,iv_err_msg      => lv_errmsg                          --  in エラーメッセージ
--         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in エラー項目  '-'
--         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
--         ,ov_retcode      => lv_retcode                         -- out リターン・コード
--         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
--        );
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
           ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
           ,iv_req_no       => gv_req_no                          --  in 依頼No
           ,iv_kyoten       => gt_to_plan(i).ktn                  --  in 管轄拠点
           ,iv_item         => gt_to_plan(i).item_no              --  in 品目
           ,in_qty          => gt_to_plan(i).amount               --  in 数量
           ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
           ,iv_arrival_date => TO_CHAR(gt_to_plan(i).for_date,'YYYY/MM/DD')
                                                                  --  in 着日
           ,iv_err_msg      => gv_tkn_msg_20                      --  in エラーメッセージ
           ,iv_err_clm      => gt_to_plan(i).amount               --  in エラー項目  [数量]
-- 2008/08/18 H.Itou Add Start 積載効率メッセージを格納するSEQ番号
           ,in_msg_seq      => gt_to_plan(i).we_loading_msg_seq   -- 積載効率(重量)メッセージ格納SEQ
--
-- 2008/08/18 H.Itou Add End
           ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                         -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
          );
-- 2008/08/13 H.Itou MOD END
-- 2008/08/13 H.Itou ADD START
      END LOOP err_loop;
-- 2008/08/13 H.Itou ADD END
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
-- 2008/08/06 Mod ↓
-- 2008/07/30 Mod ↓
--/*
--    -- 積載オーバー時、ワーニング
--    IF (gv_over_kbn = gv_1) THEN
--*/
--    -- 重量容積区分が重量で積載オーバー時、ワーニング
--    IF ((gv_over_kbn = gv_1) AND (gt_to_plan(gn_i).wei_kbn = gv_1)) THEN
    IF ((gv_over_kbn = gv_1) AND (gt_to_plan(ln_cnt).wei_kbn = gv_1)) THEN
-- 2008/07/30 Mod ↑
-- 2008/08/06 Mod ↑
--
-- 2008/08/13 H.Itou ADD START 出荷追加_1 積載効率エラーのワーニングは明細ごとに出力
      <<warn_loop>>
      FOR i IN ln_cnt - gn_line_number + 1..ln_cnt LOOP
-- 2008/08/13 H.Itou ADD END
      -- エラーリスト作成
-- 2008/08/13 H.Itou MOD START
--      pro_err_list_make
--        (
--          iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
--         ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
--         ,iv_req_no       => gv_req_no                          --  in 依頼No
--/* 2008/08/06 Mod ↓
--         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
--2008/08/06 Mod ↑ */
--         ,iv_kyoten       => gt_to_plan(ln_cnt).ktn             --  in 管轄拠点
--/* 2008/08/06 Mod ↓
--         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
--2008/08/06 Mod ↑ */
--         ,iv_item         => gt_to_plan(ln_cnt).item_no         --  in 品目
--/* 2008/08/06 Mod ↓
--         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
--2008/08/06 Mod ↑ */
--         ,in_qty          => gt_to_plan(ln_cnt).amount          --  in 数量
--         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
--/* 2008/08/06 Mod ↓
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
--2008/08/06 Mod ↑ */
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(ln_cnt).for_date,'YYYY/MM/DD')
--                                                                --  in 着日
--         ,iv_err_msg      => gv_tkn_msg_20                      --  in エラーメッセージ
--/* 2008/08/06 Mod ↓
--         ,iv_err_clm      => gt_to_plan(gn_i).amount            --  in エラー項目  [数量]
--2008/08/06 Mod ↑ */
--         ,iv_err_clm      => gt_to_plan(ln_cnt).amount          --  in エラー項目  [数量]
--         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
--         ,ov_retcode      => lv_retcode                         -- out リターン・コード
--         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
--        );
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
           ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
           ,iv_req_no       => gv_req_no                          --  in 依頼No
           ,iv_kyoten       => gt_to_plan(i).ktn                  --  in 管轄拠点
           ,iv_item         => gt_to_plan(i).item_no              --  in 品目
           ,in_qty          => gt_to_plan(i).amount               --  in 数量
           ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
           ,iv_arrival_date => TO_CHAR(gt_to_plan(i).for_date,'YYYY/MM/DD')
                                                                  --  in 着日
           ,iv_err_msg      => gv_tkn_msg_20                      --  in エラーメッセージ
           ,iv_err_clm      => gt_to_plan(i).amount               --  in エラー項目  [数量]
-- 2008/08/18 H.Itou Add Start 積載効率メッセージを格納するSEQ番号
           ,in_msg_seq      => gt_to_plan(i).we_loading_msg_seq   -- 積載効率(重量)メッセージ格納SEQ
-- 2008/08/18 H.Itou Add End
           ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                         -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
          );
-- 2008/08/13 H.Itou MOD END
-- 2008/08/13 H.Itou MOD START
        -- 共通エラーメッセージ 終了STの判定
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
-- 2008/08/13 H.Itou MOD END
-- 2008/08/13 H.Itou ADD START
      END LOOP warn_loop;
-- 2008/08/13 H.Itou ADD END
    END IF;
--
    -- 共通関数｢積載効率チェック(積載効率算出)｣にてチェック (明細容積の場合)
    xxwsh_common910_pkg.calc_load_efficiency
                            (
                              NULL                        -- 合計重量         in NULL
                             ,gn_h_ttl_capa               -- 合計容積         in 積載容積合計
                             ,gv_4                        -- コード区分From   in 倉庫'4'
/* 2008/08/06 Mod ↓
                             ,gt_to_plan(gn_i).ship_fr    -- 入出庫区分From   in 出荷元
2008/08/06 Mod ↑ */
                             ,gt_to_plan(ln_cnt).ship_fr  -- 入出庫区分From   in 出荷元
                             ,gv_9                        -- コード区分To     in 配送先'9'
/* 2008/08/06 Mod ↓
                             ,gt_to_plan(gn_i).ship_t_no  -- 入出庫区分To     in 配送先
2008/08/06 Mod ↑ */
                             ,gt_to_plan(ln_cnt).ship_t_no  -- 入出庫区分To     in 配送先
                             ,gv_max_kbn                  -- 最大配送区分     in 最大配送区分
/* 2008/08/06 Mod ↓
                             ,gt_to_plan(gn_i).skbn       -- 商品区分         in 商品区分(リーフ)
2008/08/06 Mod ↑ */
                             ,gt_to_plan(ln_cnt).skbn     -- 商品区分         in 商品区分(リーフ)
                             ,NULL                        -- 自動配車対象区分 in NULL
                             ,gd_ship_day                 -- 基準日           in 出荷予定日
                             ,lv_retcode                  -- リターン・コード
                             ,lv_errmsg_code              -- エラー・メッセージ・コード
                             ,lv_errmsg                   -- エラー・メッセージ
                             ,gv_over_kbn                 -- 積載オーバー区分 0:正常,1:オーバー
                             ,gv_ship_way                 -- 出荷方法
                             ,gn_we_dammy                 -- 重量積載効率
                             ,gn_ca_loading               -- 容積積載効率
                             ,gv_mix_ship                 -- 混載配送区分
                            );
--
    -- リターンコードがエラー時、エラー
    IF (lv_retcode = gv_1) THEN
--
-- 2008/08/13 H.Itou ADD START 出荷追加_1 積載効率エラーのワーニングは明細ごとに出力
      <<err_loop>>
      FOR i IN ln_cnt - gn_line_number + 1..ln_cnt LOOP
-- 2008/08/13 H.Itou ADD END
      -- エラーリスト作成
-- 2008/08/13 H.Itou MOD START
--      pro_err_list_make
--        (
--          iv_kind         => gv_tkn_msg_err                     --  in 種別  'エラー'
--         ,iv_dec          => gv_tkn_msg_hfn                     --  in 確定  '-'
--         ,iv_req_no       => gv_req_no                          --  in 依頼No
--/* 2008/08/06 Mod ↓
--         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
--2008/08/06 Mod ↑ */
--         ,iv_kyoten       => gt_to_plan(ln_cnt).ktn             --  in 管轄拠点
--/* 2008/08/06 Mod ↓
--         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
--2008/08/06 Mod ↑ */
--         ,iv_item         => gt_to_plan(ln_cnt).item_no         --  in 品目
--/* 2008/08/06 Mod ↓
--         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
--2008/08/06 Mod ↑ */
--         ,in_qty          => gt_to_plan(ln_cnt).amount          --  in 数量
--         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
--/* 2008/08/06 Mod ↓
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
--2008/08/06 Mod ↑ */
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(ln_cnt).for_date,'YYYY/MM/DD')
--                                                                --  in 着日
--         ,iv_err_msg      => lv_errmsg                          --  in エラーメッセージ
--         ,iv_err_clm      => gv_tkn_msg_hfn                     --  in エラー項目  '-'
--         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
--         ,ov_retcode      => lv_retcode                         -- out リターン・コード
--         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
--        );
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
           ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
           ,iv_req_no       => gv_req_no                          --  in 依頼No
           ,iv_kyoten       => gt_to_plan(i).ktn                  --  in 管轄拠点
           ,iv_item         => gt_to_plan(i).item_no              --  in 品目
           ,in_qty          => gt_to_plan(i).amount               --  in 数量
           ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
           ,iv_arrival_date => TO_CHAR(gt_to_plan(i).for_date,'YYYY/MM/DD')
                                                                  --  in 着日
           ,iv_err_msg      => gv_tkn_msg_20                      --  in エラーメッセージ
           ,iv_err_clm      => gt_to_plan(i).amount               --  in エラー項目  [数量]
-- 2008/08/18 H.Itou Add Start 積載効率メッセージを格納するSEQ番号
           ,in_msg_seq      => gt_to_plan(i).ca_loading_msg_seq   -- 積載効率(容積)メッセージ格納SEQ
-- 2008/08/18 H.Itou Add End
           ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                         -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
          );
-- 2008/08/13 H.Itou MOD END
-- 2008/08/13 H.Itou ADD START
      END LOOP err_loop;
-- 2008/08/13 H.Itou ADD END
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
-- 2008/08/06 Mod ↓
-- 2008/07/30 Mod ↓
--/*
--    -- 積載オーバー時、ワーニング
--    IF (gv_over_kbn = gv_1) THEN
--*/
--    -- 重量容積区分が容積で積載オーバー時、ワーニング
--    IF ((gv_over_kbn = gv_1) AND (gt_to_plan(gn_i).wei_kbn = gv_2)) THEN
    IF ((gv_over_kbn = gv_1) AND (gt_to_plan(ln_cnt).wei_kbn = gv_2)) THEN
-- 2008/07/30 Mod ↑
-- 2008/08/06 Mod ↑
--
-- 2008/08/13 H.Itou ADD START 出荷追加_1 積載効率エラーのワーニングは明細ごとに出力
      <<warn_loop>>
      FOR i IN ln_cnt - gn_line_number + 1..ln_cnt LOOP
-- 2008/08/13 H.Itou ADD END
      -- エラーリスト作成
-- 2008/08/13 H.Itou MOD START
--      pro_err_list_make
--        (
--          iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
--         ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
--         ,iv_req_no       => gv_req_no                          --  in 依頼No
--/* 2008/08/06 Mod ↓
--         ,iv_kyoten       => gt_to_plan(gn_i).ktn               --  in 管轄拠点
--2008/08/06 Mod ↑ */
--         ,iv_kyoten       => gt_to_plan(ln_cnt).ktn             --  in 管轄拠点
--/* 2008/08/06 Mod ↓
--         ,iv_item         => gt_to_plan(gn_i).item_no           --  in 品目
--2008/08/06 Mod ↑ */
--         ,iv_item         => gt_to_plan(ln_cnt).item_no         --  in 品目
--/* 2008/08/06 Mod ↓
--         ,in_qty          => gt_to_plan(gn_i).amount            --  in 数量
--2008/08/06 Mod ↑ */
--         ,in_qty          => gt_to_plan(ln_cnt).amount          --  in 数量
--         ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
--/* 2008/08/06 Mod ↓
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
--2008/08/06 Mod ↑ */
--         ,iv_arrival_date => TO_CHAR(gt_to_plan(ln_cnt).for_date,'YYYY/MM/DD')
--                                                                --  in 着日
--         ,iv_err_msg      => gv_tkn_msg_20                      --  in エラーメッセージ
--/* 2008/08/06 Mod ↓
--         ,iv_err_clm      => gt_to_plan(gn_i).amount            --  in エラー項目  [数量]
--2008/08/06 Mod ↑ */
--         ,iv_err_clm      => gt_to_plan(ln_cnt).amount          --  in エラー項目  [数量]
--         ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
--         ,ov_retcode      => lv_retcode                         -- out リターン・コード
--         ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
--        );
--
        pro_err_list_make
          (
            iv_kind         => gv_tkn_msg_war                     --  in 種別  '警告'
           ,iv_dec          => gv_tkn_msg_err                     --  in 確定  'エラー'
           ,iv_req_no       => gv_req_no                          --  in 依頼No
           ,iv_kyoten       => gt_to_plan(i).ktn                  --  in 管轄拠点
           ,iv_item         => gt_to_plan(i).item_no              --  in 品目
           ,in_qty          => gt_to_plan(i).amount               --  in 数量
           ,iv_ship_date    => TO_CHAR(gd_ship_day,'YYYY/MM/DD')  --  in 出庫日 [出荷予定日]
           ,iv_arrival_date => TO_CHAR(gt_to_plan(i).for_date,'YYYY/MM/DD')
                                                                  --  in 着日
           ,iv_err_msg      => gv_tkn_msg_20                      --  in エラーメッセージ
           ,iv_err_clm      => gt_to_plan(i).amount               --  in エラー項目  [数量]
-- 2008/08/18 H.Itou Add Start 積載効率メッセージを格納するSEQ番号
           ,in_msg_seq      => gt_to_plan(i).ca_loading_msg_seq   -- 積載効率(容積)メッセージ格納SEQ
-- 2008/08/18 H.Itou Add End
           ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                         -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
          );
-- 2008/08/13 H.Itou MOD END
-- 2008/08/13 H.Itou MOD START
        -- 共通エラーメッセージ 終了STの判定
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
-- 2008/08/13 H.Itou MOD END
-- 2008/08/13 H.Itou ADD START 出荷追加_1 積載効率エラーのワーニングは明細ごとに出力
      END LOOP warn_loop;
-- 2008/08/13 H.Itou ADD END
    END IF;
--
  EXCEPTION
    -- *** 共通関数 警告・エラー ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_load_eff_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_headers_create
   * Description      : 受注ヘッダアドオンレコード生成 (A-11)
   ***********************************************************************************/
  PROCEDURE pro_headers_create
    (
      in_plan_cnt   IN  NUMBER       -- 対象としているForecastの件数
     ,ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_headers_create'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2008/10/09 H.Itou Del Start ヘッダレコードを作る直前に移動
--    gn_h_cnt := gn_h_cnt + 1;
-- 2008/10/09 H.Itou Del End
--
-- 2008/10/09 H.Itou Add Start 統合テスト指摘240
    -- =====================================================
    -- 品目重複チェック (A-13)
    -- =====================================================
    pro_duplication_item_chk
      (
        in_plan_cnt       => in_plan_cnt        -- 対象としているForecastの件数
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
-- 2008/10/09 H.Itou Add End
--
    -- =====================================================
    -- 積載効率チェック (A-10)
    -- =====================================================
    pro_load_eff_chk
      (
        in_plan_cnt       => in_plan_cnt        -- 対象としているForecastの件数 --2008/08/06 Add
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
      --RAISE global_process_expt;
    END IF;
--
-- 2008/10/09 H.Itou Add Start
    -- 品目重複エラーか、積載効率チェックエラーの時はヘッダレコードを作成しない。
    IF (gv_err_flg <> gv_1) THEN
      -- ヘッダ作成レコードカウントアップ
      gn_h_cnt := gn_h_cnt + 1;
-- 2008/10/09 H.Itou Add End
      ------------------------------------------------------
      -- 受注ヘッダアドオン作成用レコード変数へ格納       --
      ------------------------------------------------------
--
      gt_h_order_header_id(gn_h_cnt)         := gn_headers_seq;              -- 受注ヘッダアドオンID
      gt_h_order_type_id(gn_h_cnt)           := gv_odr_type;                 -- 受注タイプID
      gt_h_organization_id(gn_h_cnt)         := gv_name_m_org;               -- 組織ID
      gt_h_latest_external_flag(gn_h_cnt)    := gv_yes;                      -- 最新フラグ
      gt_h_ordered_date(gn_h_cnt)            := gd_sysdate;                  -- 受注日
      --gt_h_customer_id(gn_h_cnt)             := gt_to_plan(gn_i).par_id;     -- 顧客ID
      --gt_h_customer_code(gn_h_cnt)           := gt_to_plan(gn_i).par_num;    -- 顧客
      --gt_h_deliver_to_id(gn_h_cnt)           := gt_to_plan(gn_i).p_s_site;   -- 配送先ID
      --gt_h_deliver_to(gn_h_cnt)              := gt_to_plan(gn_i).ship_t_no;  -- 配送先
      --
      gt_h_customer_id(gn_h_cnt)             := gt_to_plan(in_plan_cnt).par_id;     -- 顧客ID
      gt_h_customer_code(gn_h_cnt)           := gt_to_plan(in_plan_cnt).par_num;    -- 顧客
      gt_h_deliver_to_id(gn_h_cnt)           := gt_to_plan(in_plan_cnt).p_s_site;   -- 配送先ID
      gt_h_deliver_to(gn_h_cnt)              := gt_to_plan(in_plan_cnt).ship_t_no;  -- 配送先
      --
-- 2008/08/19 H.Itou Add Start T_S_611
      gt_h_career_id(gn_h_cnt)               := gt_to_plan(in_plan_cnt).career_id;            -- 運送業者ID
      gt_h_freight_carrier_code(gn_h_cnt)    := gt_to_plan(in_plan_cnt).freight_carrier_code; -- 運送業者
-- 2008/08/19 H.Itou Add End
      gt_h_shipping_method_code(gn_h_cnt)    := gv_max_kbn;                  -- 配送区分
      gt_h_request_no(gn_h_cnt)              := gv_req_no;                   -- 依頼No
      gt_h_req_status(gn_h_cnt)              := gr_ship_st;                  -- ステータス
      gt_h_schedule_ship_date(gn_h_cnt)      := gd_ship_day;                 -- 出荷予定日
      --gt_h_schedule_arrival_date(gn_h_cnt)   := gt_to_plan(gn_i).for_date;   -- 着荷予定日
      gt_h_schedule_arrival_date(gn_h_cnt)   := gt_to_plan(in_plan_cnt).for_date;   -- 着荷予定日
      gt_h_notif_status(gn_h_cnt)            := gr_notice_st;                -- 通知ステータス
      --gt_h_deliver_from_id(gn_h_cnt)         := gt_to_plan(gn_i).ship_id;    -- 出荷元ID
      --gt_h_deliver_from(gn_h_cnt)            := gt_to_plan(gn_i).ship_fr;    -- 出荷元保管場所
      --gt_h_Head_sales_branch(gn_h_cnt)       := gt_to_plan(gn_i).ktn;        -- 管轄拠点
      gt_h_deliver_from_id(gn_h_cnt)         := gt_to_plan(in_plan_cnt).ship_id;    -- 出荷元ID
      gt_h_deliver_from(gn_h_cnt)            := gt_to_plan(in_plan_cnt).ship_fr;    -- 出荷元保管場所
      gt_h_Head_sales_branch(gn_h_cnt)       := gt_to_plan(in_plan_cnt).ktn;        -- 管轄拠点
--2008/10/16 MOD START
--      gt_h_input_sales_branch(gn_h_cnt)      := gr_param.base;               -- 入力拠点
      gt_h_input_sales_branch(gn_h_cnt)      := gt_to_plan(in_plan_cnt).ktn; -- 入力拠点
--2008/10/16 MOD END
      --gt_h_prod_class(gn_h_cnt)              := gt_to_plan(gn_i).skbn;       -- 商品区分
      gt_h_prod_class(gn_h_cnt)              := gt_to_plan(in_plan_cnt).skbn; -- 商品区分
      gt_h_sum_quantity(gn_h_cnt)            := gn_ttl_amount;               -- 合計数量
      gt_h_small_quantity(gn_h_cnt)          := gn_ttl_ship_am;              -- 小口個数
      gt_h_label_quantity(gn_h_cnt)          := gn_ttl_ship_am;              -- ラベル枚数
      gt_h_loading_eff_weight(gn_h_cnt)      := gn_we_loading;               -- 重量積載効率
      gt_h_loading_eff_capacity(gn_h_cnt)    := gn_ca_loading;               -- 容積積載効率
      gt_h_based_weight(gn_h_cnt)            := gn_leaf_we;                  -- 基本重量
      gt_h_based_capacity(gn_h_cnt)          := gn_leaf_ca;                  -- 基本容積
      gt_h_sum_weight(gn_h_cnt)              := gn_h_ttl_weight;             -- 積載重量合計
      gt_h_sum_capacity(gn_h_cnt)            := gn_h_ttl_capa;               -- 積載容積合計
      gt_h_sum_pallet_weight(gn_h_cnt)       := gn_h_ttl_pallet;             -- 合計パレット重量
      --gt_h_weight_capacity_class(gn_h_cnt)   := gt_to_plan(gn_i).wei_kbn;      -- 重量容積区分
      gt_h_weight_capacity_class(gn_h_cnt)   := gt_to_plan(in_plan_cnt).wei_kbn; -- 重量容積区分
      gt_h_actual_confirm_class(gn_h_cnt)    := gv_no;                       -- 実績計上済区分
      gt_h_new_modify_flg(gn_h_cnt)          := gv_no;                       -- 新規修正フラグ
      gt_h_per_management_dept(gn_h_cnt)     := NULL;                        -- 成績管理部署
      gt_h_screen_update_date(gn_h_cnt)      := NULL;                        -- 画面更新日時
-- add start 1.7 uehara
      gt_h_confirm_request_class(gn_h_cnt)   := gv_0;                        -- 物流担当確認依頼区分
      gt_h_freight_charge_class(gn_h_cnt)    := gv_1;                        -- 運賃区分
      gt_h_no_cont_freight_class(gn_h_cnt)   := gv_0;                        -- 契約外運賃区分
-- add end 1.7 uehara
      gt_h_created_by(gn_h_cnt)              := gn_created_by;               -- 作成者
      gt_h_creation_date(gn_h_cnt)           := gd_creation_date;            -- 作成日
      gt_h_last_updated_by(gn_h_cnt)         := gn_last_upd_by;              -- 最終更新者
      gt_h_last_update_date(gn_h_cnt)        := gd_last_upd_date;            -- 最終更新日
      gt_h_last_update_login(gn_h_cnt)       := gn_last_upd_login;           -- 最終更新ログイン
      gt_h_request_id(gn_h_cnt)              := gn_request_id;               -- 要求ID
      gt_h_program_application_id(gn_h_cnt)  := gn_prog_appl_id;             -- プログラムアプリID
      gt_h_program_id(gn_h_cnt)              := gn_prog_id;                  -- プログラムID
      gt_h_program_update_date(gn_h_cnt)     := gd_prog_upd_date;            -- プログラム更新日
--
-- 2008/10/09 H.Itou Add Start
    END IF;
-- 2008/10/09 H.Itou Add End
    -- 受注ヘッダアドオン項目用変数 初期化
    gn_ttl_ship_am  := 0;       -- 出荷単位換算数
    gn_ttl_amount   := 0;       -- 合計数量
    gn_h_ttl_weight := 0;       -- 積載重量合計
    gn_h_ttl_capa   := 0;       -- 積載容積合計
    gn_h_ttl_pallet := 0;       -- 合計パレット重量
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_headers_create;
--
  /**********************************************************************************
   * Procedure Name   : pro_ship_order
   * Description      : 出荷依頼登録処理 (A-12)
   ***********************************************************************************/
  PROCEDURE pro_ship_order
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_ship_order'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- *************************************************
    -- ***  受注ヘッダアドオンテーブル一括更新       ***
    -- *************************************************
    FORALL i IN gt_h_order_header_id.FIRST .. gt_h_order_header_id.LAST
      INSERT INTO xxwsh_order_headers_all
        ( order_header_id
         ,order_type_id
         ,organization_id
         ,latest_external_flag
         ,ordered_date
         ,customer_id
         ,customer_code
         ,deliver_to_id
         ,deliver_to
-- 2008/08/19 H.Itou Add Start T_S_611
         ,career_id                     -- 運送業者ID
         ,freight_carrier_code          -- 運送業者
-- 2008/08/19 H.Itou Add End
         ,shipping_method_code
         ,request_no
         ,req_status
         ,schedule_ship_date
         ,schedule_arrival_date
         ,notif_status
         ,deliver_from_id
         ,deliver_from
         ,Head_sales_branch 
         ,input_sales_branch
         ,prod_class
         ,sum_quantity
         ,small_quantity
         ,label_quantity
         ,loading_efficiency_weight
         ,loading_efficiency_capacity
         ,based_weight
         ,based_capacity
         ,sum_weight
         ,sum_capacity
         ,sum_pallet_weight
         ,weight_capacity_class
         ,actual_confirm_class
         ,new_modify_flg
         ,performance_management_dept
         ,screen_update_date
-- add start 1.7 uehara
         ,confirm_request_class
         ,freight_charge_class
         ,no_cont_freight_class
-- add end 1.7 uehara
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
         ,request_id
         ,program_application_id
         ,program_id
         ,program_update_date
        ) VALUES
        ( gt_h_order_header_id(i)
         ,gt_h_order_type_id(i)
         ,gt_h_organization_id(i)
         ,gt_h_latest_external_flag(i)
         ,gt_h_ordered_date(i)
         ,gt_h_customer_id(i)
         ,gt_h_customer_code(i)
         ,gt_h_deliver_to_id(i)
         ,gt_h_deliver_to(i)
-- 2008/08/19 H.Itou Add Start T_S_611
         ,gt_h_career_id(i)             -- 運送業者ID
         ,gt_h_freight_carrier_code(i)  -- 運送業者
-- 2008/08/19 H.Itou Add End
         ,gt_h_shipping_method_code(i)
         ,gt_h_request_no(i)
         ,gt_h_req_status(i)
         ,gt_h_schedule_ship_date(i)
         ,gt_h_schedule_arrival_date(i)
         ,gt_h_notif_status(i)
         ,gt_h_deliver_from_id(i)
         ,gt_h_deliver_from(i)
         ,gt_h_Head_sales_branch(i)
         ,gt_h_input_sales_branch(i)
         ,gt_h_prod_class(i)
         ,gt_h_sum_quantity(i)
         ,gt_h_small_quantity(i)
         ,gt_h_label_quantity(i)
         ,gt_h_loading_eff_weight(i)
         ,gt_h_loading_eff_capacity(i)
         ,gt_h_based_weight(i)
         ,gt_h_based_capacity(i)
         ,gt_h_sum_weight(i)
         ,gt_h_sum_capacity(i)
         ,gt_h_sum_pallet_weight(i)
         ,gt_h_weight_capacity_class(i)
         ,gt_h_actual_confirm_class(i)
         ,gt_h_new_modify_flg(i)
         ,gt_h_per_management_dept(i)
         ,gt_h_screen_update_date(i)
-- add start 1.7 uehara
         ,gt_h_confirm_request_class(i)
         ,gt_h_freight_charge_class(i)
         ,gt_h_no_cont_freight_class(i)
-- add end 1.7 uehara
         ,gt_h_created_by(i)
         ,gt_h_creation_date(i)
         ,gt_h_last_updated_by(i)
         ,gt_h_last_update_date(i)
         ,gt_h_last_update_login(i)
         ,gt_h_request_id(i)
         ,gt_h_program_application_id(i)
         ,gt_h_program_id(i)
         ,gt_h_program_update_date(i)
        );
--
    -- *************************************************
    -- ***  受注明細アドオンテーブル一括更新         ***
    -- *************************************************
    FORALL i IN gt_l_order_line_id.FIRST .. gt_l_order_line_id.LAST
      INSERT INTO xxwsh_order_lines_all
        ( order_line_id
         ,order_header_id
         ,order_line_number
         ,request_no
         ,shipping_inventory_item_id
         ,shipping_item_code
         ,quantity
         ,uom_code
         ,based_request_quantity
         ,request_item_id
         ,request_item_code
         ,weight
         ,capacity
         ,pallet_weight
         ,delete_flag
-- 2009/12/09 M.Miyagawa Add Start 本番障害#267
         ,shipping_request_if_flg
         ,shipping_result_if_flg
-- 2009/12/09 M.Miyagawa Add End 本番障害#267
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
         ,request_id
         ,program_application_id
         ,program_id
         ,program_update_date
        ) VALUES
        ( gt_l_order_line_id(i)
         ,gt_l_order_header_id(i)
         ,gt_l_order_line_number(i)
         ,gt_l_request_no(i)
         ,gt_l_shipping_inv_item_id(i)
         ,gt_l_shipping_item_code(i)
         ,gt_l_quantity(i)
         ,gt_l_uom_code(i)
         ,gt_l_based_request_quantity(i)
         ,gt_l_request_item_id(i)
         ,gt_l_request_item_code(i)
         ,gt_l_weight(i)
         ,gt_l_capacity(i)
         ,gt_l_pallet_weight(i)
         ,gt_l_delete_flag(i)
-- 2009/12/09 M.Miyagawa Add Start 本番障害#267
         ,gt_l_shipping_request_if_flg(i)
         ,gt_l_shipping_result_if_flg(i)
-- 2009/12/09 M.Miyagawa Add End 本番障害#267
         ,gt_l_created_by(i)
         ,gt_l_creation_date(i)
         ,gt_l_last_updated_by(i)
         ,gt_l_last_update_date(i)
         ,gt_l_last_update_login(i)
         ,gt_l_request_id(i)
         ,gt_l_program_application_id(i)
         ,gt_l_program_id(i)
         ,gt_l_program_update_date(i)
        );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_ship_order;
--
-- 2009/07/08 H.Itou Add Start 本番障害#1525
  /**********************************************************************************
   * Procedure Name   : pro_no_item_category_chk
   * Description      : 品目カテゴリ設定チェック (A-15)
   ***********************************************************************************/
  PROCEDURE pro_no_item_category_chk
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_no_item_category_chk'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
   -- *** レコード型宣言 ***
    TYPE rec_item_data IS RECORD(
      item_code       xxcmn_item_mst_v.item_no                %TYPE -- 品目コード
-- 2009/07/13 H.Itou Del Start 本番障害#1525 PT対応
--     ,item_class_code xxcmn_item_categories5_v.item_class_code%TYPE -- 品目区分
--     ,prod_class_code xxcmn_item_categories5_v.prod_class_code%TYPE -- 商品区分
-- 2009/07/13 H.Itou Del End
    );
--
   -- *** 配列型宣言 ***
   TYPE tab_item_data IS TABLE OF rec_item_data INDEX BY BINARY_INTEGER ;
--
    -- *** ローカル変数 ***
    lv_sql    VARCHAR2(30000);
--
    lr_item_data tab_item_data;
--
    -- *** カーソル宣言 ***
    cur_item_data  ref_cursor ;    -- カーソル
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==========================
    -- SQL文生成
    -- ==========================
    lv_sql := '
-- 2009/07/13 H.Itou Mod Start 本番障害#1525 PT対応
--      SELECT ximv.item_no               item_code                -- 品目コード
      SELECT /*+ index(mfds MRP_MFD_N02) index(mfd MRP_FORECAST_DATES_N1) */
             ximv.item_no               item_code                -- 品目コード
-- 2009/07/13 H.Itou Mod End
-- 2009/07/13 H.Itou Del Start 本番障害#1525 PT対応
--            ,xicv.item_class_code       item_class_code          -- 品目区分
--            ,xicv.prod_class_code       prod_class_code          -- 商品区分
-- 2009/07/13 H.Itou Del End
      FROM   mrp_forecast_designators   mfds                     -- フォーキャスト名
            ,mrp_forecast_dates         mfd                      -- フォーキャスト日付
            ,xxcmn_item_mst_v           ximv                     -- OPM品目情報VIEW
-- 2010/01/21 M.Miyagawa DEL Start 本番障害#601対応
--            ,xxcmn_item_categories5_v   xicv                     -- OPM品目カテゴリ割当情報VIEW
-- 2010/01/21 M.Miyagawa DEL End
-- 2010/01/21 M.Miyagawa ADD Start 本番障害#601対応
           --品目区分
           ,(SELECT  mct_h.description        AS item_class_name         --品目区分名
                    ,mcb_h.segment1           AS item_class_code         --品目区分
                    ,gic_h.item_id            AS item_id
             FROM    gmi_item_categories    gic_h
                    ,mtl_categories_b       mcb_h
                    ,mtl_categories_tl      mct_h
                    ,mtl_category_sets_b    mcsb_h
                    ,mtl_category_sets_tl   mcst_h
             WHERE   mct_h.source_lang         = ''JA''
                AND  mct_h.language            = ''JA''
                AND  mcb_h.category_id         = mct_h.category_id
                AND  mcsb_h.structure_id       = mcb_h.structure_id
                AND  gic_h.category_id         = mcb_h.category_id
                AND  mcst_h.source_lang        = ''JA''
                AND  mcst_h.language           = ''JA''
                AND  mcst_h.category_set_name  = ''品目区分''
                AND  mcsb_h.category_set_id    = mcst_h.category_set_id
                AND  gic_h.category_set_id     = mcsb_h.category_set_id
            ) hk
           --商品区分
           ,(SELECT  mct_s.description        AS prod_class_name         --商品区分名
                    ,mcb_s.segment1           AS prod_class_code         --商品区分
                    ,gic_s.item_id            AS item_id
             FROM    gmi_item_categories    gic_s
                    ,mtl_categories_b       mcb_s
                    ,mtl_categories_tl      mct_s
                    ,mtl_category_sets_b    mcsb_s
                    ,mtl_category_sets_tl   mcst_s
             WHERE   mct_s.source_lang         = ''JA''
                AND  mct_s.language            = ''JA''
                AND  mcb_s.category_id         = mct_s.category_id
                AND  mcsb_s.structure_id       = mcb_s.structure_id
                AND  gic_s.category_id         = mcb_s.category_id
                AND  mcst_s.source_lang        = ''JA''
                AND  mcst_s.language           = ''JA''
                AND  mcst_s.category_set_name  = ''商品区分''
                AND  mcsb_s.category_set_id    = mcst_s.category_set_id
                AND  gic_s.category_set_id     = mcsb_s.category_set_id
            ) sk
           -- 本社商品区分
           ,(SELECT  mct_hs.description prod_class_h_name                -- 本社商品区分名
                    ,mcb_hs.segment1    prod_class_h_code                -- 本社商品区分
                    ,gic_hs.item_id     item_id
             FROM    gmi_item_categories    gic_hs
                    ,mtl_categories_b       mcb_hs
                    ,mtl_categories_tl      mct_hs
                    ,mtl_category_sets_b    mcsb_hs
                    ,mtl_category_sets_tl   mcst_hs
             WHERE   mct_hs.source_lang        = ''JA''
                AND  mct_hs.language           = ''JA''
                AND  mcb_hs.category_id        = mct_hs.category_id
                AND  mcsb_hs.structure_id      = mcb_hs.structure_id
                AND  gic_hs.category_id        = mcb_hs.category_id
                AND  mcst_hs.source_lang       = ''JA''
                AND  mcst_hs.language          = ''JA''
                AND  mcst_hs.category_set_name = ''本社商品区分''
                AND  mcsb_hs.category_set_id   = mcst_hs.category_set_id
                AND  gic_hs.category_set_id    = mcsb_hs.category_set_id
            ) hs          
-- 2010/01/21 M.Miyagawa ADD End
      ';
-- 2009/07/13 H.Itou Add Start 本番障害#1525 PT対応
    -- 入力Ｐ[管轄拠点]に入力なしの場合、顧客情報を結合し、絞込みをする。
    IF (gr_param.base IS NULL) THEN
      lv_sql := lv_sql || '
-- 2009/07/13 H.Itou Add Start 本番障害#1525 PT対応
            ,xxcmn_cust_accounts_v      xcav                     -- 顧客情報VIEW
-- 2009/07/13 H.Itou Add End
      ';
    END IF;
-- 2009/07/13 H.Itou Add End
    lv_sql := lv_sql || '
      WHERE  mfds.forecast_designator = mfd.forecast_designator  -- フォーキャスト名
      AND    mfds.organization_id     = mfd.organization_id      -- 組織ID
      AND    mfd.inventory_item_id    = ximv.inventory_item_id   -- 品目
-- 2010/01/21 M.Miyagawa DEL Start 本番障害#601対応
--      AND    ximv.item_id             = xicv.item_id(+)          -- 品目
-- 2010/01/21 M.Miyagawa DEL End
-- 2010/01/21 M.Miyagawa ADD Start 本番障害#601対応
      AND    ximv.item_id             = hs.item_id
      AND    ximv.item_id             = sk.item_id(+)
      AND    ximv.item_id             = hk.item_id(+)
-- 2010/01/21 M.Miyagawa ADD End
      ';
-- 2009/07/13 H.Itou Add Start 本番障害#1525 PT対応
    -- 入力Ｐ[管轄拠点]に入力なしの場合、顧客情報を結合条件を追加
    IF (gr_param.base IS NULL) THEN
      lv_sql := lv_sql || '
-- 2009/07/13 H.Itou Add Start 本番障害#1525 PT対応
      AND    xcav.account_number      = mfds.attribute3          -- 拠点
-- 2009/07/13 H.Itou Add End
      ';
    END IF;
-- 2009/07/13 H.Itou Add End
    lv_sql := lv_sql || '
      AND    mfds.attribute1          = ''' || gv_h_plan || '''  -- 引取計画 01
-- 2009/07/13 H.Itou Mod Start 本番障害#1525 PT対応
--      AND    TO_CHAR(mfd.forecast_date,''YYYYMM'') = :yyyymm     -- 入力Ｐ[対象年月]
      AND    mfd.forecast_date  BETWEEN  TO_DATE(:yyyymm,''YYYYMM'')           -- 入力Ｐ[対象年月]
                                AND      LAST_DAY(TO_DATE(:yyyymm,''YYYYMM'')) -- 入力Ｐ[対象年月]
-- 2009/07/13 H.Itou Mod End
-- 2010/01/21 M.Miyagawa ADD Start 本番障害#601対応
   -- 本社商品区分が1で、商品区分もしくは品目区分に値のないとき
   -- OR  商品区分が1で、品目区分に値がないとき
      AND  (
            (
               ((sk.prod_class_code    IS NULL) 
             OR (hk.item_class_code    IS NULL))
             AND hs.prod_class_h_code   = ''' || gv_1 || '''
            )
      OR    (
                 hk.item_class_code    IS NULL 
             AND sk.prod_class_code     = ''' || gv_1 || '''
            )
           )
-- 2010/01/21 M.Miyagawa ADD End
   ';
--
    IF (gr_param.base IS NOT NULL) THEN -- 入力Ｐ[管轄拠点]に入力ありの場合、条件に追加
      lv_sql := lv_sql || '
      AND    mfds.attribute3          = :base                    -- 入力Ｐ[管轄拠点]
      ';
--
    ELSE
      lv_sql := lv_sql || '
-- 2009/07/13 H.Itou Add Start 本番障害#1525
      AND    xcav.customer_class_code = ''' || gv_1 || '''       -- 顧客区分
      AND    xcav.order_auto_code     = ''' || gv_1 || '''       -- 出荷依頼自動作成区分
-- 2009/07/13 H.Itou Add End
      AND    :base                   IS NULL                     -- 入力Ｐ[管轄拠点]の条件なし
      ';
    END IF;
--
    lv_sql := lv_sql || '
      GROUP BY
            ximv.item_no
-- 2009/07/13 H.Itou Del Start 本番障害#1525 PT対応
--           ,xicv.item_class_code
--           ,xicv.prod_class_code
-- 2009/07/13 H.Itou Del End
     ';
--
    FND_FILE.PUT_LINE(FND_FILE.LOG, '*** (A-15) SQL ***');
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_sql);
    -- ======================================
    -- カーソルOPEN
    -- ======================================
    OPEN  cur_item_data FOR lv_sql
    USING gr_param.yyyymm
-- 2009/07/13 H.Itou Add Start 本番障害#1525
         ,gr_param.yyyymm
-- 2009/07/13 H.Itou Add End
         ,gr_param.base
    ;
--
    -- ======================================
    -- カーソルFETCH
    -- ======================================
    FETCH cur_item_data BULK COLLECT INTO lr_item_data;
--
    -- ======================================
    -- カーソルCLOSE
    -- ======================================
    CLOSE cur_item_data;
--
    -- ======================================
    -- 対象品目データLOOP(全件チェックを行う)
    -- ======================================
    <<item_loop>>
    FOR ln_loop_cnt IN 1..lr_item_data.COUNT LOOP
      -- 商品区分か品目区分が設定されていない場合、エラー
-- 2009/07/13 H.Itou Del Start 本番障害#1525 PT対応
--      IF ( ( lr_item_data(ln_loop_cnt).item_class_code IS NULL )
--        OR ( lr_item_data(ln_loop_cnt).prod_class_code IS NULL ) ) THEN
-- 2009/07/13 H.Itou Del End
        -- メッセージ取得
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       gv_application
                      ,gv_err_item
                      ,gv_tkn_item_no
                      ,lr_item_data(ln_loop_cnt).item_code -- 品目コード
                     );
--
        -- メッセージ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
--
        -- エラー終了
        ov_retcode := gv_status_error;
        ov_errbuf  := '商品区分か品目区分が設定されていない品目があります。出力の表示を参照して下さい。';
-- 2009/07/13 H.Itou Del Start 本番障害#1525 PT対応
--      END IF;
-- 2009/07/13 H.Itou Del End
    END LOOP item_loop;
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_no_item_category_chk;
-- 2009/07/08 H.itou Add End
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_yyyymm   IN   VARCHAR2     --  01.対象年月
     ,iv_base     IN   VARCHAR2     --  02.管轄拠点
     ,ov_errbuf   OUT  VARCHAR2     --  エラー・メッセージ           --# 固定 #
     ,ov_retcode  OUT  VARCHAR2     --  リターン・コード             --# 固定 #
     ,ov_errmsg   OUT  VARCHAR2     --  ユーザー・エラー・メッセージ --# 固定 #
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
    ln_plan_cnt NUMBER;
-- 2008/11/19 H.Itou Add Start 統合テスト指摘683
    lv_header_create_flag  VARCHAR2(1);  -- ヘッダ作成フラグ
-- 2008/11/19 H.Itou Add End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- 初期処理
    -- =====================================================
    -- -----------------------------------------------------
    -- パラメータ格納
    -- -----------------------------------------------------
    gr_param.yyyymm  := iv_yyyymm;    -- 対象年月
    gr_param.base    := iv_base;      -- 管轄拠点
--
    -- 開始時のシステム現在日付を代入
    gd_sysdate       := TRUNC( SYSDATE );
--
    -- グローバル変数の初期化
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
    gn_warn_cnt      := 0;
--
    -- 共通エラーメッセージ 終了ST初期化
    gv_err_sts       := gv_status_normal;
--
-- 2009/07/08 H.Itou Add Start 本番障害#1525
    -- =====================================================
    --  品目カテゴリ設定チェック (A-15)
    -- =====================================================
    pro_no_item_category_chk
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
-- 2009/07/08 H.Itou Add End
    -- =====================================================
    --  関連データ取得 (A-1)
    -- =====================================================
    pro_get_cus_option
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  入力パラメータチェック    (A-2)
    -- =====================================================
    pro_param_chk
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  引取計画情報抽出  (A-3)
    -- =====================================================
    pro_get_to_plan
      (
        ot_to_plan        => gt_to_plan         -- 取得レコード群
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 2008/07/09 Add ↓
    IF (gt_to_plan.COUNT = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWSH',
                                            'APP-XXWSH-10002');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      ov_retcode := gv_status_warn;
      RETURN;
    END IF;
    -- 2008/07/09 Add ↑
--
    -- 拠点/出荷元/着荷予定日/重量容積区分の変数初期化
    gv_ktn      := NULL;
    gv_ship_fr  := NULL;
    gv_for_date := NULL;
    gv_wei_kbn  := NULL;
--
    <<headers_data_loop>>
    FOR i IN 1..gt_to_plan.COUNT LOOP
      -- LOOPカウント用変数へカウント数挿入
      gn_i := i;
--
      -- エラー確認用フラグ初期化
      gv_err_flg := gv_0;
--
      -- 最終レコード時、
      -- または初回レコード以外で、拠点/出荷元/着荷予定日/重量容積区分のうちどれかが異なった場合
      IF (
           (gn_i <> 1)
           AND
           (
             (gt_to_plan(gn_i).ktn      <> gv_ktn) OR
             (gt_to_plan(gn_i).ship_fr  <> gv_ship_fr) OR
             (gt_to_plan(gn_i).for_date <> gv_for_date) OR
             (gt_to_plan(gn_i).wei_kbn  <> gv_wei_kbn)
           )
         )
      THEN
--
-- 2008/11/19 H.Itou Add Start 統合テスト指摘683
        -- ヘッダにエラーがある場合、受注ヘッダアドオンレコード生成は行わない。
        IF (lv_header_create_flag = gv_0) THEN
-- 2008/11/19 H.Itou Add End
          ln_plan_cnt := gn_i - 1;
          -- =====================================================
          -- 受注ヘッダアドオンレコード生成 (A-11)
          -- =====================================================
          pro_headers_create
            (
              in_plan_cnt       => ln_plan_cnt        -- 対象としているForecastの件数
             ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
-- 2008/10/09 H.Itou Add Start A-11内で発生したエラーの初期化を行う。
          -- エラー確認用フラグ初期化
          gv_err_flg := gv_0;
-- 2008/10/09 H.Itou Add End
-- 2008/11/19 H.Itou Add Start 統合テスト指摘683
        END IF;
-- 2008/11/19 H.Itou Add End
--
      END IF;
--
      -- 初回レコード、または拠点/出荷元/着荷予定日/重量容積区分のうちどれかが異なった場合、実行
      IF  (
            (gn_i = 1)
            OR
            (
              (gt_to_plan(i).ktn      <> gv_ktn) OR
              (gt_to_plan(i).ship_fr  <> gv_ship_fr) OR
              (gt_to_plan(i).for_date <> gv_for_date) OR
              (gt_to_plan(i).wei_kbn  <> gv_wei_kbn)
            )
          )
      THEN
--
-- 2008/11/19 H.Itou Add Start 統合テスト指摘683
        lv_header_create_flag := gv_0;   -- ヘッダ作成フラグ ON
-- 2008/11/19 H.Itou Add End
-- 2009/01/30 H.Itou Add Start 本番障害#994対応
        -- 初回レコード時、｢拠点｣｢出荷元｣｢着荷予定日｣｢重量容積区分｣のうち、１つでも異なる場合
        -- 明細番号は[1]セット
        gn_line_number := 1;
-- 2009/01/30 H.Itou Add End
        ---------------------------------------------
        -- 受注ヘッダアドオンID シーケンス取得     --
        ---------------------------------------------
        SELECT xxwsh_order_headers_all_s1.NEXTVAL
        INTO   gn_headers_seq
        FROM   dual;
--
        ---------------------------------------------
        -- 共通関数「採番関数」にて、依頼No 採番   --
        ---------------------------------------------
        xxcmn_common_pkg.get_seq_no( 
                                     gv_6              -- 採番番号区分  in 依頼No '6'
                                    ,gv_req_no         -- 採番したNo
                                    ,lv_errbuf         -- エラー・メッセージ
                                    ,lv_retcode        -- リターン・コード
                                    ,lv_errmsg         -- ユーザー・エラー・メッセージ
                                   );
--
        -- 出荷依頼作成件数(依頼Ｎｏ単位)カウント
        gn_req_cnt := gn_req_cnt + 1;
--
        -- リターンコードがエラーの場合
        IF (lv_retcode = 1) THEN
--
          -- エラーリスト作成
          pro_err_list_make
            (
              iv_kind         => gv_tkn_msg_err              --  in 種別  'エラー'
             ,iv_dec          => gv_tkn_msg_hfn              --  in 確定  '-'
             ,iv_req_no       => gv_req_no                   --  in 依頼No
             ,iv_kyoten       => gt_to_plan(i).ktn           --  in 管轄拠点
             ,iv_item         => gt_to_plan(i).item_no       --  in 品目
             ,in_qty          => gt_to_plan(i).amount        --  in 数量
             ,iv_ship_date    => gv_tkn_msg_hfn              --  in 出庫日
             ,iv_arrival_date => TO_CHAR(gt_to_plan(gn_i).for_date,'YYYY/MM/DD')
                                                             --  in 着日
             ,iv_err_msg      => gv_tkn_msg_22 || lv_errmsg  --  in エラーメッセージ
             ,iv_err_clm      => gv_tkn_msg_hfn              --  in エラー項目   '-'
             ,ov_errbuf       => lv_errbuf                   -- out エラー・メッセージ
             ,ov_retcode      => lv_retcode                  -- out リターン・コード
             ,ov_errmsg       => lv_errmsg                   -- out ユーザー・エラー・メッセージ
            );
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- =====================================================
      -- 出荷予定日/最大配送区分算出 (A-4)
      -- =====================================================
      pro_ship_max_kbn
        (
          ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- 2008/11/19 H.Itou Add Start 統合テスト指摘683
      IF (gv_err_flg = gv_1) THEN
        -- ヘッダにエラーがあるので、受注ヘッダアドオンレコード生成は行わない。
        lv_header_create_flag := gv_1;  -- ヘッダ作成フラグ OFF
      END IF;
-- 2008/11/19 H.Itou Add End
      -- エラー確認用フラグ (A-4にてエラーの場合は、下記処理実施しない)
      IF (gv_err_flg <> gv_1) THEN
        ---------------------------------------------
        -- 受注明細アドオンID シーケンス取得       --
        ---------------------------------------------
        SELECT xxwsh_order_lines_all_s1.NEXTVAL
        INTO   gn_lines_seq
        FROM   dual;
--
        -- =====================================================
        -- 明細項目チェック (A-5)
        -- =====================================================
        pro_lines_chk
          (
            ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
           ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =====================================================
        -- 物流構成アドオンマスタ存在チェック (A-6)
        -- =====================================================
        pro_xsr_chk
          (
            ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
           ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =====================================================
        -- 合計重量/合計容積算出 (A-7)
        -- =====================================================
        pro_total_we_ca
          (
            ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
           ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- エラー確認用フラグ (A-7にてエラーの場合は、下記処理実施しない)
        IF (gv_err_flg <> gv_2) THEN
          -- =====================================================
          -- 出荷可否チェック (A-8)
          -- =====================================================
          pro_ship_y_n_chk
            (
              ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
             ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
             ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- =====================================================
        -- 受注明細アドオンレコード生成 (A-9)
        -- =====================================================
        pro_lines_create
          (
            ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
           ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- エラー確認用フラグ初期化
        IF (gv_err_flg = gv_2) THEN
          gv_err_flg := gv_0;
        END IF;
      END IF;
-- 2008/10/09 H.Itou Add Start A-9から移動(A-9の処理が最後までいかない場合があるため)
      -- テーブルカウント
      gn_cut := gn_cut + 1;
      gt_err_msg(gn_cut).err_msg  := NULL;
      gt_to_plan(gn_i).dup_item_msg_seq := gn_cut; -- 品目重複メッセージ格納SEQ
--
      -- テーブルカウント
      gn_cut := gn_cut + 1;
      gt_err_msg(gn_cut).err_msg  := NULL;
      gt_to_plan(gn_i).we_loading_msg_seq := gn_cut; -- 積載効率(重量)メッセージ格納SEQ
--
      -- テーブルカウント
      gn_cut := gn_cut + 1;
      gt_err_msg(gn_cut).err_msg  := NULL;
      gt_to_plan(gn_i).ca_loading_msg_seq := gn_cut; -- 積載効率(容積)メッセージ格納SEQ
-- 2008/10/09 H.Itou Add End
--
      -- 拠点/出荷元/着荷予定日/重量容積区分判定用項目更新
      gv_ktn      := gt_to_plan(i).ktn;          -- 拠点
      gv_ship_fr  := gt_to_plan(i).ship_fr;      -- 出荷元
      gv_for_date := gt_to_plan(i).for_date;     -- 着荷予定日
      gv_wei_kbn  := gt_to_plan(i).wei_kbn;      -- 重量容積区分
--
      -- 対象引取計画件数(品目単位)カウント
      gn_item_cnt := gn_item_cnt + 1;
--
    END LOOP headers_data_loop;
--
    IF (gt_to_plan.COUNT <> 0) THEN
-- 2008/11/19 H.Itou Add Start 統合テスト指摘683
      -- ヘッダにエラーがある場合、受注ヘッダアドオンレコード生成は行わない。
      IF (lv_header_create_flag = gv_0) THEN
-- 2008/11/19 H.Itou Add End
        -- =====================================================
        -- 受注ヘッダアドオンレコード生成 (A-11)
        -- =====================================================
        pro_headers_create
          (
             in_plan_cnt       => (gn_i)            -- 対象としているForecastの件数
            ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
            ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
            ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
-- 2008/11/19 H.Itou Add Start 統合テスト指摘683
      END IF;
-- 2008/11/19 H.Itou Add End
--
      -- =====================================================
      -- 出荷依頼登録処理 (A-12)
      -- =====================================================
      pro_ship_order
        (
          ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ステータスを挿入
    IF (gt_to_plan.COUNT = 0) THEN
      ov_retcode := gv_status_normal;
    ELSIF (gv_err_sts = gv_status_warn)
    OR    (gv_err_sts = gv_status_error)
    THEN
      ov_retcode := gv_err_sts;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
  PROCEDURE main
    (
      errbuf     OUT    VARCHAR2     --  エラー・メッセージ  --# 固定 #
     ,retcode    OUT    VARCHAR2     --  リターン・コード    --# 固定 #
     ,iv_yyyymm  IN     VARCHAR2     --  01.対象年月
     ,iv_base    IN     VARCHAR2     --  02.管轄拠点
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- 固定出力
    -- ======================
    --実行ユーザ名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain
      (
        iv_yyyymm   => iv_yyyymm   -- 01.対象年月
       ,iv_base     => iv_base     -- 02.管轄拠点
       ,ov_errbuf   => lv_errbuf   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode  => lv_retcode  -- リターン・コード             --# 固定 #
       ,ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
    -----------------------------------------------
    -- 入力パラメータ出力                        --
    -----------------------------------------------
    -- 入力パラメータ「対象年月」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-11007','YYMM',gr_param.yyyymm);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「管轄拠点」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-11008','KYOTEN',gr_param.base);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- エラーリスト出力
    IF (gt_err_msg.COUNT > 0) THEN
      -- 項目名出力
      gv_err_report := gv_name_kind      || CHR(9) || gv_name_dec      || CHR(9) ||
                       gv_name_req_no    || CHR(9) || gv_name_kyoten   || CHR(9) ||
                       gv_name_item_a    || CHR(9) || gv_name_qty      || CHR(9) ||
                       gv_name_ship_date || CHR(9) || gv_name_arr_date || CHR(9) ||
                       gv_name_err_msg   || CHR(9) || gv_name_err_clm;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_err_report);
--
      -- 項目区切り線出力
      gv_err_report := gv_line || gv_line || gv_line || gv_line || gv_line || gv_line || gv_line;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_err_report);
--
      -- エラーリスト内容出力
      <<err_report_loop>>
      FOR i IN 1..gt_err_msg.COUNT LOOP
-- 2008/08/18 H.Itou Add Start
        -- 積載効率エラーメッセージ用ダミーエラーメッセージ（NULL）は出力しない
        IF (gt_err_msg(i).err_msg IS NOT NULL) THEN
-- 2008/08/18 H.Itou Add End
-- 2008/08/18 H.Itou Mod Start
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gt_err_msg(i).err_msg);
-- 2008/08/18 H.Itou Mod End
-- 2008/08/18 H.Itou Add Start
        END IF;
-- 2008/08/18 H.Itou Add End
      END LOOP err_report_loop;
--
      --区切り文字列出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    END IF;
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      ELSIF (lv_errbuf IS NULL) THEN
        --ユーザー・エラー・メッセージのコピー
        lv_errbuf := lv_errmsg;
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      --区切り文字列出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --処理件数出力(対象引取計画件数(品目単位))
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-11009','CNT',TO_CHAR(gn_item_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --処理件数出力(出荷依頼作成件数(依頼Ｎｏ単位))
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-11010','CNT',TO_CHAR(gn_req_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --処理件数出力(出荷依頼作成件数(依頼明細単位))
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-11011','CNT',TO_CHAR(gn_line_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxwsh400001c;
/
