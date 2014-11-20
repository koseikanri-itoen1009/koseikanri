CREATE OR REPLACE PACKAGE BODY XXCOS003A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS003A04C(body)
 * Description      : ベンダ納品実績IF出力
 * MD.050           : ベンダ納品実績IF出力 MD050_COS_003_A04
 * Version          : 1.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                       A-1．初期処理
-- 2011/09/27 DEL Ver.1.10 Start
-- *  proc_threshold             A-4． 閾値抽出
-- 2011/09/27 DEL Ver.1.10 End
-- 2011/03/31 Ver.1.9 S.Ochiai DEL Start
-- *  proc_new_item_select       A-7．コラムの最新品目抽出
-- 2011/03/31 Ver.1.9 S.Ochiai DEL End
 *  proc_month_qty             A-9．月販数、基準在庫数導出
 *  proc_sales_days           A-10．販売日数導出
 *  proc_hot_warn             A-11．ホット警告残数導出
 *  proc_deli_l_file_out      A-13．納品実績情報明細ファイル出力
 *  proc_deli_h_file_out      A-15．納品実績情報ヘッダファイル出力
-- 2011/09/27 MOD Ver.1.10 Start
-- *  proc_main_loop             A-2．顧客マスタデータ抽出
 *  proc_main_loop             A-17．ベンダ納品実績データ抽出
-- 2011/09/27 MOD Ver.1.10 End
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/07   1.0    K.Okaguchi       新規作成
 *  2009/02/24   1.1    T.Nakamura       [障害COS_130] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/04/15   1.2    N.Maeda          [ST障害No.T1_0067対応] ファイル出力時のCHAR型VARCHAR型以外への｢"｣付加の削除
 *  2009/04/16   1.3    K.Kiriu          [ST障害No.T1_0075対応] 桁数超過対応
 *                                       [ST障害No.T1_0079対応] ホット警告残数の計算ロジック修正
 *  2009/04/22   1.4    N.Maeda          [ST障害No.T1_0754対応]ファイル出力時の｢"｣付加修正
 *  2009/07/15   1.5    M.Sano           [SCS障害No.0000652対応]明細データのファイル出力方法変更
 *                                       [SCS障害No.0000653対応]ホット警告残数出力不正対応
 *                                       [SCS障害No.0000690対応]出力関連変数初期化不良対応
 *  2009/07/24   1.6    M.Sano           [SCS障害No.0000691対応]コラム変更、H/C区分変更時のホット警告残数変更
 *  2009/08/20   1.7    M.Sano           [SCS障害No.0000867対応]PT考慮
 *  2009/10/14   1.8    K.Satomura       [SCS障害No.0001525対応]補充率桁あふれ対応
 *  2011/04/14   1.9    S.Ochiai         [障害No.E_本稼動_00184対応]同一VD、同一コラムに対する、複数商品の納品対応
 *  2011/09/27   1.10   Y.Horikawa       [障害No.E_本稼動_00184対応]同一VD、同一コラムに対する、複数商品の納品対応（再）
 *  2011/10/24   1.11   Y.Horikawa       [障害No.E_本稼動_00184対応]同一VD、同一コラムに対する、複数商品の納品対応（再）（PT追加対応）
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
  gn_target_cnt    NUMBER DEFAULT 0 ;                    -- 対象件数
  gn_normal_cnt    NUMBER DEFAULT 0 ;                    -- 正常件数
  gn_error_cnt     NUMBER DEFAULT 0 ;                    -- エラー件数
  gn_warn_cnt      NUMBER DEFAULT 0 ;                    -- スキップ件数
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
-- 2011/09/27 DEL Ver.1.10 Start
--  column_no_data_expt       EXCEPTION;     --ベンダコラムマスタにデータが存在しない場合
--  line_no_data_expt         EXCEPTION;     --ベンダ納品実績情報テーブルにデータが存在しない場合
-- 2011/09/27 DEL Ver.1.10 End
  file_open_expt            EXCEPTION;     --ファイルオープンエラー
-- 2009/07/24 Add Ver.1.6 Start
  column_change_data_expt   EXCEPTION;     --コラム変更が実施された場合
  hctype_change_data_expt   EXCEPTION;     --H/C区分変更が実施された場合
-- 2009/07/24 Add Ver.1.6 End
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100):= 'XXCOS003A04C'; -- パッケージ名
  cv_application          CONSTANT VARCHAR2(5)  := 'XXCOS';        -- アプリケーション名(販売)
  cv_application_coi      CONSTANT VARCHAR2(5)  := 'XXCOI';        -- アプリケーション名(在庫)
  cv_appl_short_name      CONSTANT VARCHAR2(10) := 'XXCCP';        -- アドオン：共通・IF領域
  cv_tkn_table_name       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_data         CONSTANT VARCHAR2(20) := 'KEY_DATA';
  cv_flag_off             CONSTANT VARCHAR2(1)  := 'N';
  cv_flag_on              CONSTANT VARCHAR2(1)  := 'Y';
  cv_tkn_filename         CONSTANT VARCHAR2(20) := 'FILE_NAME';
  cv_delimit              CONSTANT VARCHAR2(1)  := ',';            -- 区切り文字
  cv_quot                 CONSTANT VARCHAR2(1)  := '"';            -- コーテーション
  cv_hot_type             CONSTANT VARCHAR2(1)  := '3';            -- ホットコールド区分がＨＯＴ
  cv_warehouse            CONSTANT VARCHAR2(20) := '1';
-- 2011/04/14 Ver.1.9 S.Ochiai ADD Start
  cv_blank_c              CONSTANT VARCHAR2(7) := 'BLANK_C';       -- VDコラムマスタ:品目コードNULL
-- 2011/04/14 Ver.1.9 S.Ochiai ADD End
-- 2011/09/27 ADD Ver.1.10 Start
  cv_tkn_error_message    CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
-- 2011/09/27 ADD Ver.1.10 End

-- 2011/09/27 DEL Ver.1.10 Start
--  cn_lock_error_code      CONSTANT NUMBER       := -54;
-- 2011/09/27 DEL Ver.1.10 End
  cv_msg_no_data_tran     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003';    --対象データ無しエラー
  cv_msg_pro              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';    --プロファイル取得エラー
  cv_msg_file_open        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00009';    --ファイルオープンエラーメッセージ
  cv_msg_select_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013';    -- データ抽出エラーメッセージ
  cv_msg_process_dt_err   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014';    -- 業務日付取得エラー
  cv_no_parameter         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';    -- パラメータなし

  cv_msg_filename         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00044';    --ファイル名（タイトル）

  cv_tkn_dir_path         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10662';    -- HHTアウトバウンド用ディレクトリパス
  cv_tkn_vend_h_filename  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10801';    -- ベンダ納品実績ヘッダファイル名
  cv_tkn_vend_l_filename  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10802';    -- ベンダ納品実績明細ファイル名
-- 2011/04/14 Ver.1.9 S.Ochiai ADD Start
  cv_tkn_orga_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10048';    -- 在庫組織コード
  cv_msg_orga             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10024';    -- 在庫組織ID取得エラー
-- 2011/04/14 Ver.1.9 S.Ochiai ADD End
-- 2011/09/27 ADD Ver.1.10 Start
  cv_tkn_min_date         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00120';    -- XXCOS:MIN日付
  cv_msg_continue         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10810';    -- 処理継続（エラーあり）メッセージ
-- 2011/09/27 ADD Ver.1.10 End

  cv_tkn_cust_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10853';    -- 顧客コード
  cv_tkn_item_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10803';    -- 品目コード
  cv_tkn_dlv_date         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10752';    -- 納品日
  cv_tkn_vd_deliv_l       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10753';    -- ベンダ納品実績情報明細テーブル
  cv_tkn_column_no        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10754';    -- コラムNo
  cv_tkn_warehouse_cl     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10804';    -- 保管場所区分
  cv_tkn_base_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10805';    -- 拠点コード
  cv_tkn_main_warehouse_c CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10806';    -- メイン倉庫区分
  cv_tkn_mtl_second_inv   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10807';    -- 保管場所マスタ
  cv_tkn_cust_account_id  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10808';    -- 顧客ID
  cv_tkn_vd_column_mst    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10809';    -- べンダコラムマスタ
-- 2009/10/14 Ver.1.8 Add Start
  cv_msg_rep_rate_over    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13908';    -- 補充率置換メッセージ
  cv_msg_threshold_null   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13909';    -- 閾値未設定メッセージ
-- 2009/10/14 Ver.1.8 Add End

  cv_tkn_profile          CONSTANT VARCHAR2(20) := 'PROFILE';             -- プロファイル名
  cv_tkn_file_name        CONSTANT VARCHAR2(20) := 'FILE_NAME';           -- ファイル名
-- 2009/10/14 Ver.1.8 Add Start
  cv_tkn_max_value        CONSTANT VARCHAR2(20) := 'MAX_VALUE';           -- 最大値
  cv_tkn_customer_code    CONSTANT VARCHAR2(20) := 'CUSTOMER_CODE';       -- 顧客コード
  cv_tkn_col_no           CONSTANT VARCHAR2(20) := 'COLUMN_NO';           -- コラムNo
-- 2009/10/14 Ver.1.8 Add End

  cv_prf_dir_path         CONSTANT VARCHAR2(50) := 'XXCOS1_OUTBOUND_HHT_DIR';      -- HHTアウトバウンド用ディレクトリパス
  cv_prf_vend_h_filename  CONSTANT VARCHAR2(50) := 'XXCOS1_VENDER_DELI_H_FILE_NAME';    -- ベンダ納品実績ヘッダファイル
  cv_prf_vend_l_filename  CONSTANT VARCHAR2(50) := 'XXCOS1_VENDER_DELI_L_FILE_NAME';    -- ベンダ納品実績明細ファイル

  cv_lookup_type_gyotai   CONSTANT VARCHAR2(30) := 'XXCOS1_GYOTAI_SHO_MST_003_A03'; -- 参照タイプ　業態小分類
  cv_organization_code    CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';      -- 在庫組織コード
-- 2009/08/20 Add Ver.1.7 Start
--
  ct_lang                 CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');  -- 言語コード
-- 2009/08/20 Add Ver.1.7 End
-- 2009/10/14 Ver.1.8 Add Start
  cn_max_length_rep_rate  CONSTANT NUMBER := 3;   -- 補充率の有効最大桁数
  cn_max_replacement_rate CONSTANT NUMBER := 999; -- 補充率が3桁を超えた場合の固定値
-- 2009/10/14 Ver.1.8 Add End
--
-- 2011/09/27 Add Ver.1.10 Start
  cv_min_date            CONSTANT VARCHAR2(30) := 'XXCOS1_MIN_DATE';
  cv_cust_stat_approved  CONSTANT VARCHAR2(30) := '30';
  cv_cust_stat_customer  CONSTANT VARCHAR2(30) := '40';
  cv_cust_stat_pause     CONSTANT VARCHAR2(30) := '50';
  cv_last_time           CONSTANT VARCHAR2(10) := '23:59:59';
-- 2011/09/27 Add Ver.1.10 End
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_key_info                 fnd_new_messages.message_text%TYPE   ; --メッセージ出力用キー情報
  gv_msg_tkn_cust_code        fnd_new_messages.message_text%TYPE   ; --顧客コード
  gv_msg_tkn_item_code        fnd_new_messages.message_text%TYPE   ; --品目コード
  gv_msg_tkn_dlv_date         fnd_new_messages.message_text%TYPE   ; --納品日
  gv_msg_tkn_vd_deliv_l       fnd_new_messages.message_text%TYPE   ; --ベンダ納品実績情報明細テーブル
  gv_msg_tkn_column_no        fnd_new_messages.message_text%TYPE   ; --コラムNo
  gv_msg_tkn_warehouse_cl     fnd_new_messages.message_text%TYPE   ; --保管場所区分
  gv_msg_tkn_base_code        fnd_new_messages.message_text%TYPE   ; --拠点コード
  gv_msg_tkn_main_warehouse_c fnd_new_messages.message_text%TYPE   ; --メイン倉庫区分
  gv_msg_tkn_mtl_second_inv   fnd_new_messages.message_text%TYPE   ; --保管場所マスタ
  gv_msg_tkn_cust_account_id  fnd_new_messages.message_text%TYPE   ; --顧客ID
  gv_msg_tkn_vd_column_mst    fnd_new_messages.message_text%TYPE   ; --べンダコラムマスタ
  gv_msg_no_data_tran         fnd_new_messages.message_text%TYPE   ; --対象データ無しエラー


  gv_msg_tkn_dir_path         fnd_new_messages.message_text%TYPE   ;--HHTアウトバウンド用ディレクトリパス
  gv_msg_tkn_vend_h_filename  fnd_new_messages.message_text%TYPE   ;--ベンダ納品実績ヘッダファイル
  gv_msg_tkn_vend_l_filename  fnd_new_messages.message_text%TYPE   ;--ベンダ納品実績明細ファイル
-- 2011/04/14 Ver.1.9 S.Ochiai ADD Start
  gv_msg_tkn_orga_code        fnd_new_messages.message_text%TYPE   ;--在庫組織コード
-- 2011/04/14 Ver.1.9 S.Ochiai ADD End

-- 2011/09/27 DEL Ver.1.10 Start
--  gv_customer_number          xxcos_unit_price_mst_work.customer_number%TYPE;
--  gv_tkn_lock_table           fnd_new_messages.message_text%TYPE   ;

--  gv_item_code                xxcos_vd_deliv_lines.item_code%TYPE;        --品目コード
--  gv_hot_cold_type            xxcos_vd_deliv_lines.hot_cold_type%TYPE;    --H/C
--  gt_dlv_date_time            xxcos_vd_deliv_lines.dlv_date_time%TYPE;    --納品日時
--  gv_column_no                xxcoi_mst_vd_column.column_no%TYPE;
--  gv_hot_stock_days           mtl_secondary_inventories.attribute10%TYPE; --ホット在庫日数
-- 2011/09/27 DEL Ver.1.10 END
  gd_standard_date            DATE;                                       --基準日
  --ヘッダファイル設定変数
  gn_sales_qty_sum_1          NUMBER DEFAULT 0;                           --売上数1
  gn_sales_qty_sum_2          NUMBER DEFAULT 0;                           --売上数2
  gn_sales_qty_sum_3          NUMBER DEFAULT 0;                           --売上数3
  gd_dlv_date_1               DATE;                                       --1件目の納品日
  gd_dlv_date_2               DATE;                                       --2件目の納品日
  gd_dlv_date_3               DATE;                                       --3件目の納品日
  gn_total_amount_1           NUMBER;                                     --1件目の合計金額
  gn_total_amount_2           NUMBER;                                     --2件目の合計金額
  gn_total_amount_3           NUMBER;                                     --3件目の合計金額
  gv_visit_time               xxcos_vd_deliv_headers.visit_time%TYPE;     --前回訪問時刻
  gn_last_visit_days          NUMBER;                                     --前回訪問日数

  --明細ファイル設定変数
  gn_monthly_sales            NUMBER;                                     --月販数
  gn_sales_days               NUMBER;                                     --販売日数
  gn_inventory_quantity_sum   NUMBER;                                     --基準在庫数（合計）
  gn_hot_warn_qty             NUMBER;                                     --ホット警告残数
-- 2011/09/27 DEL Ver.1.10 Start
--  gn_sales_qty_1              NUMBER;                                     --1件目の売上数
--  gn_sales_qty_2              NUMBER;                                     --2件目の売上数
--  gn_sales_qty_3              NUMBER;                                     --3件目の売上数
-- 2011/09/27 DEL Ver.1.10 End
  gn_replacement_rate         NUMBER;                                     --補充率
-- 2011/04/14 Ver.1.9 S.Ochiai ADD Start
  gv_orga_code                VARCHAR(100);                               --在庫組織コード格納用
  gn_orga_id                  NUMBER;                                     --在庫組織ID格納用
-- 2011/04/14 Ver.1.9 S.Ochiai ADD End

  --ファイル出力変数
  gv_deli_h_file_data         VARCHAR2(1000) ;                            --ベンダ納品実績ヘッダファイル出力用
  gv_deli_l_file_data         VARCHAR2(1000) ;                            --ベンダ納品実績明細ファイル出力用
-- 2011/09/27 ADD Ver.1.10 Start
  gd_min_date                 DATE;    -- XXCOS:MIN日付
  gd_vd_change_dlv_date_time  DATE;    -- 納品日時（ベンダ変更前）
-- 2011/09/27 ADD Ver.1.10 End
-- 2011/09/27 DEL Ver.1.10 Start
--  --件数カウンタ
--  gn_warn_tran_count          NUMBER DEFAULT 0;
--  gn_tran_count               NUMBER DEFAULT 0;
--  gn_unit_price               NUMBER;
--  gn_skip_cnt                 NUMBER DEFAULT 0;                      -- 対象外件数
--  gn_main_loop_cnt            NUMBER DEFAULT 0;
-- 2011/09/27 DEL Ver.1.10 END

-- 2009/07/15 Add Ver.1.5 Start
  gn_deli_l_cnt               NUMBER DEFAULT 0;                      -- 出力対象の納品実績情報明細用件数
-- 2009/07/15 Add Ver.1.5 End

--
--カーソル
-- 2011/09/27 Add Ver.1.10 Start
  CURSOR main_cur
  IS
    SELECT b.customer_number            account_number,      -- 顧客コード
           b.cust_account_id            cust_account_id,     -- 顧客ID
           b.dlv_date                   dlv_date,            -- 納品日
           b.visit_time                 visit_time,          -- 訪問時刻
           b.total_amount               total_amount,        -- 合計金額
           b.attribute10                hot_stock_days,      -- ホット在庫（閾値）
           b.column_no                  column_no,           -- コラムNo
           b.segment1                   item_code,           -- 品目コード
           b.inventory_quantity         inventory_quantity,  -- ベンダ基準在庫数量
           b.hot_cold                   hot_cold,            -- Hot/Cold 区分
           SUM(NVL(xvdl.sales_qty, 0))  sales_qty_of_day,    -- 合計数量（売上数量）
           b.base_code                  base_code            -- 拠点コード
    FROM (
-- 2011/10/24 Mod Ver.1.11 Start
--         SELECT a.customer_number       customer_number,
         SELECT /*+ leading(a)  index(msi xxcos_msi_n02) use_nl(a msi xmvc msib) */
                a.customer_number       customer_number,
-- 2011/10/24 Mod Ver.1.11 End
                a.cust_account_id       cust_account_id,
                a.dlv_date              dlv_date,
                a.visit_time            visit_time,
                a.total_amount          total_amount,
                msi.attribute10         attribute10,
                xmvc.column_no          column_no,
                msib.segment1           segment1,
                xmvc.inventory_quantity inventory_quantity,
                xmvc.hot_cold           hot_cold,
                a.base_code             base_code
         FROM mtl_secondary_inventories msi,   -- 保管場所マスタ
              xxcoi_mst_vd_column       xmvc,  -- VDコラムマスタ
              mtl_system_items_b        msib,  -- 品目マスタ
              (
-- 2011/10/24 Mod Ver.1.11 Start
--              SELECT xvdh.customer_number customer_number,
              SELECT /*+ leading(flv) use_nl(flv xca hca hp xvdh) */
                     xvdh.customer_number customer_number,
-- 2011/10/24 Mod Ver.1.11 End
                     hca.cust_account_id  cust_account_id,
                     xvdh.base_code       base_code,
                     xvdh.dlv_date        dlv_date,
                     xvdh.visit_time      visit_time,
                     xvdh.total_amount    total_amount,
                     ROW_NUMBER() OVER(
                       PARTITION BY xvdh.customer_number
                       ORDER BY xvdh.dlv_date DESC) local_number
              FROM xxcos_vd_deliv_headers xvdh,  -- ベンダ納品実績ヘッダ
                   hz_parties             hp,    -- パーティマスタ
                   hz_cust_accounts       hca,   -- 顧客マスタ
                   xxcmm_cust_accounts    xca,   -- 顧客アドオンマスタ
                   fnd_lookup_values      flv    -- 参照タイプ（業態小分類）
              WHERE flv.lookup_type = cv_lookup_type_gyotai
              AND   flv.language = ct_lang
              AND   TRUNC(SYSDATE)  BETWEEN flv.start_date_active
                                    AND NVL(flv.end_date_active, TRUNC(SYSDATE))
              AND   flv.enabled_flag = cv_flag_on
              AND   xca.business_low_type = flv.meaning
              AND   hca.cust_account_id = xca.customer_id
              AND   hp.party_id = hca.party_id
              AND   hp.duns_number_c in (cv_cust_stat_approved, cv_cust_stat_customer, cv_cust_stat_pause)
              AND   xvdh.customer_number = hca.account_number
              AND   xvdh.total_amount > 0
              ) a
         WHERE a.local_number BETWEEN 1 AND 3
         AND   msi.attribute7 = a.base_code
         AND   msi.attribute1 = cv_warehouse
         AND   msi.attribute6 = cv_flag_on
         AND   xmvc.customer_id = a.cust_account_id
         AND   msib.inventory_item_id(+) = xmvc.item_id
-- 2011/10/24 Del Ver.1.11 Start
--         AND   msib.organization_id(+) = xmvc.organization_id
-- 2011/10/24 Del Ver.1.11 End
         AND   msib.organization_id(+) = gn_orga_id
         ) b,
         xxcos_vd_deliv_lines xvdl  -- ベンダ納品実績明細
    WHERE b.customer_number = xvdl.customer_number (+)
    AND   b.dlv_date = xvdl.dlv_date (+)
-- 2011/10/24 Mod Ver.1.11 Start
--    AND   b.column_no = xvdl.column_num (+)
    AND   TO_CHAR(b.column_no) = xvdl.column_num (+)
-- 2011/10/24 Mod Ver.1.11 End
    AND   NVL(b.segment1, cv_blank_c) = xvdl.item_code (+)
    AND   b.hot_cold = xvdl.hot_cold_type (+)
    GROUP BY b.customer_number,
             b.cust_account_id,
             b.dlv_date,
             b.visit_time,
             b.total_amount,
             b.attribute10,
             b.column_no,
             b.segment1,
             b.inventory_quantity,
             b.hot_cold,
             b.base_code
    ORDER BY b.customer_number,
             b.dlv_date DESC,
             b.column_no;

  main_rec     main_cur%ROWTYPE;
  main_rec_old main_cur%ROWTYPE;


-- 2011/09/27 Add Ver.1.10 End
-- 2011/09/27 Del Ver.1.10 Start
--  CURSOR main_cur
--  IS
---- 2009/08/20 Mod Ver.1.7 Start
----    SELECT hzca.cust_account_id   cust_account_id        --顧客ID
--    SELECT /*+ INDEX(xxca xxcmm_cust_accounts_n09) */
--           hzca.cust_account_id   cust_account_id        --顧客ID
---- 2009/08/20 Mod Ver.1.7 End
--          ,hzca.account_number    account_number         --顧客コード
--    FROM   hz_cust_accounts       hzca                   --顧客マスタ
--          ,xxcmm_cust_accounts    xxca                   --顧客追加情報
--          ,fnd_lookup_values      flvl
--    WHERE  hzca.cust_account_id   = xxca.customer_id
--    AND    xxca.business_low_type = flvl.meaning
--    AND    flvl.lookup_type       = cv_lookup_type_gyotai
---- 2009/08/20 Mod Ver.1.7 Start
----    AND    flvl.security_group_id = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
----    AND    flvl.language          = USERENV('LANG')
--    AND    flvl.language          = ct_lang
---- 2009/08/20 Mod Ver.1.7 End
--    AND    TRUNC(SYSDATE)         BETWEEN flvl.start_date_active
--                                    AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
--    AND    flvl.enabled_flag      = cv_flag_on
--    ORDER BY
--           hzca.account_number
--    ;
--
--  main_rec main_cur%ROWTYPE;
--
--  CURSOR header_cur
--  IS
--    SELECT dlv_date
--          ,visit_time
--          ,total_amount
--          ,base_code
--    FROM(
--      SELECT xvdh.dlv_date           dlv_date              --納品日
--            ,xvdh.visit_time         visit_time            --訪問時刻
--            ,xvdh.total_amount       total_amount          --合計金額
--            ,xvdh.base_code          base_code             --拠点コード
--      FROM   xxcos_vd_deliv_headers  xvdh
--      WHERE  xvdh.customer_number = main_rec.account_number
--      AND    xvdh.total_amount    > 0
--      ORDER BY
--             xvdh.dlv_date DESC
--        )
--    WHERE ROWNUM < 4
--    ;

--  header_rec  header_cur%ROWTYPE;

--  CURSOR column_cur
--  IS
--    SELECT xmvc.column_no            column_no             --コラムNo
--          ,xmvc.inventory_quantity   inventory_quantity    --基準在庫数
---- 2011/04/14 Ver.1.9 S.Ochiai ADD Start
--          ,msib.segment1             item_code             --品目コード
--          ,xmvc.hot_cold             hot_cold              --ホット/コールド区分
---- 2011/04/14 Ver.1.9 S.Ochiai ADD End
--    FROM   xxcoi_mst_vd_column       xmvc                  --ベンダコラムマスタ
---- 2011/04/14 Ver.1.9 S.Ochiai ADD Start
--          ,mtl_system_items_b        msib                  --品目マスタ
---- 2011/04/14 Ver.1.9 S.Ochiai ADD End
--    WHERE  xmvc.customer_id = main_rec.cust_account_id
---- 2011/04/14 Ver.1.9 S.Ochiai ADD Start
--    AND    msib.inventory_item_id(+) = xmvc.item_id
--    AND    msib.organization_id(+)   = gn_orga_id
---- 2011/04/14 Ver.1.9 S.Ochiai ADD End
--    ORDER BY
--           xmvc.column_no
--    ;
--
--  column_rec column_cur%ROWTYPE;
--
--  CURSOR line_cur
--  IS
--    SELECT dlv_date
--          ,sum_sales_qty
--    FROM(
--      SELECT xvdl.dlv_date        dlv_date                   --納品日
--            ,SUM(xvdl.sales_qty)  sum_sales_qty              --売上数のサマリ
--      FROM   xxcos_vd_deliv_lines xvdl                       --ベンダ納品実績情報明細テーブル
--      WHERE  xvdl.customer_number = main_rec.account_number
--      AND    xvdl.column_num      = column_rec.column_no
--      AND    xvdl.dlv_date        IN(gd_dlv_date_1,gd_dlv_date_2,gd_dlv_date_3)
---- 2011/04/14 Ver.1.9 S.Ochiai ADD Start
--      AND    xvdl.item_code       = NVL(gv_item_code, cv_blank_c)
---- 2011/04/14 Ver.1.9 S.Ochiai ADD End
--      GROUP BY xvdl.dlv_date
--      ORDER BY xvdl.dlv_date DESC
--      )
--    WHERE ROWNUM < 4
--    ;

--  line_rec line_cur%ROWTYPE;
-- 2011/09/27 Del Ver.1.10 End

-- 2009/07/15 Add Ver.1.5 Start
  -- ===============================
  -- ユーザー定義グローバルRECORD型宣言
  -- ===============================
  -- 納品実績情報明細レコード
  TYPE g_deli_line_rtype  IS RECORD
    (
      account_number                hz_cust_accounts.account_number%TYPE,  -- 顧客コード
      column_no                     xxcoi_mst_vd_column.column_no%TYPE,    -- コラムNo
      monthly_sales                 NUMBER,                                -- 月販数
      sales_days                    NUMBER,                                -- 販売日数
      inventory_quantity_sum        NUMBER,                                -- 基準在庫数
      hot_warn_qty                  NUMBER,                                -- ホット警告残数
      sales_qty_1                   NUMBER,                                -- 前回売上数
      sales_qty_2                   NUMBER,                                -- 前々回売上数
      sales_qty_3                   NUMBER,                                -- 前々前回売上数
      replacement_rate              NUMBER                                 -- 補充率
-- 2011/10/24 Add Ver.1.11 Start
    , vd_change_dlv_date_time       DATE  -- 納品日時（ベンダ変更前）
-- 2011/10/24 Add Ver.1.11 End
    );

--
  -- ===============================
  -- ユーザー定義グローバルTABLE型宣言
  -- ===============================
  -- 納品実績情報明細テーブル型
  TYPE g_deli_line_ttype  IS TABLE OF g_deli_line_rtype  INDEX BY BINARY_INTEGER;
--
-- 2009/07/15 Add Ver.1.5 End
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================

    gt_deli_h_handle       UTL_FILE.FILE_TYPE; --納品実績情報ヘッダファイルハンドル
    gt_deli_l_handle       UTL_FILE.FILE_TYPE; --納品実績情報明細ファイルハンドル
-- 2009/07/15 Add Ver.1.5 Start
    gt_deli_l_tab          g_deli_line_ttype;  --出力対象の納品実績情報明細データ
-- 2009/07/15 Add Ver.1.5 End

--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
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
    lv_dir_path                 VARCHAR2(100);                -- HHTアウトバウンド用ディレクトリパス
    lv_vend_h_filename          VARCHAR2(100);                -- ベンダ納品実績ヘッダファイル名
    lv_vend_l_filename          VARCHAR2(100);                -- ベンダ納品実績明細ファイル名
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
    gv_msg_tkn_dlv_date        := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_dlv_date
                                                           );
    gv_msg_tkn_vd_deliv_l      := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_vd_deliv_l
                                                           );
    gv_msg_tkn_column_no       := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_column_no
                                                           );
    gv_msg_tkn_warehouse_cl    := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_warehouse_cl
                                                           );
    gv_msg_tkn_base_code       := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_base_code
                                                           );
    gv_msg_tkn_main_warehouse_c := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_main_warehouse_c
                                                           );
    gv_msg_tkn_mtl_second_inv  := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_mtl_second_inv
                                                           );
    gv_msg_tkn_cust_account_id := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_cust_account_id
                                                           );
    gv_msg_tkn_vd_column_mst   := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_vd_column_mst
                                                           );
    gv_msg_tkn_vend_h_filename := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_vend_h_filename
                                                           );
    gv_msg_tkn_vend_l_filename := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_vend_l_filename
                                                           );
    gv_msg_tkn_dir_path        := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_tkn_dir_path
                                                           );
    gv_msg_no_data_tran        := xxccp_common_pkg.get_msg(iv_application   => cv_application
                                                           ,iv_name         => cv_msg_no_data_tran
                                                           );


-- 2011/09/27 ADD Ver.1.10 Start
    --==============================================================
    -- プロファイルの取得(XXCOS:MIN日付)
    --==============================================================
    gd_min_date := TO_DATE(FND_PROFILE.VALUE(cv_min_date), 'YYYY/MM/DD');
--
    -- プロファイル取得エラーの場合
    IF (gd_min_date IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , cv_tkn_min_date
                                           );
      RAISE global_api_others_expt;
    END IF;
-- 2011/09/27 ADD Ver.1.10 End
    --==============================================================
    -- プロファイルの取得(XXCOS:HHTアウトバウンド用ディレクトリパス)
    --==============================================================
    lv_dir_path := FND_PROFILE.VALUE(cv_prf_dir_path);

--
    -- プロファイル取得エラーの場合
    IF (lv_dir_path IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_dir_path
                                           );
      RAISE global_api_others_expt;
    END IF;
--

    --==============================================================
    -- プロファイルの取得(XXCOS:ベンダ納品実績ヘッダファイル名)
    --==============================================================
    lv_vend_h_filename := FND_PROFILE.VALUE(cv_prf_vend_h_filename);
--
    -- プロファイル取得エラーの場合
    IF (lv_vend_h_filename IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_vend_h_filename
                                           );
      RAISE global_api_others_expt;
    END IF;

    --==============================================================
    -- プロファイルの取得(XXCOS:ベンダ納品実績明細ファイル名)
    --==============================================================
    lv_vend_l_filename := FND_PROFILE.VALUE(cv_prf_vend_l_filename);
--
    -- プロファイル取得エラーの場合
    IF (lv_vend_l_filename IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_vend_l_filename
                                           );
      RAISE global_api_others_expt;
    END IF;

    --==============================================================
    -- ファイル名のログ出力
    --==============================================================
    --ベンダ納品実績ヘッダファイル名
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                          ,iv_name         => cv_msg_filename
                                          ,iv_token_name1  => cv_tkn_filename
                                          ,iv_token_value1 => lv_vend_h_filename
                                          );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );


    --ベンダ納品実績明細ファイル名
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                          ,iv_name         => cv_msg_filename
                                          ,iv_token_name1  => cv_tkn_filename
                                          ,iv_token_value1 => lv_vend_l_filename
                                          );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );

    --空行
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
--
    --==============================================================
    -- ベンダ納品実績ヘッダファイル　ファイルオープン
    --==============================================================
    BEGIN
      gt_deli_h_handle := UTL_FILE.FOPEN(lv_dir_path
                                  , lv_vend_h_filename
                                  , 'w');
    EXCEPTION
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_file_open
                                            , cv_tkn_file_name
                                            , lv_vend_h_filename);
        RAISE file_open_expt;
    END;

    --==============================================================
    -- ベンダ納品実績明細ファイル　ファイルオープン
    --==============================================================
    BEGIN
      gt_deli_l_handle := UTL_FILE.FOPEN(lv_dir_path
                                  , lv_vend_l_filename
                                  , 'w');
    EXCEPTION
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_file_open
                                            , cv_tkn_file_name
                                            , lv_vend_l_filename);
      RAISE file_open_expt;
    END;

    --==============================================================
    -- 基準日を取得
    --==============================================================
    gd_standard_date := xxccp_common_pkg2.get_process_date + 1;

    IF (gd_standard_date IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_process_dt_err
                                           );
      RAISE global_api_others_expt;
    END IF;
-- 2011/04/14 Ver.1.9 S.Ochiai ADD Start
    --==============================================================
    -- 在庫組織IDの取得
    --==============================================================
    --在庫組織コード取得
    gv_orga_code := FND_PROFILE.VALUE( cv_organization_code );
--
    -- プロファイル取得エラーの場合
    IF ( gv_orga_code IS NULL ) THEN
      --
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , cv_tkn_orga_code
                                           );
      --
      RAISE global_api_others_expt;
      --
    END IF;
    --
    --在庫組織ID取得
    gn_orga_id := xxcoi_common_pkg.get_organization_id( gv_orga_code );
--
    -- 在庫組織ID取得エラーの場合
    IF ( gn_orga_id IS NULL ) THEN
      --
      ov_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_orga );
      --
      RAISE global_api_others_expt;
      --
    END IF;
-- 2011/04/14 Ver.1.9 S.Ochiai ADD End
--
  EXCEPTION
    WHEN file_open_expt THEN
      ov_errbuf := ov_errbuf || ov_errmsg;
      ov_retcode := cv_status_error;
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
-- 2011/09/27 DEL Ver.1.10 Start
--  /**********************************************************************************
--   * Procedure Name   : proc_threshold
--   * Description      : A-4． 閾値抽出
--   ***********************************************************************************/
--  PROCEDURE proc_threshold(
--    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
--    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
--    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_threshold'; -- プログラム名
----
----#####################  固定ローカル変数宣言部 START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
----
--    -- *** ローカル・カーソル ***
----
--    -- *** ローカル・レコード ***
----
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    SELECT mtsi.attribute10          hot_stock_days
--    INTO   gv_hot_stock_days
--    FROM   mtl_secondary_inventories mtsi
--    WHERE  mtsi.attribute1 = cv_warehouse
--    AND    mtsi.attribute7 = header_rec.base_code
--    AND    mtsi.attribute6 = cv_flag_on
--    ;
---- 2009/10/14 Add Ver.1.8 Start
--    IF (gv_hot_stock_days IS NULL) THEN
--      -- 閾値がNULLの場合
--      xxcos_common_pkg.makeup_key_info(
--         ov_errbuf      => lv_errbuf                   -- エラー・メッセージ
--        ,ov_retcode     => lv_retcode                  -- リターン・コード
--        ,ov_errmsg      => lv_errmsg                   -- ユーザー・エラー・メッセージ
--        ,ov_key_info    => gv_key_info                 -- キー情報
--        ,iv_item_name1  => gv_msg_tkn_warehouse_cl     -- 項目名称1
--        ,iv_data_value1 => cv_warehouse                -- データの値1
--        ,iv_item_name2  => gv_msg_tkn_base_code        -- 項目名称2
--        ,iv_data_value2 => header_rec.base_code        -- データの値2
--        ,iv_item_name3  => gv_msg_tkn_main_warehouse_c -- 項目名称3
--        ,iv_data_value3 => cv_flag_on                  -- データの値3
--      );
--      --
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_application
--                     ,iv_name         => cv_msg_threshold_null
--                     ,iv_token_name1  => cv_tkn_key_data
--                     ,iv_token_value1 => gv_key_info
--                   );
--      --
--      fnd_file.put_line(
--         which  => fnd_file.output
--        ,buff   => lv_errmsg
--      );
--      --
--      RAISE global_api_expt;
--      --
--    END IF;
--    --
---- 2009/10/14 Add Ver.1.8 End
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--
--      xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
--                                      ,ov_retcode     => lv_retcode                 --リターン・コード
--                                      ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
--                                      ,ov_key_info    => gv_key_info                --キー情報
--                                      ,iv_item_name1  => gv_msg_tkn_warehouse_cl    --項目名称1
--                                      ,iv_data_value1 => cv_warehouse               --データの値1
--                                      ,iv_item_name2  => gv_msg_tkn_base_code       --項目名称2
--                                      ,iv_data_value2 => header_rec.base_code       --データの値2
--                                      ,iv_item_name3  => gv_msg_tkn_main_warehouse_c --項目名称3
--                                      ,iv_data_value3 => cv_flag_on                  --データの値3
--                                      );
--
--      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
--                                          , cv_msg_select_err
--                                          , cv_tkn_table_name
--                                          , gv_msg_tkn_mtl_second_inv
--                                          , cv_tkn_key_data
--                                          , gv_key_info
--                                          );
--      FND_FILE.PUT_LINE(
--                        which  => FND_FILE.OUTPUT
--                       ,buff   => ov_errmsg --エラーメッセージ
--                       );
--
--      FND_FILE.PUT_LINE(
--                        which  => FND_FILE.LOG
--                       ,buff   => lv_errbuf --エラーメッセージ
--                       );
--      ov_errmsg := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
--
--      FND_FILE.PUT_LINE(
--                        which  => FND_FILE.LOG
--                       ,buff   => ov_errmsg --エラーメッセージ
--                       );
--      ov_retcode := cv_status_warn;

----
----#####################################  固定部 END   ##########################################
----
--  END proc_threshold;
-- 2011/09/27 DEL Ver.1.10 End
--
-- 2011/04/14 Ver.1.9 S.Ochiai DEL Start
--
--  /**********************************************************************************
--   * Procedure Name   : proc_new_item_select
--   * Description      : A-7．コラムの最新品目抽出
--   ***********************************************************************************/
--  PROCEDURE proc_new_item_select(
--    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
--    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
--    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_new_item_select'; -- プログラム名
----
----#####################  固定ローカル変数宣言部 START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
----
--    -- *** ローカル・カーソル ***
----
--    -- *** ローカル・レコード ***
----
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    SELECT xvdl.item_code      item_code
--          ,xvdl.hot_cold_type  hot_cold_type
--          ,a.dlv_date_time     dlv_date_time
--    INTO   gv_item_code
--          ,gv_hot_cold_type
--          ,gt_dlv_date_time
--    FROM   xxcos_vd_deliv_lines xvdl
--          ,(SELECT MAX(dlv_date_time) dlv_date_time
--                  ,customer_number
--                  ,dlv_date
--                  ,column_num
--            FROM   xxcos_vd_deliv_lines
--            WHERE  customer_number = main_rec.account_number
--            AND    dlv_date        = header_rec.dlv_date
--            AND    column_num      = column_rec.column_no
--            GROUP BY customer_number
--                    ,dlv_date
--                    ,column_num
--           ) a
--    WHERE  xvdl.customer_number = a.customer_number
--    AND    xvdl.column_num      = a.column_num
--    AND    xvdl.dlv_date        = a.dlv_date
--    AND    xvdl.dlv_date_time   = a.dlv_date_time
--    ;
----
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
--                                      ,ov_retcode     => lv_retcode                 --リターン・コード
--                                      ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
--                                      ,ov_key_info    => gv_key_info                --キー情報
--                                      ,iv_item_name1  => gv_msg_tkn_cust_code       --項目名称1
--                                      ,iv_data_value1 => main_rec.account_number    --データの値1
--                                      ,iv_item_name2  => gv_msg_tkn_column_no       --項目名称2
--                                      ,iv_data_value2 => column_rec.column_no       --データの値2
--                                      ,iv_item_name3  => gv_msg_tkn_dlv_date        --項目名称3
--                                      ,iv_data_value3 => header_rec.dlv_date  --データの値3
--                                      );
--
--      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
--                                          , cv_msg_select_err
--                                          , cv_tkn_table_name
--                                          , gv_msg_tkn_vd_deliv_l
--                                          , cv_tkn_key_data
--                                          , gv_key_info
--                                          );
--      FND_FILE.PUT_LINE(
--                        which  => FND_FILE.OUTPUT
--                       ,buff   => ov_errmsg --エラーメッセージ
--                       );
--
--      FND_FILE.PUT_LINE(
--                        which  => FND_FILE.LOG
--                       ,buff   => lv_errbuf --エラーメッセージ
--                       );
--      ov_errmsg := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
--      FND_FILE.PUT_LINE(
--                        which  => FND_FILE.LOG
--                       ,buff   => ov_errmsg --エラーメッセージ
--                       );
--      ov_retcode := cv_status_warn;
----
----#####################################  固定部 END   ##########################################
----
--  END proc_new_item_select;
----
-- 2011/04/14 Ver.1.9 S.Ochiai DEL End
--
  /**********************************************************************************
   * Procedure Name   : proc_month_qty
   * Description      : A-9．月販数、基準在庫数導出
   ***********************************************************************************/
  PROCEDURE proc_month_qty(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_month_qty'; -- プログラム名
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
    SELECT NVL(SUM(xvdl.sales_qty),0)        sum_sales_qty
          ,NVL(SUM(xvdl.standard_inv_qty),0) sum_standard_inv_qty
    INTO   gn_monthly_sales                                --月販数
          ,gn_inventory_quantity_sum                       --基準在庫数（合計）
    FROM   xxcos_vd_deliv_lines xvdl                       --ベンダ納品実績情報明細テーブル
    WHERE  xvdl.customer_number = main_rec.account_number
-- 2011/09/27 ADD Ver.1.10 Start
    AND    xvdl.column_num    = main_rec.column_no
-- 2011/10/24 Mod Ver.1.11 Start
--    AND    xvdl.dlv_date_time > GREATEST(TO_DATE(TO_CHAR(ADD_MONTHS(gd_standard_date, -1), 'YYYY/MM/DD') ||' '|| cv_last_time, 'YYYY/MM/DD HH24:MI:SS')
--                                         , gd_vd_change_dlv_date_time)
    AND    xvdl.dlv_date_time > GREATEST(TO_DATE(TO_CHAR(ADD_MONTHS(gd_standard_date, -1), 'YYYY/MM/DD') ||' '|| cv_last_time, 'YYYY/MM/DD HH24:MI:SS')
                                         , gt_deli_l_tab(main_rec.column_no).vd_change_dlv_date_time)
-- 2011/10/24 Mod Ver.1.11 End
    AND    xvdl.item_code     = NVL(main_rec.item_code, cv_blank_c);
-- 2011/09/27 ADD Ver.1.10 End
-- 2011/09/27 DEL Ver.1.10 Start
--    AND    xvdl.column_num      = column_rec.column_no
--    AND    xvdl.dlv_date        > ADD_MONTHS(gd_standard_date, -1)
---- 2011/04/14 Ver.1.9 S.Ochiai MOD Start
----    AND    xvdl.item_code       = gv_item_code
--    AND    xvdl.item_code       = NVL(gv_item_code, cv_blank_c)
---- 2011/04/14 Ver.1.9 S.Ochiai MOD End
--    ;
-- 2011/09/27 DEL Ver.1.10 End
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
  END proc_month_qty;
--
  /**********************************************************************************
   * Procedure Name   : proc_sales_days
   * Description      : A-10．販売日数導出
   ***********************************************************************************/
  PROCEDURE proc_sales_days(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_sales_days'; -- プログラム名
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
    ld_min_dlv_date DATE;
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
    SELECT MIN(xvdl.dlv_date)
    INTO   ld_min_dlv_date
    FROM   xxcos_vd_deliv_lines xvdl                       --ベンダ納品実績情報明細テーブル
    WHERE  xvdl.customer_number = main_rec.account_number
-- 2011/09/27 ADD Ver.1.10 Start
    AND    xvdl.column_num    = main_rec.column_no
    AND    xvdl.item_code     = NVL(main_rec.item_code, cv_blank_c)
-- 2011/10/24 Mod Ver.1.11 Start
--    AND    xvdl.dlv_date_time > gd_vd_change_dlv_date_time;
    AND    xvdl.dlv_date_time > gt_deli_l_tab(main_rec.column_no).vd_change_dlv_date_time;
-- 2011/10/24 Mod Ver.1.11 End
-- 2011/09/27 ADD Ver.1.10 END
-- 2011/09/27 DEL Ver.1.10 Start
--    AND    xvdl.column_num      = column_rec.column_no
---- 2011/04/14 Ver.1.9 S.Ochiai MOD Start
----    AND    xvdl.item_code       = gv_item_code
--    AND    xvdl.item_code       = NVL(gv_item_code, cv_blank_c)
---- 2011/04/14 Ver.1.9 S.Ochiai MOD End
--    ;
-- 2011/09/27 DEL Ver.1.10 END

    IF ld_min_dlv_date > ADD_MONTHS(gd_standard_date ,-1) THEN
      gn_sales_days := gd_standard_date - ld_min_dlv_date;
    ELSE
      gn_sales_days := gd_standard_date - ADD_MONTHS(gd_standard_date ,-1);
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
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;

      xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
                                      ,ov_retcode     => lv_retcode                 --リターン・コード
                                      ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
                                      ,ov_key_info    => gv_key_info                --キー情報
                                      ,iv_item_name1  => gv_msg_tkn_cust_code       --項目名称1
                                      ,iv_data_value1 => main_rec.account_number    --データの値1
                                      ,iv_item_name2  => gv_msg_tkn_column_no       --項目名称2
-- 2011/09/27 MOD Ver.1.10 Start
--                                      ,iv_data_value2 => column_rec.column_no       --データの値2
                                      ,iv_data_value2 => main_rec.column_no       --データの値2
-- 2011/09/27 MOD Ver.1.10 End
                                      ,iv_item_name3  => gv_msg_tkn_item_code       --項目名称3
-- 2011/09/27 MOD Ver.1.10 Start
--                                      ,iv_data_value3 => gv_item_code               --データの値3
                                      ,iv_data_value3 => main_rec.item_code         --データの値3
-- 2011/09/27 MOD Ver.1.10 End
                                      );

      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_select_err
                                          , cv_tkn_table_name
                                          , gv_msg_tkn_vd_deliv_l
                                          , cv_tkn_key_data
                                          , gv_key_info
                                          );
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.OUTPUT
                       ,buff   => ov_errmsg --エラーメッセージ
                       );
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.LOG
                       ,buff   => lv_errbuf --エラーメッセージ
                       );
      ov_errmsg := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
      FND_FILE.PUT_LINE(
                        which  => FND_FILE.LOG
                       ,buff   => ov_errmsg --エラーメッセージ
                       );

      ov_retcode := cv_status_warn;
--
--#####################################  固定部 END   ##########################################
--
  END proc_sales_days;
--
  /**********************************************************************************
   * Procedure Name   : proc_hot_warn
   * Description      : A-11．ホット警告残数導出
   ***********************************************************************************/
  PROCEDURE proc_hot_warn(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_hot_warn'; -- プログラム名
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
    ln_sales_total_qty NUMBER;
-- 2011/09/27 DEL Ver.1.10 Start
---- 2009/07/24 Add Ver.1.6 Start
--    lt_change_column_date  xxcos_vd_deliv_lines.dlv_date%TYPE;
--    lt_change_hctype_date  xxcos_vd_deliv_lines.dlv_date%TYPE;
---- 2009/07/24 Add Ver.1.6 End
-- 2011/09/27 DEL Ver.1.10 End
--
-- 2011/09/27 ADD Ver.1.10 Start
    lt_vd_change_date  xxcos_vd_deliv_lines.dlv_date%TYPE;
-- 2011/09/27 ADD Ver.1.10 End
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
-- 2011/09/27 ADD Ver.1.10 Start
    SELECT MIN(xvdl.dlv_date)
    INTO   lt_vd_change_date
    FROM   xxcos_vd_deliv_lines xvdl
    WHERE  xvdl.customer_number = main_rec.account_number
    AND    xvdl.column_num      = main_rec.column_no
-- 2011/10/24 Mod Ver.1.11 Start
--    AND    xvdl.dlv_date_time   > gd_vd_change_dlv_date_time;
    AND    xvdl.dlv_date_time   > gt_deli_l_tab(main_rec.column_no).vd_change_dlv_date_time;
-- 2011/10/24 Mod Ver.1.11 End

    IF (main_rec.dlv_date < lt_vd_change_date + TO_NUMBER(main_rec.hot_stock_days)) THEN
      RAISE column_change_data_expt;
    END IF;
-- 2011/09/27 ADD Ver.1.10 End

-- 2011/09/27 DEL Ver.1.10 Start
---- 2009/07/24 Add Ver.1.6 Start
--    -- ■ コラム変更の最終更新納品日を取得する。
--    BEGIN
--      SELECT MIN(xvdl.dlv_date)                                           -- コラムを最後に変更した日時
--      INTO   lt_change_column_date
--      FROM   xxcos_vd_deliv_lines xvdl                                    -- (TABLE)ベンダ納品明細
--            ,( SELECT MAX(xvdl_m.dlv_date_time) dlv_date_time             -- 最後にコラム変更を実施する前の日時
--               FROM   xxcos_vd_deliv_lines xvdl_m                         -- (TABLE)ベンダ納品明細
--               WHERE  xvdl_m.customer_number = main_rec.account_number
--               AND    xvdl_m.column_num      = column_rec.column_no
---- 2011/04/14 Ver.1.9 S.Ochiai MOD Start
----               AND    xvdl_m.item_code      <> gv_item_code
--               AND    xvdl_m.item_code      <> NVL(gv_item_code, cv_blank_c)
---- 2011/04/14 Ver.1.9 S.Ochiai MOD End
--             ) xvdl_v
--      WHERE  xvdl.customer_number = main_rec.account_number
--      AND    xvdl.column_num      = column_rec.column_no
--      AND    xvdl_v.dlv_date_time IS NOT NULL
--      AND    xvdl.dlv_date_time   > xvdl_v.dlv_date_time;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        lt_change_column_date := NULL;
--    END;
----
--    -- ■ コラム変更が閾値内で実施された場合、後続の処理を実施しない。
--    IF (   lt_change_column_date IS NOT NULL
--       AND header_rec.dlv_date < lt_change_column_date + TO_NUMBER(gv_hot_stock_days)
--       ) THEN
--      RAISE column_change_data_expt;
--    END IF;
----
--    -- ■ H/C区分変更の最終更新納品日を取得する。
--    BEGIN
--      SELECT MIN(xvdl.dlv_date)
--      INTO   lt_change_hctype_date
--      FROM   xxcos_vd_deliv_lines xvdl
--            ,( SELECT MAX(xvdl_m.dlv_date_time) dlv_date_time
--               FROM   xxcos_vd_deliv_lines xvdl_m
--               WHERE  xvdl_m.customer_number = main_rec.account_number
--               AND    xvdl_m.column_num      = column_rec.column_no
---- 2011/04/14 Ver.1.9 S.Ochiai MOD Start
----               AND    xvdl_m.item_code       = gv_item_code
--               AND    xvdl_m.item_code       = NVL(gv_item_code, cv_blank_c)
---- 2011/04/14 Ver.1.9 S.Ochiai MOD End
--               AND    xvdl_m.hot_cold_type  <> gv_hot_cold_type
--             ) xvdl_v
--      WHERE  xvdl.customer_number = main_rec.account_number
--      AND    xvdl.column_num      = column_rec.column_no
--      AND    xvdl_v.dlv_date_time IS NOT NULL
--      AND    xvdl.dlv_date_time   > xvdl_v.dlv_date_time;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        lt_change_hctype_date := NULL;
--    END;
----
--    -- ■ コラム変更が閾値内で実施された場合、後続の処理を実施しない。
--    IF (   lt_change_hctype_date IS NOT NULL
--       AND header_rec.dlv_date < lt_change_hctype_date + TO_NUMBER(gv_hot_stock_days)
--       ) THEN
--      RAISE hctype_change_data_expt;
--    END IF;
----
--    -- ■ 上記の条件を満たさない場合、ホット警告残数を取得する。
---- 2009/07/24 Add Ver.1.6 End
-- 2011/09/27 DEL Ver.1.10 End

    BEGIN
      SELECT NVL(SUM(xvdl.sales_qty),0)
      INTO   ln_sales_total_qty
      FROM   xxcos_vd_deliv_lines xvdl
      WHERE  xvdl.customer_number = main_rec.account_number
-- 2011/09/27 ADD Ver.1.10 Start
      AND    xvdl.column_num    = main_rec.column_no
-- 2011/10/24 Mod Ver.1.11 Start
--      AND    xvdl.dlv_date_time > GREATEST((gd_standard_date - TO_NUMBER(main_rec.hot_stock_days)), gd_vd_change_dlv_date_time)
      AND    xvdl.dlv_date_time > GREATEST((gd_standard_date - TO_NUMBER(main_rec.hot_stock_days)),
                                           gt_deli_l_tab(main_rec.column_no).vd_change_dlv_date_time)
-- 2011/10/24 Mod Ver.1.11 End
      AND    xvdl.item_code     = NVL(main_rec.item_code, cv_blank_c);
-- 2011/09/27 ADD Ver.1.10 End
-- 2011/09/27 DEL Ver.1.10 Start
--      AND    xvdl.column_num      = column_rec.column_no
--      AND    xvdl.dlv_date        > (gd_standard_date - gv_hot_stock_days)
---- 2011/04/14 Ver.1.9 S.Ochiai MOD Start
----      AND    xvdl.item_code       = gv_item_code
--      AND    xvdl.item_code       = NVL(gv_item_code, cv_blank_c)
---- 2011/04/14 Ver.1.9 S.Ochiai MOD End
--      ;
-- 2011/09/27 DEL Ver.1.10 End
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_sales_total_qty := 0;
    END;
-- 2011/09/27 MOD Ver.1.10 Start
---- 2009/04/16 K.Kiriu Ver.1.3 Mod start
----    gn_hot_warn_qty := gn_inventory_quantity_sum - ln_sales_total_qty;
--    gn_hot_warn_qty := column_rec.inventory_quantity - ln_sales_total_qty;
---- 2009/04/16 K.Kiriu Ver.1.3 Mod end
    gn_hot_warn_qty := main_rec.inventory_quantity - ln_sales_total_qty;
-- 2011/09/27 MOD Ver.1.10 End
--
-- 2009/07/15 Ver.1.5 Mod Start
    IF ( gn_hot_warn_qty < 0 ) THEN
      gn_hot_warn_qty := 0;
    END IF;
-- 2009/07/15 Ver.1.5 Mod End
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN column_change_data_expt THEN
      gn_hot_warn_qty := 0;
    -- *** 共通関数例外ハンドラ ***
    WHEN hctype_change_data_expt THEN
      gn_hot_warn_qty := 0;
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
  END proc_hot_warn;
--
  /**********************************************************************************
   * Procedure Name   : proc_deli_l_file_out
   * Description      : A-13．納品実績情報明細ファイル出力
   ***********************************************************************************/
  PROCEDURE proc_deli_l_file_out(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_deli_l_file_out'; -- プログラム名
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
  --編集
-- 2009/07/15 Ver.1.5 Mod Start
--    SELECT                  cv_quot || main_rec.account_number             || cv_quot --顧客コード
--           || cv_delimit || cv_quot || column_rec.column_no                || cv_quot --コラムNo        A-5で抽出したコラムNo
--           || cv_delimit || TO_CHAR(gn_monthly_sales)                                 --月販数（表示用）A-9で抽出した月販数
--           || cv_delimit || TO_CHAR(gn_monthly_sales)                                 --月販数          A-9で抽出した月販数
--           || cv_delimit || TO_CHAR(gn_sales_days)                                    --販売日数        A-10で抽出した販売日数
--           || cv_delimit || TO_CHAR(gn_sales_days)                                    --基準日数        A-10で抽出した販売日数
---- 2009/04/16 K.Kiriu Ver.1.3 Mod start
----           || cv_delimit || TO_CHAR(NVL(gn_inventory_quantity_sum,0))                 --基準在庫数      A-9で抽出した基準在庫数
----           || cv_delimit || TO_CHAR(NVL(gn_hot_warn_qty,0))                           --ホット警告残数  A-11で抽出したホット警告残数を設定。
--           || cv_delimit || SUBSTRB(TO_CHAR(NVL(gn_inventory_quantity_sum,0)), 1, 3)  --基準在庫数      A-9で抽出した基準在庫数(3桁以上の場合は先頭3桁)
--           || cv_delimit || SUBSTRB(TO_CHAR(NVL(gn_hot_warn_qty,0)), 1, 2)            --ホット警告残数  A-11で抽出したホット警告残数を設定。(2桁以上の場合は先頭2桁)
--                                                                                                        --H/CがC（コールド）の場合は0を設定
---- 2009/04/16 K.Kiriu Ver.1.3 Mod end
--           || cv_delimit || TO_CHAR(NVL(gn_sales_qty_1 ,0))                           --前回売上数      A-6で抽出した1件目の売上数
--           || cv_delimit || TO_CHAR(NVL(gn_sales_qty_2 ,0))                           --前々回売上数    A-6で抽出した2件目の売上数
--           || cv_delimit || TO_CHAR(NVL(gn_sales_qty_3 ,0))                           --前々前回売上数  A-6で抽出した3件目の売上数
--           || cv_delimit || TO_CHAR(NVL(gn_replacement_rate,0))                       --補充率          A-12で抽出した補充率
--    INTO gv_deli_l_file_data
--    FROM DUAL
--    ;
    SELECT             cv_quot || gt_deli_l_tab(gn_deli_l_cnt).account_number || cv_quot --顧客コード      A-13の顧客コード
      || cv_delimit || cv_quot || gt_deli_l_tab(gn_deli_l_cnt).column_no      || cv_quot --コラムNo        A-13のコラムNo
      || cv_delimit || TO_CHAR(gt_deli_l_tab(gn_deli_l_cnt).monthly_sales)               --月販数（表示用）A-13の月販数
      || cv_delimit || TO_CHAR(gt_deli_l_tab(gn_deli_l_cnt).monthly_sales)               --月販数          A-13の月販数
      || cv_delimit || TO_CHAR(gt_deli_l_tab(gn_deli_l_cnt).sales_days)                  --販売日数        A-13の販売日数
      || cv_delimit || TO_CHAR(gt_deli_l_tab(gn_deli_l_cnt).sales_days)                  --基準日数        A-13の販売日数
      || cv_delimit || SUBSTRB(TO_CHAR(NVL(gt_deli_l_tab(gn_deli_l_cnt).inventory_quantity_sum,0)), 1, 3)
                                                                                         --基準在庫数      A-13の基準在庫数
                                                                                         --                ・3桁以上の場合は先頭3桁
      || cv_delimit || SUBSTRB(TO_CHAR(NVL(gt_deli_l_tab(gn_deli_l_cnt).hot_warn_qty,0)), 1, 2)
                                                                                         --ホット警告残数  A-13のホット警告残数
                                                                                         --                ・2桁以上の場合は先頭2桁
                                                                                         --                ・H/CがC（コールド）の場合は0を設定
      || cv_delimit || TO_CHAR(NVL(gt_deli_l_tab(gn_deli_l_cnt).sales_qty_1 ,0))         --前回売上数      A-13の1件目の売上数
      || cv_delimit || TO_CHAR(NVL(gt_deli_l_tab(gn_deli_l_cnt).sales_qty_2 ,0))         --前々回売上数    A-13の2件目の売上数
      || cv_delimit || TO_CHAR(NVL(gt_deli_l_tab(gn_deli_l_cnt).sales_qty_3 ,0))         --前々前回売上数  A-13の3件目の売上数
      || cv_delimit || TO_CHAR(NVL(gt_deli_l_tab(gn_deli_l_cnt).replacement_rate,0))     --補充率          A-13の補充率
    INTO gv_deli_l_file_data
    FROM DUAL
    ;
-- 2009/07/15 Ver.1.5 Mod End

  --ファイル出力
    UTL_FILE.PUT_LINE(gt_deli_l_handle
                     ,gv_deli_l_file_data
                     );


-- 2011/09/27 DEL Ver.1.10 Start
--  --変数初期化
--  gn_monthly_sales           := NULL;
--  gn_sales_days              := NULL;
--  gn_inventory_quantity_sum  := NULL;
--  gn_hot_warn_qty            := NULL;
--  gn_sales_qty_1             := NULL;
--  gn_sales_qty_2             := NULL;
--  gn_sales_qty_3             := NULL;
--  gn_replacement_rate        := NULL;
-- 2011/09/27 DEL Ver.1.10 End
--
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
  END proc_deli_l_file_out;
--
  /**********************************************************************************
   * Procedure Name   : proc_deli_h_file_out
   * Description      : A-15．納品実績情報ヘッダファイル出力
   ***********************************************************************************/
  PROCEDURE proc_deli_h_file_out(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_deli_h_file_out'; -- プログラム名
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

  --編集
-- 2011/09/27 MOD Ver.1.10 Start
--    SELECT                  cv_quot || main_rec.account_number || cv_quot --顧客コード
    SELECT       cv_quot || main_rec_old.account_number || cv_quot --顧客コード
-- 2011/09/27 MOD Ver.1.10 End
           || cv_delimit ||  TO_CHAR(gd_dlv_date_1,'MMDD')               --前回納品日（ＭＭＤＤ）
           || cv_delimit ||  TO_CHAR(gd_dlv_date_2,'MMDD')               --前々回納品日
           || cv_delimit ||  TO_CHAR(gd_dlv_date_3,'MMDD')               --前々前回納品日
           || cv_delimit ||  gv_visit_time                               --前回訪問時刻
           || cv_delimit ||  TO_CHAR(gn_last_visit_days)                 --前回訪問日数
           || cv_delimit ||  TO_CHAR(NVL(gn_sales_qty_sum_1,0))          --前回納品数量
           || cv_delimit ||  TO_CHAR(NVL(gn_sales_qty_sum_2,0))          --前々回納品数量
           || cv_delimit ||  TO_CHAR(NVL(gn_sales_qty_sum_3,0))          --前々前回納品数量
           || cv_delimit ||  TO_CHAR(NVL(gn_total_amount_1 ,0))          --前回納品金額
           || cv_delimit ||  TO_CHAR(NVL(gn_total_amount_2 ,0))          --前々回納品金額
           || cv_delimit ||  TO_CHAR(NVL(gn_total_amount_3 ,0))          --前々前回納品金額
           || cv_delimit || cv_quot ||TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || cv_quot    --更新日時
    INTO gv_deli_h_file_data
    FROM DUAL
    ;

  --ファイル出力
    UTL_FILE.PUT_LINE(gt_deli_h_handle
                     ,gv_deli_h_file_data
                     );

  --変数初期化
    --売上数
  gd_dlv_date_1      := NULL;
  gd_dlv_date_2      := NULL;
  gd_dlv_date_3      := NULL;
  gv_visit_time      := NULL;
  gn_last_visit_days := 0;
  gn_sales_qty_sum_1 := 0;
  gn_sales_qty_sum_2 := 0;
  gn_sales_qty_sum_3 := 0;
  gn_total_amount_1  := 0;
  gn_total_amount_2  := 0;
  gn_total_amount_3  := 0;

--
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
  END proc_deli_h_file_out;
--
-- 2011/09/27 ADD Ver.1.10 Start
  /**********************************************************************************
   * Procedure Name   : proc_get_vd_col_change_date
   * Description      : A-19．ベンダコラム変更日取得
   ***********************************************************************************/
  PROCEDURE proc_get_vd_col_change_date(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_vd_col_change_date'; -- プログラム名
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
    ld_item_change_date_time  DATE;
    ld_hc_change_date_time    DATE;
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
    -- 品目の変更前の納品日を取得
    SELECT NVL(MAX(xvdl.dlv_date_time), gd_min_date)
    INTO   ld_item_change_date_time
    FROM   xxcos_vd_deliv_lines xvdl
    WHERE  xvdl.customer_number = main_rec.account_number
    AND    xvdl.column_num = main_rec.column_no
    AND    xvdl.item_code != main_rec.item_code;

    -- Hot/Cold区分の変更前の納品日を取得
    SELECT NVL(MAX(xvdl.dlv_date_time), gd_min_date)
    INTO   ld_hc_change_date_time
    FROM   xxcos_vd_deliv_lines xvdl
    WHERE  xvdl.customer_number = main_rec.account_number
    AND    xvdl.column_num = main_rec.column_no
    AND    xvdl.item_code = main_rec.item_code
    AND    xvdl.hot_cold_type != main_rec.hot_cold;

    -- 品目、Hot/Cold区分の変更日のどちらか大きい方を納品日時（ベンダ変更日）として保持
    gd_vd_change_dlv_date_time := GREATEST(ld_item_change_date_time, ld_hc_change_date_time);
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
  END proc_get_vd_col_change_date;
-- 2011/09/27 ADD Ver.1.10 End

  /**********************************************************************************
   * Procedure Name   : proc_main_loop（ループ部）
-- 2011/09/27 MOD Ver.1.10 Start
--   * Description      : A-2．顧客マスタデータ抽出
   * Description      : A-17．ベンダ納品実績データ抽出
-- 2011/09/27 MOD Ver.1.10 End
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
    tran_in_expt      EXCEPTION;
-- 2011/09/27 ADD Ver.1.10 Start
    data_skip_expt    EXCEPTION;     -- データスキップのために利用
-- 2011/09/27 ADD Ver.1.10 End
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_message_code          VARCHAR2(20);
-- 2011/09/27 DEL Ver.1.10 Start
--    ln_header_cnt            NUMBER;
--    ln_column_cnt            NUMBER;
--    ln_line_count            NUMBER;
---- 2009/07/15 Ver.1.5 Add Start
--    ln_deli_l_cnt            NUMBER;
---- 2009/07/15 Ver.1.5 Add End
-- 2011/09/27 DEL Ver.1.10 End

-- 2009/10/14 Ver.1.8 Add Start
    lv_message_data          VARCHAR2(1000);
-- 2009/10/14 Ver.1.8 Add End
-- 2011/09/27 ADD Ver.1.10 Start
    lb_new_customer          BOOLEAN;
    lb_data_skip             BOOLEAN;
    ln_cnt                   NUMBER;
-- 2011/09/27 ADD Ver.1.10 End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2011/09/27 ADD Ver.1.10 Start
    lb_new_customer := TRUE;
    lb_data_skip    := FALSE;
    gt_deli_l_tab.DELETE;

    main_rec_old := NULL;
    OPEN main_cur;
    FETCH main_cur INTO main_rec;
    <<main_loop>>
    LOOP
      BEGIN
        IF (main_rec.account_number != main_rec_old.account_number)
          OR (main_rec_old.account_number IS NULL)
          OR (main_cur%NOTFOUND)
        THEN
          -- 顧客単位のデータスキップ条件クリア処理
          IF (lb_data_skip = TRUE) THEN
            gt_deli_l_tab.DELETE;
          END IF;
          lb_new_customer := TRUE;
          lb_data_skip := FALSE;
        END IF;

        IF (lb_data_skip = TRUE) THEN
          RAISE data_skip_expt;
        END IF;

        IF ((gt_deli_l_tab.COUNT > 0)
          AND (lb_new_customer = TRUE)
          AND (main_rec_old.account_number IS NOT NULL))
        THEN
          -- ==================================================
          --A-13.  納品実績情報明細ファイル出力
          -- ==================================================
          gn_deli_l_cnt := gt_deli_l_tab.FIRST;
          << output_deli_l_loop >>
          LOOP
            proc_deli_l_file_out(
                                 lv_errbuf   -- エラー・メッセージ           --# 固定 #
                                ,lv_retcode  -- リターン・コード             --# 固定 #
                                ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                                );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE tran_in_expt;
            END IF;
            IF gn_deli_l_cnt = gt_deli_l_tab.LAST THEN
              EXIT output_deli_l_loop;
            END IF;
            gn_deli_l_cnt := gt_deli_l_tab.NEXT(gn_deli_l_cnt);
          END LOOP output_deli_l_loop;
          -- ==================================================
          --A-14．前回訪問日数導出
          -- ==================================================
          --初期処理で取得した基準日　―　A-3で抽出した（顧客内で）1件の納品日
          gn_last_visit_days := gd_standard_date - gd_dlv_date_1;

          -- ==================================================
          --A-15． 納品実績情報ヘッダファイル出力
          -- ==================================================
          proc_deli_h_file_out(
                               lv_errbuf   -- エラー・メッセージ           --# 固定 #
                              ,lv_retcode  -- リターン・コード             --# 固定 #
                              ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                              );
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE tran_in_expt;
          END IF;
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;

        EXIT main_loop WHEN main_cur%NOTFOUND;

        IF (lb_new_customer = TRUE) THEN
          gn_target_cnt := gn_target_cnt + 1;

          -- ヘッダ関連変数初期化
          ln_cnt := 0;
          gd_dlv_date_1      := NULL;
          gd_dlv_date_2      := NULL;
          gd_dlv_date_3      := NULL;
          gn_last_visit_days := 0;
          gv_visit_time      := NULL;
          gn_sales_qty_sum_1 := 0;
          gn_sales_qty_sum_2 := 0;
          gn_sales_qty_sum_3 := 0;
          gn_total_amount_1  := 0;
          gn_total_amount_2  := 0;
          gn_total_amount_3  := 0;

          gt_deli_l_tab.DELETE;
        END IF;

        IF ((main_rec.dlv_date != main_rec_old.dlv_date) OR (lb_new_customer = TRUE)) THEN
          ln_cnt := ln_cnt + 1;

          -- A-18 納品実績データチェック
          IF (main_rec.hot_stock_days IS NULL) THEN
            -- Hot在庫（閾値）がNULLの場合の処理
            xxcos_common_pkg.makeup_key_info(
               ov_errbuf      => lv_errbuf                   -- エラー・メッセージ
              ,ov_retcode     => lv_retcode                  -- リターン・コード
              ,ov_errmsg      => lv_errmsg                   -- ユーザー・エラー・メッセージ
              ,ov_key_info    => gv_key_info                 -- キー情報
              ,iv_item_name1  => gv_msg_tkn_warehouse_cl     -- 項目名称1
              ,iv_data_value1 => cv_warehouse                -- データの値1
              ,iv_item_name2  => gv_msg_tkn_base_code        -- 項目名称2
              ,iv_data_value2 => main_rec.base_code          -- データの値2
              ,iv_item_name3  => gv_msg_tkn_main_warehouse_c -- 項目名称3
              ,iv_data_value3 => cv_flag_on                  -- データの値3
            );
            --
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                           ,iv_name         => cv_msg_threshold_null
                           ,iv_token_name1  => cv_tkn_key_data
                           ,iv_token_value1 => gv_key_info
                         );
            --
            fnd_file.put_line(
               which  => fnd_file.output
              ,buff   => lv_errmsg
            );

            ov_retcode := cv_status_warn;
            gn_warn_cnt := gn_warn_cnt + 1;
            lb_data_skip := TRUE;
            RAISE data_skip_expt;
          END IF;

          IF (ln_cnt = 1) THEN
            gv_visit_time := main_rec.visit_time;
            gd_dlv_date_1 := main_rec.dlv_date;
            gn_total_amount_1 := main_rec.total_amount;
          ELSIF (ln_cnt = 2) THEN
            gd_dlv_date_2 := main_rec.dlv_date;
            gn_total_amount_2 := main_rec.total_amount;
          ELSIF (ln_cnt = 3) THEN
            gd_dlv_date_3 := main_rec.dlv_date;
            gn_total_amount_3 := main_rec.total_amount;
          END IF;
        END IF;
-- 2011/10/24 Add Ver1.11 Start
        IF (ln_cnt = 1) THEN
-- 2011/10/24 Add Ver1.11 End
          -- ==================================================
          --A-19．ベンダコラム変更日取得
          -- ==================================================
          proc_get_vd_col_change_date(
                               lv_errbuf   -- エラー・メッセージ           --# 固定 #
                              ,lv_retcode  -- リターン・コード             --# 固定 #
                              ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                              );
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE tran_in_expt;
          END IF;
-- 2011/10/24 Add Ver1.11 Start
          gt_deli_l_tab(main_rec.column_no).vd_change_dlv_date_time := gd_vd_change_dlv_date_time;
        END IF;
-- 2011/10/24 Add Ver1.11 End
-- 2011/10/24 Mod Ver1.11 Start
--        IF (main_rec.dlv_date >= TRUNC(gd_vd_change_dlv_date_time)) THEN
        IF (main_rec.dlv_date >= TRUNC(gt_deli_l_tab(main_rec.column_no).vd_change_dlv_date_time)) THEN
-- 2011/10/24 Mod Ver1.11 End
          -- ヘッダ売上数サマリ（A-8）
          -- 品目・Hot/Cold区分のどちらかが変更されている場合、変更前は考慮しない
          IF (ln_cnt = 1) THEN
            gn_sales_qty_sum_1 := gn_sales_qty_sum_1 + main_rec.sales_qty_of_day;
          ELSIF (ln_cnt = 2) THEN
            gn_sales_qty_sum_2 := gn_sales_qty_sum_2 + main_rec.sales_qty_of_day;
          ELSIF (ln_cnt = 3) THEN
            gn_sales_qty_sum_3 := gn_sales_qty_sum_3 + main_rec.sales_qty_of_day;
          END IF;
        END IF;

        IF (ln_cnt = 1) THEN
          -- 明細関連変数初期化
          gn_monthly_sales           := 0;
          gn_sales_days              := 0;
          gn_inventory_quantity_sum  := 0;
          gn_hot_warn_qty            := 0;
          gn_replacement_rate        := 0;
          -- ==================================================
          --A-9．月販数、基準在庫数導出
          -- ==================================================
          proc_month_qty(
                               lv_errbuf   -- エラー・メッセージ           --# 固定 #
                              ,lv_retcode  -- リターン・コード             --# 固定 #
                              ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                              );
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE tran_in_expt;
          END IF;

          -- ==================================================
          --A-10．販売日数導出
          -- ==================================================
          proc_sales_days(
                               lv_errbuf   -- エラー・メッセージ           --# 固定 #
                              ,lv_retcode  -- リターン・コード             --# 固定 #
                              ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                              );
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE tran_in_expt;
          END IF;

          -- ==================================================
          --A-11．ホット警告残数導出
          -- ==================================================
          IF (main_rec.hot_cold = cv_hot_type) THEN
            proc_hot_warn(
                                 lv_errbuf   -- エラー・メッセージ           --# 固定 #
                                ,lv_retcode  -- リターン・コード             --# 固定 #
                                ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                                );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE tran_in_expt;
            END IF;
          END IF;

          -- ==================================================
          --A-12．補充率導出
          -- ==================================================
          --補充率　＝　A-9で抽出した月販数　÷　A-9で抽出した基準在庫数　×　100(端数切捨）
          IF gn_inventory_quantity_sum > 0 THEN
            gn_replacement_rate := TRUNC(gn_monthly_sales / gn_inventory_quantity_sum * 100);
            IF (LENGTHB(gn_replacement_rate) > cn_max_length_rep_rate) THEN
              -- 補充率が３桁を超えた場合、固定値999を設定
              gn_replacement_rate := cn_max_replacement_rate;
              --
              lv_message_data := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_application
                                   ,iv_name         => cv_msg_rep_rate_over
                                   ,iv_token_name1  => cv_tkn_max_value
                                   ,iv_token_value1 => cn_max_replacement_rate
                                   ,iv_token_name2  => cv_tkn_customer_code
                                   ,iv_token_value2 => main_rec.account_number
                                   ,iv_token_name3  => cv_tkn_col_no
                                   ,iv_token_value3 => main_rec.column_no
                                 );
              --
              fnd_file.put_line(
                 which => fnd_file.log
                ,buff  => lv_message_data
              );
              --
            END IF;
            --
          END IF;

          gt_deli_l_tab(main_rec.column_no).account_number         := main_rec.account_number;   -- 顧客コード
          gt_deli_l_tab(main_rec.column_no).column_no              := main_rec.column_no;        -- A-5で抽出したコラムNo
          gt_deli_l_tab(main_rec.column_no).monthly_sales          := gn_monthly_sales;          -- A-9で抽出した月販数
          gt_deli_l_tab(main_rec.column_no).sales_days             := gn_sales_days;             -- A-10で抽出した販売日数
          gt_deli_l_tab(main_rec.column_no).inventory_quantity_sum := gn_inventory_quantity_sum; -- A-9で抽出した基準在庫数
          gt_deli_l_tab(main_rec.column_no).hot_warn_qty           := gn_hot_warn_qty;           -- A-11で抽出したホット警告残数
          gt_deli_l_tab(main_rec.column_no).replacement_rate       := gn_replacement_rate;       -- A-12で抽出した補充率
        END IF;
-- 2011/10/24 Mod Ver.1.11 Start
--        IF (main_rec.dlv_date >= TRUNC(gd_vd_change_dlv_date_time)) THEN
        IF (main_rec.dlv_date >= TRUNC(gt_deli_l_tab(main_rec.column_no).vd_change_dlv_date_time)) THEN
-- 2011/10/24 Mod Ver.1.11 End
          -- 品目・Hot/Cold区分のどちらかが変更されている場合、変更前は考慮しない
          IF (ln_cnt = 1) THEN
            gt_deli_l_tab(main_rec.column_no).sales_qty_1            := main_rec.sales_qty_of_day; -- A-6で抽出した1件目の売上数
          ELSIF (ln_cnt = 2) THEN
            gt_deli_l_tab(main_rec.column_no).sales_qty_2            := main_rec.sales_qty_of_day; -- A-6で抽出した2件目の売上数
          ELSIF (ln_cnt = 3) THEN
            gt_deli_l_tab(main_rec.column_no).sales_qty_3            := main_rec.sales_qty_of_day; -- A-6で抽出した3件目の売上数
          END IF;
        END IF;
      EXCEPTION
        WHEN tran_in_expt THEN
          lv_message_data := lv_errbuf;  -- サブプロシージャのエラーを保持
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
                                          ,ov_retcode     => lv_retcode                 --リターン・コード
                                          ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
                                          ,ov_key_info    => gv_key_info                              --キー情報
                                          ,iv_item_name1  => gv_msg_tkn_cust_code                     --項目名称1
                                          ,iv_data_value1 => main_rec.account_number                  --データの値1
                                          ,iv_item_name2  => gv_msg_tkn_column_no                     --項目名称2
                                          ,iv_data_value2 => main_rec.column_no                       --データの値2
                                          ,iv_item_name3  => gv_msg_tkn_dlv_date                      --項目名称3
                                          ,iv_data_value3 => TO_CHAR(main_rec.dlv_date, 'YYYY/MM/DD') --データの値3
                                          );
          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_continue
                                              , cv_tkn_error_message
                                              , lv_message_data
                                              , cv_tkn_key_data
                                              , gv_key_info
                                              );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => ov_errmsg --エラーメッセージ
                           );
          ov_errmsg := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => ov_errmsg --エラーメッセージ
                           );
          ov_retcode := cv_status_warn;
          gn_warn_cnt := gn_warn_cnt + 1;
          lb_data_skip := TRUE;
        WHEN data_skip_expt THEN
          -- データスキップ処理（何も処理しない）
          NULL;
      END;

      lb_new_customer := FALSE;
      main_rec_old := main_rec;
      FETCH main_cur INTO main_rec;
    END LOOP main_loop;
    CLOSE main_cur;

-- 2011/09/27 ADD Ver.1.10 End

-- 2011/09/27 DEL Ver.1.10 Start
--    FOR main_rec_d IN main_cur LOOP
--      BEGIN
--        main_rec := main_rec_d;
--        gn_main_loop_cnt := gn_main_loop_cnt + 1;
--
--
---- 2009/07/15 Ver.1.5 Add Start
--        --変数初期化
--          --売上数
--        gv_visit_time      := NULL;
--        gn_last_visit_days := 0;
--        gn_sales_qty_sum_1 := 0;
--        gn_sales_qty_sum_2 := 0;
--        gn_sales_qty_sum_3 := 0;
--        gn_total_amount_1  := 0;
--        gn_total_amount_2  := 0;
--        gn_total_amount_3  := 0;
---- 2009/07/15 Ver.1.5 Add End
--        ln_header_cnt := 0;
--        gd_dlv_date_1 := NULL;
--        gd_dlv_date_2 := NULL;
--        gd_dlv_date_3 := NULL;
--        <<loop_5>>
--        FOR header_rec2 IN header_cur LOOP
--          ln_header_cnt := ln_header_cnt + 1;
--          IF    ln_header_cnt = 1 THEN
--            gd_dlv_date_1 := header_rec2.dlv_date;
--          ELSIF ln_header_cnt = 2 THEN
--            gd_dlv_date_2 := header_rec2.dlv_date;
--          ELSIF ln_header_cnt = 3 THEN
--            gd_dlv_date_3 := header_rec2.dlv_date;
--          END IF;
--        END LOOP loop_5;

--        -- ==================================================
--        --A-3．ベンダ納品実績情報ヘッダテーブルデータ抽出
--        -- ==================================================
--        ln_header_cnt := 0;
---- 2009/07/15 Ver.1.5 Add Start
--        ln_deli_l_cnt := 0;
---- 2009/07/15 Ver.1.5 Add End
--        <<loop_2>>
--        FOR header_rec_d IN header_cur LOOP
--          header_rec := header_rec_d;
--          ln_header_cnt := ln_header_cnt + 1;
--          IF ln_header_cnt = 1 THEN
--          gn_target_cnt := gn_target_cnt + 1;
--            -- ==================================================
--            --A-4． 閾値抽出
--            -- ==================================================
--            proc_threshold(
--                                 lv_errbuf   -- エラー・メッセージ           --# 固定 #
--                                ,lv_retcode  -- リターン・コード             --# 固定 #
--                                ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--                                );
--            IF (lv_retcode <> cv_status_normal) THEN
--              RAISE tran_in_expt;
--            END IF;
---- 2009/07/24 Add Ver.1.6 Start
--            -- 閾値がNULLの場合、該当レコードをスキップ
--            IF ( gv_hot_stock_days IS NULL ) THEN
--              RAISE tran_in_expt;
--            END IF;
---- 2009/07/24 Add Ver.1.6 End
--            -- ==================================================
--            --A-5．ベンダコラムマスタデータ抽出
--            -- ==================================================
--            ln_column_cnt := 0;
--            <<loop_3>>
--            FOR column_rec_d IN column_cur LOOP
---- 2009/07/15 Ver.1.5 Mod Start
--              --納品実績情報明細関連の変数の初期化
--              gn_monthly_sales           := NULL;
--              gn_sales_days              := NULL;
--              gn_inventory_quantity_sum  := NULL;
--              gn_hot_warn_qty            := NULL;
--              gn_sales_qty_1             := NULL;
--              gn_sales_qty_2             := NULL;
--              gn_sales_qty_3             := NULL;
--              gn_replacement_rate        := NULL;
---- 2009/07/15 Ver.1.5 Mod End
--              column_rec := column_rec_d;
---- 2011/04/14 Ver.1.9 S.Ochiai ADD Start
--              gv_item_code     := column_rec.item_code;
--              gv_hot_cold_type := column_rec.hot_cold;
---- 2011/04/14 Ver.1.9 S.Ochiai ADD End
--              ln_column_cnt := ln_column_cnt + 1;
--              -- ==================================================
--              --A-6．ベンダ納品実績情報明細テーブルデータ抽出
--              -- ==================================================
--              ln_line_count := 0;                   --A-8．売上数サマリ処理用　初期化
--              <<loop_4>>
--              FOR line_rec_d IN line_cur LOOP
--                line_rec := line_rec_d;
--
--                gn_tran_count := gn_tran_count + 1;
--                ln_line_count := ln_line_count + 1; --A-8．売上数サマリ処理用　カウント
---- 2011/04/14 Ver.1.9 S.Ochiai DEL Start
----                -- ==================================================
----                --A-7．コラムの最新品目抽出
----                -- ==================================================
----                proc_new_item_select(
----                                     lv_errbuf   -- エラー・メッセージ           --# 固定 #
----                                    ,lv_retcode  -- リターン・コード             --# 固定 #
----                                    ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
----                                    );
----                IF (lv_retcode <> cv_status_normal) THEN
----                  RAISE tran_in_expt;
----                END IF;
----
---- 2011/04/14 Ver.1.9 S.Ochiai DEL End
--                -- ==================================================
--                --A-8．売上数サマリ (と明細売上数の設定)
--                -- ==================================================
--                IF    ln_line_count = 1 THEN
--                  gn_sales_qty_sum_1 := gn_sales_qty_sum_1 + line_rec.sum_sales_qty;
--                  gn_sales_qty_1     := line_rec.sum_sales_qty;
--                ELSIF ln_line_count = 2 THEN
--                  gn_sales_qty_sum_2 := gn_sales_qty_sum_2 + line_rec.sum_sales_qty;
--                  gn_sales_qty_2     := line_rec.sum_sales_qty;
--                ELSIF ln_line_count = 3 THEN
--                  gn_sales_qty_sum_3 := gn_sales_qty_sum_3 + line_rec.sum_sales_qty;
--                  gn_sales_qty_3     := line_rec.sum_sales_qty;
--                END IF;
--
--              END LOOP loop_4;
--
--              IF ln_line_count = 0 THEN
--                gv_column_no := column_rec.column_no;
--                RAISE line_no_data_expt;
--              END IF;
--
--        -- ==================================================
--        --A-9．月販数、基準在庫数導出
--        -- ==================================================
--              proc_month_qty(
--                                   lv_errbuf   -- エラー・メッセージ           --# 固定 #
--                                  ,lv_retcode  -- リターン・コード             --# 固定 #
--                                  ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--                                  );
--              IF (lv_retcode <> cv_status_normal) THEN
--                RAISE tran_in_expt;
--              END IF;
--
--        -- ==================================================
--        --A-10．販売日数導出
--        -- ==================================================
--              proc_sales_days(
--                                   lv_errbuf   -- エラー・メッセージ           --# 固定 #
--                                  ,lv_retcode  -- リターン・コード             --# 固定 #
--                                  ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--                                  );
--              IF (lv_retcode <> cv_status_normal) THEN
--                RAISE tran_in_expt;
--              END IF;
--
--        -- ==================================================
--        --A-11．ホット警告残数導出
--        -- ==================================================
--              IF gv_hot_cold_type = cv_hot_type THEN
--                proc_hot_warn(
--                                     lv_errbuf   -- エラー・メッセージ           --# 固定 #
--                                    ,lv_retcode  -- リターン・コード             --# 固定 #
--                                    ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--                                    );
--                IF (lv_retcode <> cv_status_normal) THEN
--                  RAISE tran_in_expt;
--                END IF;
---- 2009/07/15 Ver.1.5 Mod Start
--              ELSE
--                gn_hot_warn_qty := 0;
---- 2009/07/15 Ver.1.5 Mod End
--              END IF;
--
--        -- ==================================================
--        --A-12．補充率導出
--        -- ==================================================
--        --補充率　＝　A-9で抽出した月販数　÷　A-9で抽出した基準在庫数　×　100(端数切捨）
--              IF gn_inventory_quantity_sum > 0 THEN
--                gn_replacement_rate := TRUNC(gn_monthly_sales / gn_inventory_quantity_sum * 100);
---- 2009/10/14 Ver.1.8 Add Start
--                IF (LENGTHB(gn_replacement_rate) > cn_max_length_rep_rate) THEN
--                  -- 補充率が３桁を超えた場合、固定値999を設定
--                  gn_replacement_rate := cn_max_replacement_rate;
--                  --
--                  lv_message_data := xxccp_common_pkg.get_msg(
--                                        iv_application  => cv_application
--                                       ,iv_name         => cv_msg_rep_rate_over
--                                       ,iv_token_name1  => cv_tkn_max_value
--                                       ,iv_token_value1 => cn_max_replacement_rate
--                                       ,iv_token_name2  => cv_tkn_customer_code
--                                       ,iv_token_value2 => main_rec_d.account_number
--                                       ,iv_token_name3  => cv_tkn_col_no
--                                       ,iv_token_value3 => column_rec_d.column_no
--                                     );
--                  --
--                  fnd_file.put_line(
--                     which => fnd_file.log
--                    ,buff  => lv_message_data
--                  );
--                  --
--                END IF;
--                --
---- 2009/10/14 Ver.1.8 Add End
--              END IF;
--
---- 2009/07/15 Ver.1.5 Mod Start
----        -- ==================================================
----        --A-13.  納品実績情報明細ファイル出力
----        -- ==================================================
----              proc_deli_l_file_out(
----                                   lv_errbuf   -- エラー・メッセージ           --# 固定 #
----                                  ,lv_retcode  -- リターン・コード             --# 固定 #
----                                  ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
----                                  );
----              IF (lv_retcode <> cv_status_normal) THEN
----                RAISE tran_in_expt;
----              END IF;
--        -- ==================================================
--        --明細出力用変数の格納
--        -- ==================================================
--              ln_deli_l_cnt := ln_deli_l_cnt + 1;
--              gt_deli_l_tab(ln_deli_l_cnt).account_number         := main_rec.account_number;   -- 顧客コード
--              gt_deli_l_tab(ln_deli_l_cnt).column_no              := column_rec.column_no;      -- A-5で抽出したコラムNo
--              gt_deli_l_tab(ln_deli_l_cnt).monthly_sales          := gn_monthly_sales;          -- A-9で抽出した月販数
--              gt_deli_l_tab(ln_deli_l_cnt).sales_days             := gn_sales_days;             -- A-10で抽出した販売日数
--              gt_deli_l_tab(ln_deli_l_cnt).inventory_quantity_sum := gn_inventory_quantity_sum; -- A-9で抽出した基準在庫数
--              gt_deli_l_tab(ln_deli_l_cnt).hot_warn_qty           := gn_hot_warn_qty;           -- A-11で抽出したホット警告残数
--              gt_deli_l_tab(ln_deli_l_cnt).sales_qty_1            := gn_sales_qty_1;            -- A-6で抽出した1件目の売上数
--              gt_deli_l_tab(ln_deli_l_cnt).sales_qty_2            := gn_sales_qty_2;            -- A-6で抽出した2件目の売上数
--              gt_deli_l_tab(ln_deli_l_cnt).sales_qty_3            := gn_sales_qty_3;            -- A-6で抽出した3件目の売上数
--              gt_deli_l_tab(ln_deli_l_cnt).replacement_rate       := gn_replacement_rate;       -- A-12で抽出した補充率
---- 2009/07/15 Ver.1.5 Mod End

--            END LOOP loop_3;
--
--            IF ln_column_cnt = 0 THEN
--              RAISE column_no_data_expt;
--            END IF;
--
--        -- ==================================================
--        --ヘッダ出力用変数の格納
--        -- ==================================================
--            gd_dlv_date_1     := header_rec.dlv_date;     --A-3で抽出した1件目の納品日
--            gn_total_amount_1 := header_rec.total_amount; --A-3で抽出した1件目の合計金額
--            gv_visit_time     := header_rec.visit_time;   --前回訪問時刻
--          ELSIF ln_header_cnt = 2 THEN --ヘッダ2件目
--            gd_dlv_date_2     := header_rec.dlv_date;         --A-3で抽出した2件目の納品日
--            gn_total_amount_2 := header_rec.total_amount; --A-3で抽出した2件目の合計金額
--          ELSIF ln_header_cnt = 3 THEN --ヘッダ3件目
--            gd_dlv_date_3     := header_rec.dlv_date;         --A-3で抽出した3件目の納品日
--            gn_total_amount_3 := header_rec.total_amount; --A-3で抽出した3件目の合計金額
--          END IF;
--
--        END LOOP loop_2;
--        IF ln_header_cnt > 0 THEN
---- 2009/07/15 Ver.1.5 Add Start
----
--          -- ==================================================
--          --A-13.  納品実績情報明細ファイル出力
--          -- ==================================================
--          << output_deli_l_loop >>
--          FOR ln_deli_l_idx in 1..ln_deli_l_cnt LOOP
--            gn_deli_l_cnt := ln_deli_l_idx;
--            proc_deli_l_file_out(
--                                 lv_errbuf   -- エラー・メッセージ           --# 固定 #
--                                ,lv_retcode  -- リターン・コード             --# 固定 #
--                                ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--                                );
--            IF (lv_retcode <> cv_status_normal) THEN
--              RAISE tran_in_expt;
--            END IF;
--          END LOOP output_deli_l_loop;
---- 2009/07/15 Ver.1.5 Add End
--
--          -- ==================================================
--          --A-14．前回訪問日数導出
--          -- ==================================================
--          --初期処理で取得した基準日　―　A-3で抽出した（顧客内で）1件の納品日
--          gn_last_visit_days := gd_standard_date - gd_dlv_date_1;
--
--          -- ==================================================
--          --A-15． 納品実績情報ヘッダファイル出力
--          -- ==================================================
--          proc_deli_h_file_out(
--                               lv_errbuf   -- エラー・メッセージ           --# 固定 #
--                              ,lv_retcode  -- リターン・コード             --# 固定 #
--                              ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--                              );
--          IF (lv_retcode <> cv_status_normal) THEN
--            RAISE tran_in_expt;
--          ELSE
--            gn_normal_cnt := gn_normal_cnt + 1;
--          END IF;
--        END IF;
--
--      EXCEPTION
--        WHEN column_no_data_expt THEN
--          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;

--          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
--                                          ,ov_retcode     => lv_retcode                 --リターン・コード
--                                          ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
--                                          ,ov_key_info    => gv_key_info                --キー情報
--                                          ,iv_item_name1  => gv_msg_tkn_cust_account_id --項目名称1
--                                          ,iv_data_value1 => main_rec.cust_account_id   --データの値1
--                                          );
--
--          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
--                                              , cv_msg_select_err
--                                              , cv_tkn_table_name
--                                              , gv_msg_tkn_vd_column_mst
--                                              , cv_tkn_key_data
--                                              , gv_key_info
--                                              );
--          FND_FILE.PUT_LINE(
--                            which  => FND_FILE.OUTPUT
--                           ,buff   => ov_errmsg --エラーメッセージ
--                           );
--          FND_FILE.PUT_LINE(
--                            which  => FND_FILE.LOG
--                           ,buff   => lv_errbuf --エラーメッセージ
--                           );
--          ov_errmsg := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
--          FND_FILE.PUT_LINE(
--                            which  => FND_FILE.LOG
--                           ,buff   => ov_errmsg --エラーメッセージ
--                           );
--          ov_retcode := cv_status_warn;
--          gn_warn_cnt := gn_warn_cnt + 1;
--        WHEN line_no_data_expt THEN
--          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;

--          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  --エラー・メッセージ
--                                          ,ov_retcode     => lv_retcode                 --リターン・コード
--                                          ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
--                                          ,ov_key_info    => gv_key_info                --キー情報
--                                          ,iv_item_name1  => gv_msg_tkn_cust_code       --項目名称1
--                                          ,iv_data_value1 => main_rec.account_number    --データの値1
--                                          ,iv_item_name2  => gv_msg_tkn_column_no       --項目名称2
--                                          ,iv_data_value2 => gv_column_no               --データの値2
--                                          ,iv_item_name3  => gv_msg_tkn_dlv_date        --項目名称3
--                                          ,iv_data_value3 => TO_CHAR(gd_dlv_date_1,'YYYYMMDD')  || ',' ||
--                                                             TO_CHAR(gd_dlv_date_2,'YYYYMMDD')  || ',' ||
--                                                             TO_CHAR(gd_dlv_date_3,'YYYYMMDD')     --データの値3
--                                          );
--
--          ov_errmsg := xxccp_common_pkg.get_msg(cv_application
--                                              , cv_msg_select_err
--                                              , cv_tkn_table_name
--                                              , gv_msg_tkn_vd_deliv_l
--                                              , cv_tkn_key_data
--                                              , gv_key_info
--                                              );
--          FND_FILE.PUT_LINE(
--                            which  => FND_FILE.OUTPUT
--                           ,buff   => ov_errmsg --エラーメッセージ
--                           );
--          FND_FILE.PUT_LINE(
--                            which  => FND_FILE.LOG
--                           ,buff   => lv_errbuf --エラーメッセージ
--                           );
--          ov_errmsg := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
--          FND_FILE.PUT_LINE(
--                            which  => FND_FILE.LOG
--                           ,buff   => ov_errmsg --エラーメッセージ
--                           );
--          ov_retcode := cv_status_warn;
--          gn_warn_cnt := gn_warn_cnt + 1;
--        WHEN tran_in_expt THEN
--          ov_retcode := cv_status_warn;
--          gn_warn_cnt := gn_warn_cnt + 1;
--      END;
--    END LOOP main_loop;
-- 2011/09/27 DEL Ver.1.10 End

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
-- 2011/09/27 MOD Ver.1.10 Start
--    -- A-2．顧客マスタデータ抽出
    -- A-17．ベンダ納品実績データ抽出
-- 2011/09/27 MOD Ver.1.10 End
    -- ===============================
    proc_main_loop(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    ov_retcode := lv_retcode;
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;

    --出力件数が0件の場合は警告とする。
    IF gn_normal_cnt = 0 THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_msg_no_data_tran
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_msg_no_data_tran
      );
      ov_retcode := cv_status_warn;
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
    IF lv_retcode = cv_status_normal THEN
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
    -- A-15．終了処理
    -- ===============================================
    --ファイルのクローズ
    UTL_FILE.FCLOSE(gt_deli_h_handle);
    UTL_FILE.FCLOSE(gt_deli_l_handle);

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
END XXCOS003A04C;
/
