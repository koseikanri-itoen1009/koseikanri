CREATE OR REPLACE PACKAGE BODY XXCOI006A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A03C(body)
 * Description      : 月次在庫受払（日次）を元に、月次在庫受払表を作成します。
 * MD.050           : 月次在庫受払表作成<MD050_COI_006_A03>
 * Version          : 1.17
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  ins_month_tran_data    受払情報確定処理                     (A-17, A-18)
 *  ins_inv_data           月首在庫、棚卸確定処理               (A-15, A-16)
 *  close_process          終了処理                             (A-14)
 *  ins_month_balance      月首残高出力                         (A-13)
 *  ins_daily_invcntl      棚卸管理出力（当日取引データ）       (A-11)
 *  ins_daily_data         月次在庫受払出力（当日取引データ）   (A-10)
 *  upd_inv_control        棚卸管理出力（棚卸結果データ）       (A-8)
 *  ins_inv_result         月次在庫受払出力（棚卸結果データ）   (A-7)
 *  ins_inv_control        棚卸管理出力（日次データ）           (A-5)
 *  ins_invrcp_daily       月次在庫受払出力（日次データ）       (A-4)
 *  del_invrcp_monthly     作成済み月次在庫受払データ削除       (A-3)
 *  init                   初期処理                             (A-1)
 *  submain                メイン処理プロシージャ
 *                         月次在庫受払（日次）情報取得         (A-2)
 *                         棚卸結果情報抽出                     (A-6)
 *                         当日取引データ取得                   (A-9)
 *                         前月棚卸結果抽出                     (A-12)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/12    1.0   H.Sasaki         初版作成
 *  2009/02/17    1.1   H.Sasaki         [障害COI_007]棚卸管理からの月次在庫受払の作成条件追加
 *  2009/02/17    1.2   H.Sasaki         [障害COI_008]資材取引からの月次在庫受払の作成条件追加
 *  2009/02/18    1.3   H.Sasaki         [障害COI_016]棚卸管理の抽出方法変更
 *  2009/02/19    1.4   H.Sasaki         [障害COI_020]棚卸管理新規作成時の条件を追加
 *  2009/03/17    1.5   H.Sasaki         [T1_0076]月首棚卸高算出の実行条件変更
 *  2009/03/30    1.6   H.Sasaki         [T1_0195]棚卸情報登録時の拠点コード変換条件変更
 *  2009/04/27    1.7   H.Sasaki         [T1_0553]年月日の設定値変更
 *  2009/05/11    1.8   T.Nakamura       [T1_0839]拠点間移動オーダーを受払データ作成対象に追加
 *  2009/05/14    1.9   H.Sasaki         [T1_0840][T1_0842]倉替数量の集計条件変更
 *  2009/05/21    1.10  H.Sasaki         [T1_1123]棚卸情報検索時に日付条件を追加
 *  2009/06/04    1.11  H.Sasaki         [T1_1324]当日取引データにて消化VDを対象外とする
 *  2009/07/21    1.12  H.Sasaki         [0000768]PT対応
 *  2009/07/30    1.13  N.Abe            [0000638]数量の取得項目修正
 *  2009/08/20    1.14  H.Sasaki         [0001003]夜間強制確定処理の分割（PT対応）
 *  2010/01/05    1.15  H.Sasaki         [E_本稼動_00850]日次データ取得SQLの分割（PT対応）
 *  2010/04/09    1.16  N.Abe            [E_本稼動_02219]資材取引取得SQLの日付指定の修正
 *  2010/12/14    1.17  H.Sasaki         [E_本稼動_05549]PT対応（受払取得元を累計に変更）
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
  lock_error_expt           EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI006A03C'; -- パッケージ名
  -- 棚卸区分（1:月中  2:月末）
  cv_inv_kbn_1          CONSTANT VARCHAR2(1)  :=  '1';
  cv_inv_kbn_2          CONSTANT VARCHAR2(1)  :=  '2';
  -- 棚卸ステータス（1:取込済  2:受払作成）
  cv_invsts_1           CONSTANT VARCHAR2(1)  :=  '1';
  cv_invsts_2           CONSTANT VARCHAR2(1)  :=  '2';
  -- 保管場所区分（1:倉庫  2:営業車  3:預け先  4:専門店）
  cv_subinv_1           CONSTANT VARCHAR2(1)  :=  '1';
  cv_subinv_2           CONSTANT VARCHAR2(1)  :=  '2';
  cv_subinv_3           CONSTANT VARCHAR2(1)  :=  '3';
  cv_subinv_4           CONSTANT VARCHAR2(1)  :=  '4';
  -- 良品区分（0:良品  1:不良品）
  cv_quality_0          CONSTANT VARCHAR2(1)  :=  '0';
  cv_quality_1          CONSTANT VARCHAR2(1)  :=  '1';
  -- 保管場所区分
  cv_inv_type_5         CONSTANT VARCHAR2(1)  :=  '5';
  cv_inv_type_8         CONSTANT VARCHAR2(1)  :=  '8';
  -- 顧客区分（1:拠点）
  cv_cust_cls_1         CONSTANT VARCHAR2(1)  :=  '1';
  -- 日付型
  cv_date               CONSTANT VARCHAR2(8)  :=  'YYYYMMDD';
  cv_month              CONSTANT VARCHAR2(6)  :=  'YYYYMM';
  -- メッセージ関連
  cv_short_name         CONSTANT VARCHAR2(30) :=  'XXCOI';
  cv_msg_xxcoi1_00005   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00005';
  cv_msg_xxcoi1_00006   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00006';
  cv_msg_xxcoi1_00011   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00011';
  cv_msg_xxcoi1_10144   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10144';
  cv_msg_xxcoi1_10145   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10145';
  cv_msg_xxcoi1_10127   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10127';
  cv_msg_xxcoi1_10233   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10233';
  cv_msg_xxcoi1_10285   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10285';
  cv_msg_xxcoi1_10293   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10293';
-- == 2010/12/14 V1.17 Added START ===============================================================
  cv_msg_xxcoi1_10428   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10428';
-- == 2010/12/14 V1.17 Added END   ===============================================================
  cv_token_10233_1      CONSTANT VARCHAR2(30) :=  'INV_KBN';
  cv_token_10233_2      CONSTANT VARCHAR2(30) :=  'BASE_CODE';
  cv_token_10233_3      CONSTANT VARCHAR2(30) :=  'STARTUP_FLG';
  cv_token_00005_1      CONSTANT VARCHAR2(30) :=  'PRO_TOK';
  cv_token_00006_1      CONSTANT VARCHAR2(30) :=  'ORG_CODE_TOK';
  -- 受払集計キー（取引タイプ）
  cv_trans_type_010     CONSTANT VARCHAR2(3) :=  '10';        -- 売上出庫
  cv_trans_type_020     CONSTANT VARCHAR2(3) :=  '20';        -- 売上出庫振戻
  cv_trans_type_030     CONSTANT VARCHAR2(3) :=  '30';        -- 返品
  cv_trans_type_040     CONSTANT VARCHAR2(3) :=  '40';        -- 返品振戻
  cv_trans_type_050     CONSTANT VARCHAR2(3) :=  '50';        -- 入出庫
  cv_trans_type_060     CONSTANT VARCHAR2(3) :=  '60';        -- 倉替
  cv_trans_type_070     CONSTANT VARCHAR2(3) :=  '70';        -- 商品振替（旧商品）
  cv_trans_type_080     CONSTANT VARCHAR2(3) :=  '80';        -- 商品振替（新商品）
  cv_trans_type_090     CONSTANT VARCHAR2(3) :=  '90';        -- 見本出庫
  cv_trans_type_100     CONSTANT VARCHAR2(3) :=  '100';       -- 見本出庫振戻
  cv_trans_type_110     CONSTANT VARCHAR2(3) :=  '110';       -- 顧客見本出庫
  cv_trans_type_120     CONSTANT VARCHAR2(3) :=  '120';       -- 顧客見本出庫振戻
  cv_trans_type_130     CONSTANT VARCHAR2(3) :=  '130';       -- 顧客協賛見本出庫
  cv_trans_type_140     CONSTANT VARCHAR2(3) :=  '140';       -- 顧客協賛見本出庫振戻
  cv_trans_type_150     CONSTANT VARCHAR2(3) :=  '150';       -- 消化VD補充
  cv_trans_type_160     CONSTANT VARCHAR2(3) :=  '160';       -- 基準在庫変更
  cv_trans_type_170     CONSTANT VARCHAR2(3) :=  '170';       -- 工場返品
  cv_trans_type_180     CONSTANT VARCHAR2(3) :=  '180';       -- 工場返品振戻
  cv_trans_type_190     CONSTANT VARCHAR2(3) :=  '190';       -- 工場倉替
  cv_trans_type_200     CONSTANT VARCHAR2(3) :=  '200';       -- 工場倉替振戻
  cv_trans_type_210     CONSTANT VARCHAR2(3) :=  '210';       -- 廃却
  cv_trans_type_220     CONSTANT VARCHAR2(3) :=  '220';       -- 廃却振戻
  cv_trans_type_230     CONSTANT VARCHAR2(3) :=  '230';       -- 工場入庫
  cv_trans_type_240     CONSTANT VARCHAR2(3) :=  '240';       -- 工場入庫振戻
  cv_trans_type_250     CONSTANT VARCHAR2(3) :=  '250';       -- 顧客広告宣伝費A自社商品
  cv_trans_type_260     CONSTANT VARCHAR2(3) :=  '260';       -- 顧客広告宣伝費A自社商品振戻
  cv_trans_type_270     CONSTANT VARCHAR2(3) :=  '270';       -- 棚卸減耗益
  cv_trans_type_280     CONSTANT VARCHAR2(3) :=  '280';       -- 棚卸減耗損
  cv_trans_type_290     CONSTANT VARCHAR2(3) :=  '290';       -- 移動オーダー移動
  -- その他
  cv_exec_1             CONSTANT VARCHAR2(1)  :=  '1';        -- 起動フラグ：コンカレント起動
  cv_exec_2             CONSTANT VARCHAR2(1)  :=  '2';        -- 起動フラグ：夜間強制確定（棚卸情報取込）
-- == 2009/08/20 V1.14 Added START ===============================================================
  cv_exec_3             CONSTANT VARCHAR2(1)  :=  '3';        -- 起動フラグ：夜間強制確定（日次情報取込）
-- == 2009/08/20 V1.14 Added END   ===============================================================
  cv_control_base_1     CONSTANT VARCHAR2(1)  :=  '1';        -- 拠点判定フラグ（1:管理元拠点）
  cv_status_a           CONSTANT VARCHAR2(1)  :=  'A';        -- 顧客マスタ．ステータス
  cv_yes                CONSTANT VARCHAR2(1)  :=  'Y';
  cv_space              CONSTANT VARCHAR2(1)  :=  ' ';
  cv_prf_name_orgcd     CONSTANT VARCHAR2(30) :=  'XXCOI1_ORGANIZATION_CODE';   -- プロファイル名（在庫組織コード）
  cv_pgsname_a09c       CONSTANT VARCHAR2(30) :=  'XXCOI006A09C';
  cv_on                 CONSTANT VARCHAR2(1)  :=  '1';        -- 月次在庫受払表作成済み
  cv_off                CONSTANT VARCHAR2(1)  :=  '0';        -- 月次在庫受払表未作成
-- == 2009/06/04 V1.11 Added START ===============================================================
  cv_subinv_class_7     CONSTANT VARCHAR2(1)  :=  '7';        -- 保管場所分類（7:消化VD）
-- == 2009/06/04 V1.11 Added END   ===============================================================
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE acct_num_type IS TABLE OF hz_cust_accounts.account_number%TYPE INDEX BY BINARY_INTEGER;
  gt_f_account_number   acct_num_type;      -- 処理対象拠点
  TYPE quantity_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  gt_quantity           quantity_type;      -- 取引タイプ別数量
  TYPE daily_data    IS TABLE OF xxcoi_inv_reception_monthly%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_daily_data         daily_data;         -- 当日データ
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 起動パラメータ
  gv_param_inventory_kbn      VARCHAR2(1);        -- 棚卸区分
  gv_param_base_code          VARCHAR2(4);        -- 拠点
  gv_param_exec_flag          VARCHAR2(1);        -- 起動フラグ
  -- 初期処理設定値
  gd_f_process_date           DATE;               -- 業務処理日付
  gv_f_organization_code      VARCHAR2(10);       -- 在庫組織コード
  gn_f_organization_id        NUMBER;             -- 在庫組織ID
  gv_f_inv_acct_period        VARCHAR2(6);        -- 在庫会計期間（年月 YYYYMM）
  gn_f_last_transaction_id    NUMBER;             -- 処理済取引ID
  gd_f_last_cooperation_date  DATE;               -- 処理日
  gn_f_max_transaction_id     NUMBER;             -- 最大取引ID
  -- その他変数
  gt_save_1_inv_seq           xxcoi_inv_control.inventory_seq%TYPE;                 -- 棚卸SEQ
  gt_save_1_base_code         xxcoi_inv_reception_daily.base_code%TYPE;             -- 拠点コード
  gt_save_1_subinv_code       xxcoi_inv_reception_daily.subinventory_code%TYPE;     -- 保管場所
  gt_save_2_inv_seq           xxcoi_inv_control.inventory_seq%TYPE;                 -- 棚卸SEQ
  gt_save_2_base_code         xxcoi_inv_control.base_code%TYPE;                     -- 拠点コード
  gt_save_2_subinv_code       xxcoi_inv_control.subinventory_code%TYPE;             -- 保管場所
  gt_save_3_inv_seq           xxcoi_inv_reception_monthly.inv_seq%TYPE;             -- 棚卸SEQ
  gt_save_3_inv_seq_sub       xxcoi_inv_reception_monthly.inv_seq%TYPE;             -- 棚卸SEQ
  gt_save_3_base_code         mtl_secondary_inventories.attribute7%TYPE;            -- 拠点コード
  gt_save_3_inv_code          mtl_material_transactions.subinventory_code%TYPE;     -- 保管場所コード
  gt_save_3_item_id           mtl_material_transactions.inventory_item_id%TYPE;     -- 品目ID
  gt_save_3_inv_type          mtl_secondary_inventories.attribute1%TYPE;            -- 保管場所タイプ
  gn_data_cnt                 NUMBER;                                               -- 当日データ保持用カウンタ
  gv_create_flag              VARCHAR2(1);                                          -- 月次在庫受払表作成フラグ
--
  -- ===============================
  -- カーソル定義
  -- ===============================
  -- A-2.月次在庫受払（日次）情報取得(【起動パラメータ】棚卸区分:1)
  CURSOR  invrcp_daily_1_cur(
            iv_base_code        IN  VARCHAR2        -- 拠点コード
          )
  IS
    SELECT
      xird.base_code                      base_code                 -- 拠点コード
     ,xird.organization_id                organization_id           -- 組織ID
     ,xird.subinventory_code              subinventory_code         -- 保管場所
     ,xird.subinventory_type              subinventory_type         -- 保管場所区分
     ,xird.inventory_item_id              inventory_item_id         -- 品目ID
     ,MAX(xird.operation_cost)            operation_cost            -- 営業原価
     ,MAX(xird.standard_cost)             standard_cost             -- 標準原価
     ,SUM(xird.sales_shipped)             sales_shipped             -- 売上出庫
     ,SUM(xird.sales_shipped_b)           sales_shipped_b           -- 売上出庫振戻
     ,SUM(xird.return_goods)              return_goods              -- 返品
     ,SUM(xird.return_goods_b)            return_goods_b            -- 返品振戻
     ,SUM(xird.warehouse_ship)            warehouse_ship            -- 倉庫へ返庫
     ,SUM(xird.truck_ship)                truck_ship                -- 営業車へ出庫
     ,SUM(xird.others_ship)               others_ship               -- 入出庫＿その他出庫
     ,SUM(xird.warehouse_stock)           warehouse_stock           -- 倉庫より入庫
     ,SUM(xird.truck_stock)               truck_stock               -- 営業車より入庫
     ,SUM(xird.others_stock)              others_stock              -- 入出庫＿その他入庫
     ,SUM(xird.change_stock)              change_stock              -- 倉替入庫
     ,SUM(xird.change_ship)               change_ship               -- 倉替出庫
     ,SUM(xird.goods_transfer_old)        goods_transfer_old        -- 商品振替（旧商品）
     ,SUM(xird.goods_transfer_new)        goods_transfer_new        -- 商品振替（新商品）
     ,SUM(xird.sample_quantity)           sample_quantity           -- 見本出庫
     ,SUM(xird.sample_quantity_b)         sample_quantity_b         -- 見本出庫振戻
     ,SUM(xird.customer_sample_ship)      customer_sample_ship      -- 顧客見本出庫
     ,SUM(xird.customer_sample_ship_b)    customer_sample_ship_b    -- 顧客見本出庫振戻
     ,SUM(xird.customer_support_ss)       customer_support_ss       -- 顧客協賛見本出庫
     ,SUM(xird.customer_support_ss_b)     customer_support_ss_b     -- 顧客協賛見本出庫振戻
     ,SUM(xird.vd_supplement_stock)       vd_supplement_stock       -- 消化VD補充入庫
     ,SUM(xird.vd_supplement_ship)        vd_supplement_ship        -- 消化VD補充出庫
     ,SUM(xird.inventory_change_in)       inventory_change_in       -- 基準在庫変更入庫
     ,SUM(xird.inventory_change_out)      inventory_change_out      -- 基準在庫変更出庫
     ,SUM(xird.factory_return)            factory_return            -- 工場返品
     ,SUM(xird.factory_return_b)          factory_return_b          -- 工場返品振戻
     ,SUM(xird.factory_change)            factory_change            -- 工場倉替
     ,SUM(xird.factory_change_b)          factory_change_b          -- 工場倉替振戻
     ,SUM(xird.removed_goods)             removed_goods             -- 廃却
     ,SUM(xird.removed_goods_b)           removed_goods_b           -- 廃却振戻
     ,SUM(xird.factory_stock)             factory_stock             -- 工場入庫
     ,SUM(xird.factory_stock_b)           factory_stock_b           -- 工場入庫振戻
     ,SUM(xird.ccm_sample_ship)           ccm_sample_ship           -- 顧客広告宣伝費A自社商品
     ,SUM(xird.ccm_sample_ship_b)         ccm_sample_ship_b         -- 顧客広告宣伝費A自社商品振戻
     ,SUM(xird.wear_decrease)             wear_decrease             -- 棚卸減耗増
     ,SUM(xird.wear_increase)             wear_increase             -- 棚卸減耗減
     ,SUM(xird.selfbase_ship)             selfbase_ship             -- 保管場所移動＿自拠点出庫
     ,SUM(xird.selfbase_stock)            selfbase_stock            -- 保管場所移動＿自拠点入庫
     ,MAX(xic.inventory_seq)              inventory_seq             -- 棚卸SEQ
-- == 2009/04/27 V1.7 Added START ===============================================================
     ,MAX(xird.practice_date)             practice_date
     ,MAX(xic.inventory_date)             inventory_date
-- == 2009/04/27 V1.7 Added END   ===============================================================
    FROM    xxcoi_inv_reception_daily   xird                        -- 月次在庫受払表（日次）
           ,(SELECT   sub_msi.attribute7            base_code
                     ,sub_xic.subinventory_code     subinventory_code
                     ,MAX(sub_xic.inventory_date)   inventory_date
                     ,MAX(sub_xic.inventory_seq)    inventory_seq
             FROM     xxcoi_inv_control           sub_xic
                     ,mtl_secondary_inventories   sub_msi
             WHERE    sub_xic.inventory_kbn     =   gv_param_inventory_kbn
             AND      sub_xic.inventory_status  =   cv_invsts_1
             AND      sub_xic.subinventory_code =   sub_msi.secondary_inventory_name
             AND      sub_msi.attribute7        =   iv_base_code
-- == 2009/05/21 V1.10 Added START ===============================================================
             AND      sub_xic.inventory_date   >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
             AND      sub_xic.inventory_date   <=   gd_f_process_date
-- == 2009/05/21 V1.10 Added END   ===============================================================
             GROUP BY sub_msi.attribute7
                     ,sub_xic.subinventory_code
            )                           xic
    WHERE   xird.base_code          =   xic.base_code
    AND     xird.subinventory_code  =   xic.subinventory_code
    AND     xird.organization_id    =   gn_f_organization_id
    AND     xird.practice_date     >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
    AND     xird.practice_date     <=   xic.inventory_date
    GROUP BY
            xird.base_code
           ,xird.organization_id
           ,xird.subinventory_code
           ,xird.inventory_item_id
           ,xird.subinventory_type
    ORDER BY
            xird.base_code
           ,xird.subinventory_code;
  --
-- == 2009/07/21 V1.12 Modified START ===============================================================
  -- A-2.月次在庫受払（日次）情報取得(【起動パラメータ】棚卸区分:2)
  CURSOR invrcp_daily_2_cur(
            iv_base_code        IN  VARCHAR2        -- 拠点コード
          )
  IS
--    SELECT
--      xird.base_code                      base_code                 -- 拠点コード
--     ,xird.organization_id                organization_id           -- 組織ID
--     ,xird.subinventory_code              subinventory_code         -- 保管場所
--     ,xird.subinventory_type              subinventory_type         -- 保管場所区分
--     ,xird.inventory_item_id              inventory_item_id         -- 品目ID
--     ,MAX(xird.operation_cost)            operation_cost            -- 営業原価
--     ,MAX(xird.standard_cost)             standard_cost             -- 標準原価
--     ,SUM(xird.sales_shipped)             sales_shipped             -- 売上出庫
--     ,SUM(xird.sales_shipped_b)           sales_shipped_b           -- 売上出庫振戻
--     ,SUM(xird.return_goods)              return_goods              -- 返品
--     ,SUM(xird.return_goods_b)            return_goods_b            -- 返品振戻
--     ,SUM(xird.warehouse_ship)            warehouse_ship            -- 倉庫へ返庫
--     ,SUM(xird.truck_ship)                truck_ship                -- 営業車へ出庫
--     ,SUM(xird.others_ship)               others_ship               -- 入出庫＿その他出庫
--     ,SUM(xird.warehouse_stock)           warehouse_stock           -- 倉庫より入庫
--     ,SUM(xird.truck_stock)               truck_stock               -- 営業車より入庫
--     ,SUM(xird.others_stock)              others_stock              -- 入出庫＿その他入庫
--     ,SUM(xird.change_stock)              change_stock              -- 倉替入庫
--     ,SUM(xird.change_ship)               change_ship               -- 倉替出庫
--     ,SUM(xird.goods_transfer_old)        goods_transfer_old        -- 商品振替（旧商品）
--     ,SUM(xird.goods_transfer_new)        goods_transfer_new        -- 商品振替（新商品）
--     ,SUM(xird.sample_quantity)           sample_quantity           -- 見本出庫
--     ,SUM(xird.sample_quantity_b)         sample_quantity_b         -- 見本出庫振戻
--     ,SUM(xird.customer_sample_ship)      customer_sample_ship      -- 顧客見本出庫
--     ,SUM(xird.customer_sample_ship_b)    customer_sample_ship_b    -- 顧客見本出庫振戻
--     ,SUM(xird.customer_support_ss)       customer_support_ss       -- 顧客協賛見本出庫
--     ,SUM(xird.customer_support_ss_b)     customer_support_ss_b     -- 顧客協賛見本出庫振戻
--     ,SUM(xird.vd_supplement_stock)       vd_supplement_stock       -- 消化VD補充入庫
--     ,SUM(xird.vd_supplement_ship)        vd_supplement_ship        -- 消化VD補充出庫
--     ,SUM(xird.inventory_change_in)       inventory_change_in       -- 基準在庫変更入庫
--     ,SUM(xird.inventory_change_out)      inventory_change_out      -- 基準在庫変更出庫
--     ,SUM(xird.factory_return)            factory_return            -- 工場返品
--     ,SUM(xird.factory_return_b)          factory_return_b          -- 工場返品振戻
--     ,SUM(xird.factory_change)            factory_change            -- 工場倉替
--     ,SUM(xird.factory_change_b)          factory_change_b          -- 工場倉替振戻
--     ,SUM(xird.removed_goods)             removed_goods             -- 廃却
--     ,SUM(xird.removed_goods_b)           removed_goods_b           -- 廃却振戻
--     ,SUM(xird.factory_stock)             factory_stock             -- 工場入庫
--     ,SUM(xird.factory_stock_b)           factory_stock_b           -- 工場入庫振戻
--     ,SUM(xird.ccm_sample_ship)           ccm_sample_ship           -- 顧客広告宣伝費A自社商品
--     ,SUM(xird.ccm_sample_ship_b)         ccm_sample_ship_b         -- 顧客広告宣伝費A自社商品振戻
--     ,SUM(xird.wear_decrease)             wear_decrease             -- 棚卸減耗増
--     ,SUM(xird.wear_increase)             wear_increase             -- 棚卸減耗減
--     ,SUM(xird.selfbase_ship)             selfbase_ship             -- 保管場所移動＿自拠点出庫
--     ,SUM(xird.selfbase_stock)            selfbase_stock            -- 保管場所移動＿自拠点入庫
--     ,MAX(xic.inventory_seq)              inventory_seq             -- 棚卸SEQ
---- == 2009/04/27 V1.7 Added START ===============================================================
--     ,MAX(xird.practice_date)             practice_date
--     ,MAX(xic.inventory_date)             inventory_date
---- == 2009/04/27 V1.7 Added END   ===============================================================
--    FROM    xxcoi_inv_reception_daily   xird                        -- 月次在庫受払表（日次）
--           ,(SELECT   sub_msi.attribute7                base_code
--                     ,sub_xic.subinventory_code         subinventory_code
--                     ,MAX(sub_xic.inventory_seq)        inventory_seq
--                     ,MAX(sub_xic.inventory_date)       inventory_date
--             FROM     xxcoi_inv_control           sub_xic
--                     ,mtl_secondary_inventories   sub_msi
--             WHERE    sub_xic.inventory_kbn     =   gv_param_inventory_kbn
--             AND      sub_xic.subinventory_code =   sub_msi.secondary_inventory_name
--             AND      ((iv_base_code IS NOT NULL AND sub_msi.attribute7 = iv_base_code)
--                       OR
--                       (iv_base_code IS NULL)
--                      )
---- == 2009/05/21 V1.10 Added START ===============================================================
--             AND      sub_xic.inventory_date   >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
--             AND      sub_xic.inventory_date   <=   LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month))
---- == 2009/05/21 V1.10 Added END   ===============================================================
--             GROUP BY  sub_msi.attribute7
--                      ,sub_xic.subinventory_code
--            )                           xic
--    WHERE   xird.base_code          =   xic.base_code(+)
--    AND     xird.subinventory_code  =   xic.subinventory_code(+)
--    AND     xird.organization_id    =   gn_f_organization_id
--    AND     ((iv_base_code IS NOT NULL AND xird.base_code = iv_base_code)
--             OR
--             (iv_base_code IS NULL)
--            )
--    AND     xird.practice_date     >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
--    AND     xird.practice_date     <=   LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month))
--    GROUP BY
--            xird.base_code
--           ,xird.organization_id
--           ,xird.subinventory_code
--           ,xird.inventory_item_id
--           ,xird.subinventory_type
--    ORDER BY
--            xird.base_code
--           ,xird.subinventory_code;
    --
    SELECT
      xird.base_code                      base_code                 -- 拠点コード
     ,xird.organization_id                organization_id           -- 組織ID
     ,xird.subinventory_code              subinventory_code         -- 保管場所
     ,xird.subinventory_type              subinventory_type         -- 保管場所区分
     ,xird.inventory_item_id              inventory_item_id         -- 品目ID
     ,MAX(xird.operation_cost)            operation_cost            -- 営業原価
     ,MAX(xird.standard_cost)             standard_cost             -- 標準原価
     ,SUM(xird.sales_shipped)             sales_shipped             -- 売上出庫
     ,SUM(xird.sales_shipped_b)           sales_shipped_b           -- 売上出庫振戻
     ,SUM(xird.return_goods)              return_goods              -- 返品
     ,SUM(xird.return_goods_b)            return_goods_b            -- 返品振戻
     ,SUM(xird.warehouse_ship)            warehouse_ship            -- 倉庫へ返庫
     ,SUM(xird.truck_ship)                truck_ship                -- 営業車へ出庫
     ,SUM(xird.others_ship)               others_ship               -- 入出庫＿その他出庫
     ,SUM(xird.warehouse_stock)           warehouse_stock           -- 倉庫より入庫
     ,SUM(xird.truck_stock)               truck_stock               -- 営業車より入庫
     ,SUM(xird.others_stock)              others_stock              -- 入出庫＿その他入庫
     ,SUM(xird.change_stock)              change_stock              -- 倉替入庫
     ,SUM(xird.change_ship)               change_ship               -- 倉替出庫
     ,SUM(xird.goods_transfer_old)        goods_transfer_old        -- 商品振替（旧商品）
     ,SUM(xird.goods_transfer_new)        goods_transfer_new        -- 商品振替（新商品）
     ,SUM(xird.sample_quantity)           sample_quantity           -- 見本出庫
     ,SUM(xird.sample_quantity_b)         sample_quantity_b         -- 見本出庫振戻
     ,SUM(xird.customer_sample_ship)      customer_sample_ship      -- 顧客見本出庫
     ,SUM(xird.customer_sample_ship_b)    customer_sample_ship_b    -- 顧客見本出庫振戻
     ,SUM(xird.customer_support_ss)       customer_support_ss       -- 顧客協賛見本出庫
     ,SUM(xird.customer_support_ss_b)     customer_support_ss_b     -- 顧客協賛見本出庫振戻
     ,SUM(xird.vd_supplement_stock)       vd_supplement_stock       -- 消化VD補充入庫
     ,SUM(xird.vd_supplement_ship)        vd_supplement_ship        -- 消化VD補充出庫
     ,SUM(xird.inventory_change_in)       inventory_change_in       -- 基準在庫変更入庫
     ,SUM(xird.inventory_change_out)      inventory_change_out      -- 基準在庫変更出庫
     ,SUM(xird.factory_return)            factory_return            -- 工場返品
     ,SUM(xird.factory_return_b)          factory_return_b          -- 工場返品振戻
     ,SUM(xird.factory_change)            factory_change            -- 工場倉替
     ,SUM(xird.factory_change_b)          factory_change_b          -- 工場倉替振戻
     ,SUM(xird.removed_goods)             removed_goods             -- 廃却
     ,SUM(xird.removed_goods_b)           removed_goods_b           -- 廃却振戻
     ,SUM(xird.factory_stock)             factory_stock             -- 工場入庫
     ,SUM(xird.factory_stock_b)           factory_stock_b           -- 工場入庫振戻
     ,SUM(xird.ccm_sample_ship)           ccm_sample_ship           -- 顧客広告宣伝費A自社商品
     ,SUM(xird.ccm_sample_ship_b)         ccm_sample_ship_b         -- 顧客広告宣伝費A自社商品振戻
     ,SUM(xird.wear_decrease)             wear_decrease             -- 棚卸減耗増
     ,SUM(xird.wear_increase)             wear_increase             -- 棚卸減耗減
     ,SUM(xird.selfbase_ship)             selfbase_ship             -- 保管場所移動＿自拠点出庫
     ,SUM(xird.selfbase_stock)            selfbase_stock            -- 保管場所移動＿自拠点入庫
     ,NULL                                inventory_seq             -- 棚卸SEQ
     ,MAX(xird.practice_date)             practice_date             -- 受払作成日
     ,NULL                                inventory_date            -- 棚卸日
    FROM    xxcoi_inv_reception_daily   xird                        -- 月次在庫受払表（日次）
    WHERE   xird.organization_id    =   gn_f_organization_id
-- == 2010/01/05 V1.15 Modified START ===============================================================
--    AND     ((iv_base_code IS NOT NULL AND xird.base_code = iv_base_code)
--             OR
--             (iv_base_code IS NULL)
--            )
    AND     xird.base_code          =   iv_base_code
-- == 2010/01/05 V1.15 Modified END   ===============================================================
    AND     xird.practice_date     >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
    AND     xird.practice_date     <=   LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month))
    GROUP BY
            xird.base_code
           ,xird.organization_id
           ,xird.subinventory_code
           ,xird.inventory_item_id
           ,xird.subinventory_type
    ORDER BY
            xird.base_code
           ,xird.subinventory_code;
-- == 2009/07/21 V1.12 Modified END   ===============================================================
-- == 2010/01/05 V1.15 Added START ===============================================================
  CURSOR invrcp_daily_3_cur
  IS
    SELECT
      xird.base_code                      base_code                 -- 拠点コード
     ,xird.organization_id                organization_id           -- 組織ID
     ,xird.subinventory_code              subinventory_code         -- 保管場所
     ,xird.subinventory_type              subinventory_type         -- 保管場所区分
     ,xird.inventory_item_id              inventory_item_id         -- 品目ID
     ,MAX(xird.operation_cost)            operation_cost            -- 営業原価
     ,MAX(xird.standard_cost)             standard_cost             -- 標準原価
     ,SUM(xird.sales_shipped)             sales_shipped             -- 売上出庫
     ,SUM(xird.sales_shipped_b)           sales_shipped_b           -- 売上出庫振戻
     ,SUM(xird.return_goods)              return_goods              -- 返品
     ,SUM(xird.return_goods_b)            return_goods_b            -- 返品振戻
     ,SUM(xird.warehouse_ship)            warehouse_ship            -- 倉庫へ返庫
     ,SUM(xird.truck_ship)                truck_ship                -- 営業車へ出庫
     ,SUM(xird.others_ship)               others_ship               -- 入出庫＿その他出庫
     ,SUM(xird.warehouse_stock)           warehouse_stock           -- 倉庫より入庫
     ,SUM(xird.truck_stock)               truck_stock               -- 営業車より入庫
     ,SUM(xird.others_stock)              others_stock              -- 入出庫＿その他入庫
     ,SUM(xird.change_stock)              change_stock              -- 倉替入庫
     ,SUM(xird.change_ship)               change_ship               -- 倉替出庫
     ,SUM(xird.goods_transfer_old)        goods_transfer_old        -- 商品振替（旧商品）
     ,SUM(xird.goods_transfer_new)        goods_transfer_new        -- 商品振替（新商品）
     ,SUM(xird.sample_quantity)           sample_quantity           -- 見本出庫
     ,SUM(xird.sample_quantity_b)         sample_quantity_b         -- 見本出庫振戻
     ,SUM(xird.customer_sample_ship)      customer_sample_ship      -- 顧客見本出庫
     ,SUM(xird.customer_sample_ship_b)    customer_sample_ship_b    -- 顧客見本出庫振戻
     ,SUM(xird.customer_support_ss)       customer_support_ss       -- 顧客協賛見本出庫
     ,SUM(xird.customer_support_ss_b)     customer_support_ss_b     -- 顧客協賛見本出庫振戻
     ,SUM(xird.vd_supplement_stock)       vd_supplement_stock       -- 消化VD補充入庫
     ,SUM(xird.vd_supplement_ship)        vd_supplement_ship        -- 消化VD補充出庫
     ,SUM(xird.inventory_change_in)       inventory_change_in       -- 基準在庫変更入庫
     ,SUM(xird.inventory_change_out)      inventory_change_out      -- 基準在庫変更出庫
     ,SUM(xird.factory_return)            factory_return            -- 工場返品
     ,SUM(xird.factory_return_b)          factory_return_b          -- 工場返品振戻
     ,SUM(xird.factory_change)            factory_change            -- 工場倉替
     ,SUM(xird.factory_change_b)          factory_change_b          -- 工場倉替振戻
     ,SUM(xird.removed_goods)             removed_goods             -- 廃却
     ,SUM(xird.removed_goods_b)           removed_goods_b           -- 廃却振戻
     ,SUM(xird.factory_stock)             factory_stock             -- 工場入庫
     ,SUM(xird.factory_stock_b)           factory_stock_b           -- 工場入庫振戻
     ,SUM(xird.ccm_sample_ship)           ccm_sample_ship           -- 顧客広告宣伝費A自社商品
     ,SUM(xird.ccm_sample_ship_b)         ccm_sample_ship_b         -- 顧客広告宣伝費A自社商品振戻
     ,SUM(xird.wear_decrease)             wear_decrease             -- 棚卸減耗増
     ,SUM(xird.wear_increase)             wear_increase             -- 棚卸減耗減
     ,SUM(xird.selfbase_ship)             selfbase_ship             -- 保管場所移動＿自拠点出庫
     ,SUM(xird.selfbase_stock)            selfbase_stock            -- 保管場所移動＿自拠点入庫
     ,NULL                                inventory_seq             -- 棚卸SEQ
     ,MAX(xird.practice_date)             practice_date             -- 受払作成日
     ,NULL                                inventory_date            -- 棚卸日
    FROM    xxcoi_inv_reception_daily   xird                        -- 月次在庫受払表（日次）
    WHERE   xird.organization_id    =   gn_f_organization_id
    AND     xird.practice_date     >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
    AND     xird.practice_date     <=   LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month))
    GROUP BY
            xird.base_code
           ,xird.organization_id
           ,xird.subinventory_code
           ,xird.inventory_item_id
           ,xird.subinventory_type
    ORDER BY
            xird.base_code
           ,xird.subinventory_code;
-- == 2010/01/05 V1.15 Added END   ===============================================================
  --
  -- A-6.棚卸結果情報抽出(【起動パラメータ】棚卸区分:1)
  CURSOR  inv_result_1_cur(
            iv_base_code          IN  VARCHAR2                -- 拠点コード
          )
  IS
    SELECT  xid.inventory_seq           xir_inv_seq                 -- 棚卸SEQ
           ,msi.attribute7              base_code                   -- 拠点コード
           ,xid.inventory_date          inventory_date              -- 棚卸日
           ,msi.attribute1              warehouse_kbn               -- 倉庫区分
           ,msib.inventory_item_id      inventory_item_id           -- 品目ID
           ,SUM(DECODE(xir.quality_goods_kbn, cv_quality_0, xir.case_qty * xir.case_in_qty + xir.quantity
                                                 , 0
                )
            )                           standard_article_qty        -- 良品数（0:良品）
           ,SUM(DECODE(xir.quality_goods_kbn, cv_quality_1, xir.case_qty * xir.case_in_qty + xir.quantity
                                                 , 0
                )
            )                           sub_standard_article_qty    -- 不良品数（1:不良品）
           ,xic.subinventory_code       subinventory_code           -- 保管場所
    FROM    xxcoi_inv_result              xir                       -- HHT棚卸結果テーブル
           ,xxcoi_inv_control             xic                       -- 棚卸管理テーブル
           ,mtl_system_items_b            msib                      -- Disc品目（営業組織）
           ,mtl_secondary_inventories     msi                       -- 保管場所マスタ
           ,(SELECT  MAX(xic.inventory_seq)      inventory_seq
                    ,MAX(xic.inventory_date)     inventory_date
                    ,xic.base_code               base_code                   -- 拠点コード
                    ,xic.subinventory_code       subinventory_code           -- 棚卸場所
             FROM    xxcoi_inv_result              xir                       -- HHT棚卸結果テーブル
                    ,xxcoi_inv_control             xic                       -- 棚卸管理テーブル
                    ,mtl_secondary_inventories     msi
             WHERE   xir.inventory_seq       =   xic.inventory_seq
             AND     xir.inventory_date     >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
             AND     xir.inventory_date     <=   gd_f_process_date
             AND     xir.inventory_kbn       =   gv_param_inventory_kbn
             AND     xic.inventory_status    =   cv_invsts_1                 -- 1:取込済み
             AND     xic.subinventory_code   =   msi.secondary_inventory_name
             AND     msi.attribute7          =   iv_base_code
             AND     msi.organization_id     =   gn_f_organization_id
             GROUP BY   xic.base_code
                       ,xic.subinventory_code
           )                              xid
    WHERE   xid.base_code           =   xic.base_code
    AND     xid.subinventory_code   =   xic.subinventory_code
    AND     xic.inventory_status    =   cv_invsts_1                 -- 1:取込済み
    AND     xic.inventory_seq       =   xir.inventory_seq
    AND     xir.inventory_date     >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
    AND     xir.inventory_date     <=   gd_f_process_date
    AND     xir.inventory_kbn       =   gv_param_inventory_kbn
    AND     xir.item_code           =   msib.segment1
    AND     msib.organization_id    =   gn_f_organization_id
    AND     xic.subinventory_code   =   msi.secondary_inventory_name
    AND     msi.organization_id     =   gn_f_organization_id
    AND     msi.attribute7          =   iv_base_code
    GROUP BY  xid.inventory_seq
             ,msi.attribute7
             ,xid.inventory_date
             ,msi.attribute1
             ,xic.subinventory_code
             ,msib.inventory_item_id
    ORDER BY  base_code
             ,subinventory_code;
  --
  -- A-6.棚卸結果情報抽出(【起動パラメータ】棚卸区分:2)
  CURSOR  inv_result_2_cur(
            iv_base_code          IN  VARCHAR2                -- 拠点コード
          )
  IS
    SELECT  xid.inventory_seq           xir_inv_seq                 -- 棚卸SEQ
           ,msi.attribute7              base_code                   -- 拠点コード
           ,xid.inventory_date          inventory_date              -- 棚卸日
           ,msi.attribute1              warehouse_kbn               -- 倉庫区分
           ,msib.inventory_item_id      inventory_item_id           -- 品目ID
           ,SUM(DECODE(xir.quality_goods_kbn, cv_quality_0, xir.case_qty * xir.case_in_qty + xir.quantity
                                                 , 0
                )
            )                           standard_article_qty        -- 良品数（0:良品）
           ,SUM(DECODE(xir.quality_goods_kbn, cv_quality_1, xir.case_qty * xir.case_in_qty + xir.quantity
                                                 , 0
                )
            )                           sub_standard_article_qty    -- 不良品数（1:不良品）
           ,xic.subinventory_code       subinventory_code           -- 保管場所
    FROM    xxcoi_inv_result              xir                       -- HHT棚卸結果テーブル
           ,xxcoi_inv_control             xic                       -- 棚卸管理テーブル
           ,mtl_system_items_b            msib                      -- Disc品目（営業組織）
           ,mtl_secondary_inventories     msi                       -- 保管場所マスタ
           ,(SELECT  MAX(xic.inventory_seq)      inventory_seq
                    ,MAX(xic.inventory_date)     inventory_date
                    ,xic.base_code               base_code                   -- 拠点コード
                    ,xic.subinventory_code       subinventory_code           -- 棚卸場所
             FROM    xxcoi_inv_result              xir                       -- HHT棚卸結果テーブル
                    ,xxcoi_inv_control             xic                       -- 棚卸管理テーブル
                    ,mtl_secondary_inventories     msi
             WHERE   xir.inventory_seq       =   xic.inventory_seq
             AND     xir.inventory_date     >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
             AND     xir.inventory_date     <=   LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month))
             AND     xir.inventory_kbn       =   gv_param_inventory_kbn
             AND     xic.subinventory_code   =   msi.secondary_inventory_name
             AND     msi.organization_id     =   gn_f_organization_id
             AND     ((iv_base_code IS NOT NULL AND msi.attribute7  =  iv_base_code)
                      OR
                      (iv_base_code IS NULL)
                     )
             GROUP BY   xic.base_code
                       ,xic.subinventory_code
           )                              xid
    WHERE   xid.base_code           =   xic.base_code
    AND     xid.subinventory_code   =   xic.subinventory_code
    AND     xic.inventory_seq       =   xir.inventory_seq
    AND     xir.inventory_date     >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
    AND     xir.inventory_date     <=   LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month))
    AND     xir.inventory_kbn       =   gv_param_inventory_kbn
    AND     xir.item_code           =   msib.segment1
    AND     msib.organization_id    =   gn_f_organization_id
    AND     xic.subinventory_code   =   msi.secondary_inventory_name
    AND     msi.organization_id     =   gn_f_organization_id
    AND     ((iv_base_code IS NOT NULL AND msi.attribute7  =  iv_base_code)
             OR
             (iv_base_code IS NULL)
            )
    GROUP BY  xid.inventory_seq
             ,msi.attribute7
             ,xid.inventory_date
             ,msi.attribute1
             ,xic.subinventory_code
             ,msib.inventory_item_id
    ORDER BY  base_code
             ,subinventory_code;
  --
  -- A-9.当日取引データ取得
  CURSOR  daily_trans_cur(
            iv_base_code          IN  VARCHAR2                -- 拠点コード
          )
  IS
-- == 2009/08/20 V1.14 Modified START ===============================================================
--    SELECT  msi1.attribute7               base_code             -- 拠点コード
--           ,msi1.attribute1               inventory_type        -- 保管場所区分
--           ,msi2.attribute7               sub_base_code         -- 相手先拠点コード
--           ,msi2.attribute1               subinventory_type     -- 相手先保管場所区分
--           ,mmt.subinventory_code         subinventory_code     -- 保管場所コード
--           ,mtt.attribute3                transaction_type      -- 受払表集計キー
--           ,mmt.inventory_item_id         inventory_item_id     -- 品目ID
---- == 2009/07/30 V1.13 Modified START ===============================================================
----           ,mmt.transaction_quantity      transaction_qty       -- 取引数量
--           ,mmt.primary_quantity      transaction_qty           -- 基準単位数量
---- == 2009/07/30 V1.13 Modified END   ===============================================================
--           ,xirm.inv_seq                  inventory_seq         -- 受払棚卸SEQ
---- == 2009/06/04 V1.11 Added START ===============================================================
--           ,msi1.attribute13              subinv_class          -- 保管場所分類
---- == 2009/06/04 V1.11 Added END   ===============================================================
--    FROM    mtl_material_transactions     mmt                   -- 資材取引テーブル
--           ,mtl_secondary_inventories     msi1                  -- 保管場所
--           ,mtl_secondary_inventories     msi2                  -- 保管場所
--           ,xxcoi_inv_reception_monthly   xirm                  -- 月次在庫受払表（月次）
--           ,mtl_transaction_types         mtt                   -- 取引タイプマスタ
--    WHERE   mmt.organization_id       =   gn_f_organization_id
--    AND     mmt.transaction_id        >   gn_f_last_transaction_id
--    AND     mmt.transaction_id       <=   gn_f_max_transaction_id
--    AND     mmt.subinventory_code     =   msi1.secondary_inventory_name
--    AND     mmt.organization_id       =   msi1.organization_id
--    AND     ((iv_base_code IS NOT NULL AND msi1.attribute7 = iv_base_code)
--             OR
--             (iv_base_code IS NULL)
--            )
--    AND     mmt.transfer_subinventory  =  msi2.secondary_inventory_name(+)
--    AND     TO_CHAR(mmt.transaction_date, cv_month)   =   gv_f_inv_acct_period
--    AND     msi1.attribute1           <>  cv_inv_type_5
--    AND     msi1.attribute1           <>  cv_inv_type_8
--    AND     mmt.organization_id        =  xirm.organization_id(+)
--    AND     mmt.subinventory_code      =  xirm.subinventory_code(+)
--    AND     mmt.inventory_item_id      =  xirm.inventory_item_id(+)
--    AND     xirm.practice_month(+)     =  gv_f_inv_acct_period
--    AND     ((xirm.inventory_kbn IS NOT NULL AND xirm.inventory_kbn = gv_param_inventory_kbn)
--             OR
--             (xirm.inventory_kbn IS NULL)
--            )
--    AND     mmt.transaction_type_id    =  mtt.transaction_type_id
--    AND     mtt.attribute3       IS NOT NULL
--    ORDER BY  msi1.attribute7
--             ,mmt.subinventory_code
--             ,msi1.attribute1
--             ,mmt.inventory_item_id;
--
    SELECT
            /*+ LEADING(MMT)
                USE_NL(MMT MSI1 MTT)
                USE_NL(MMT MSI2)
                USE_NL(MMT XIRM)
                INDEX(MMT MTL_MATERIAL_TRANSACTIONS_U1)
            */
            msi1.attribute7               base_code             -- 拠点コード
           ,msi1.attribute1               inventory_type        -- 保管場所区分
           ,msi2.attribute7               sub_base_code         -- 相手先拠点コード
           ,msi2.attribute1               subinventory_type     -- 相手先保管場所区分
           ,mmt.subinventory_code         subinventory_code     -- 保管場所コード
           ,mtt.attribute3                transaction_type      -- 受払表集計キー
           ,mmt.inventory_item_id         inventory_item_id     -- 品目ID
           ,mmt.primary_quantity          transaction_qty       -- 基準単位数量
           ,xirm.inv_seq                  inventory_seq         -- 受払棚卸SEQ
           ,msi1.attribute13              subinv_class          -- 保管場所分類
    FROM    mtl_material_transactions     mmt                   -- 資材取引テーブル
           ,mtl_secondary_inventories     msi1                  -- 保管場所
           ,mtl_secondary_inventories     msi2                  -- 保管場所
           ,xxcoi_inv_reception_monthly   xirm                  -- 月次在庫受払表（月次）
           ,mtl_transaction_types         mtt                   -- 取引タイプマスタ
    WHERE   mmt.organization_id                       =   gn_f_organization_id
    AND     mmt.transaction_id                        >   gn_f_last_transaction_id
    AND     mmt.transaction_id                       <=   gn_f_max_transaction_id
-- == 2010/04/09 V1.16 Modified START ===============================================================
--    AND     mmt.transaction_date    BETWEEN   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
--                                    AND       LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month))
    AND     mmt.transaction_date                     >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
    AND     mmt.transaction_date                      <   LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month)) + 1
-- == 2010/04/09 V1.16 Modified END   ===============================================================
    AND     mmt.subinventory_code                     =   msi1.secondary_inventory_name
    AND     mmt.organization_id                       =   msi1.organization_id
    AND     msi1.attribute7                           =   iv_base_code
    AND     msi1.attribute1                          <>   cv_inv_type_5
    AND     msi1.attribute1                          <>   cv_inv_type_8
    AND     mmt.transfer_subinventory                 =   msi2.secondary_inventory_name(+)
    AND     mmt.transfer_organization_id              =   msi2.organization_id(+)
    AND     mmt.organization_id                       =   xirm.organization_id(+)
    AND     mmt.subinventory_code                     =   xirm.subinventory_code(+)
    AND     mmt.inventory_item_id                     =   xirm.inventory_item_id(+)
    AND     xirm.practice_month(+)                    =   gv_f_inv_acct_period
    AND     xirm.inventory_kbn(+)                     =   gv_param_inventory_kbn
    AND     mmt.transaction_type_id                   =   mtt.transaction_type_id
    AND     mtt.attribute3       IS NOT NULL
    ORDER BY  msi1.attribute7
             ,mmt.subinventory_code
             ,mmt.inventory_item_id;
-- == 2009/08/20 V1.14 Modified END   ===============================================================
  --
-- == 2009/08/20 V1.14 Modified START ===============================================================
-- == 2009/07/21 V1.12 Modified START ===============================================================
  -- A-12.前月棚卸結果抽出
  CURSOR  last_month_cur(
            iv_base_code          IN  VARCHAR2                -- 拠点コード
          )
  IS
----    SELECT  xirm1.inv_seq                               inventory_seq         -- 棚卸SEQ（当月）
----           ,xirm1.base_code                             base_code             -- 拠点コード
----           ,xirm1.organization_id                       organization_id       -- 組織ID
----           ,xirm1.subinventory_type                     subinventory_type     -- 保管場所区分
----           ,xirm1.subinventory_code                     subinventory_code     -- 保管場所コード
----           ,xirm1.practice_date                         practice_date         -- 年月日
----           ,xirm1.inventory_item_id                     inventory_item_id     -- 品目ID
----           ,xirm2.inv_result + xirm2.inv_result_bad     inv_result            -- 棚卸数（前月）
----           ,xirm2.inv_seq                               last_month_inv_seq    -- 棚卸SEQ（前月）
----    FROM    xxcoi_inv_reception_monthly   xirm1         -- 月次在庫受払_当月
----           ,xxcoi_inv_reception_monthly   xirm2         -- 月次在庫受払_前月
----    WHERE   xirm1.base_code           =   xirm2.base_code(+)
----    AND     xirm1.subinventory_code   =   xirm2.subinventory_code(+)
----    AND     xirm1.inventory_item_id   =   xirm2.inventory_item_id(+)
----    AND     ((iv_base_code IS NOT NULL AND xirm1.base_code  = iv_base_code)
----             OR
----             (iv_base_code IS NULL)
----            )
----    AND     ((    (xirm2.practice_month IS NOT NULL)
----              AND (xirm2.practice_month = TO_CHAR(ADD_MONTHS(TO_DATE(gv_f_inv_acct_period,cv_month), -1), cv_month))
----             )
----             OR
----             (xirm2.practice_month IS NULL)
----            )
----    AND     xirm1.practice_month      =   gv_f_inv_acct_period
----    AND     xirm1.inventory_kbn       =   gv_param_inventory_kbn
----    AND     xirm2.inventory_kbn(+)    =   cv_inv_kbn_2
----    ORDER BY  xirm1.base_code
----             ,xirm1.subinventory_code;
------
--    SELECT  xirm2.base_code                             base_code             -- 拠点コード
--           ,xirm2.subinventory_code                     subinventory_code     -- 保管場所コード
--           ,xirm2.inventory_item_id                     inventory_item_id     -- 品目ID
--           ,xirm2.inv_result + xirm2.inv_result_bad     inv_result            -- 棚卸数（前月）
--    FROM    xxcoi_inv_reception_monthly   xirm2                               -- 月次在庫受払_前月
--    WHERE   xirm2.practice_month    =   TO_CHAR(ADD_MONTHS(TO_DATE(gv_f_inv_acct_period,cv_month), -1), cv_month)
--    AND     xirm2.inventory_kbn     =   cv_inv_kbn_2
--    AND     xirm2.base_code         =   NVL(iv_base_code, xirm2.base_code)
--    AND     EXISTS( SELECT  1
--                    FROM    xxcoi_inv_reception_monthly   xirm1               -- 月次在庫受払_当月
--                    WHERE   xirm1.practice_month      =   gv_f_inv_acct_period
--                    AND     xirm1.inventory_kbn       =   gv_param_inventory_kbn
--                    AND     xirm1.base_code           =   xirm2.base_code
--                    AND     xirm1.subinventory_code   =   xirm2.subinventory_code
--                    AND     xirm1.inventory_item_id   =   xirm2.inventory_item_id
--            )
--    ORDER BY  xirm2.base_code
--             ,xirm2.subinventory_code;
---- == 2009/07/21 V1.12 Modified START ===============================================================
--
    SELECT   xirm.base_code                              base_code                 -- 拠点コード
            ,xirm.subinventory_code                      subinventory_code         -- 保管場所コード
            ,xirm.subinventory_type                      subinventory_type         -- 保管場所区分
            ,xirm.inventory_item_id                      inventory_item_id         -- 品目ID
            ,xirm.inv_result + xirm.inv_result_bad       inv_result                -- 棚卸数（前月）
    FROM     xxcoi_inv_reception_monthly                 xirm
    WHERE   xirm.practice_month                   =  TO_CHAR(ADD_MONTHS(TO_DATE(gv_f_inv_acct_period, cv_month), -1), cv_month)
    AND     xirm.inventory_kbn                    =  cv_inv_kbn_2
    AND     xirm.inv_result + xirm.inv_result_bad <> 0
    AND     xirm.organization_id                  =  gn_f_organization_id
    AND     xirm.base_code                        =  NVL(iv_base_code, xirm.base_code)
    ORDER BY xirm.subinventory_code;
-- == 2009/08/20 V1.14 Modified END   ===============================================================
--
-- == 2009/08/20 V1.14 Added END   ===============================================================
  -- カーソルレコード
  invrcp_daily_rec        invrcp_daily_1_cur%ROWTYPE;     -- 日次データ
  inv_result_rec          inv_result_1_cur%ROWTYPE;       -- 棚卸データ
  daily_trans_rec         daily_trans_cur%ROWTYPE;        -- 資材取引データ
  last_month_rec          last_month_cur%ROWTYPE;         -- 前月月次データ
-- == 2009/08/20 V1.14 Added END   ===============================================================
-- == 2009/08/20 V1.14 Deleted START ===============================================================
--  --
--  /**********************************************************************************
--   * Procedure Name   : close_process
--   * Description      : 終了処理(A-14)
--   ***********************************************************************************/
--  PROCEDURE close_process(
--    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
--    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
--    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_process'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
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
--    -- ===============================
--    -- ローカル・カーソル
--    -- ===============================
--    -- <カーソル名>
--    -- <カーソル名>レコード型
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ***************************************
--    -- ***        ループ処理の記述         ***
--    -- ***       処理部の呼び出し          ***
--    -- ***************************************
----
--    --==============================================================
--    --メッセージ出力をする必要がある場合は処理を記述
--    --==============================================================
--    --
--    -- 成功件数取得
--    SELECT  COUNT(1)
--    INTO    gn_normal_cnt
--    FROM    xxcoi_inv_reception_monthly
--    WHERE   request_id  = cn_request_id;
--    --
--    -- 対象件数設定
--    gn_target_cnt :=  gn_normal_cnt + gn_error_cnt;
----
--  EXCEPTION
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
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
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END close_process;
-- == 2009/08/20 V1.14 Deleted END ===============================================================
--
-- == 2009/08/20 V1.14 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : ins_inv_control
   * Description      :  棚卸管理出力（日次データ）(A-5)
   ***********************************************************************************/
  PROCEDURE ins_inv_control(
    it_base_code      IN  xxcoi_inv_control.base_code%TYPE,
    it_subinv_code    IN  xxcoi_inv_control.subinventory_code%TYPE,
    it_subinv_type    IN  xxcoi_inv_reception_monthly.subinventory_type%TYPE,
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inv_control'; -- プログラム名
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
    ln_dummy      NUMBER(1);          -- ダミー変数
    lt_base_code  xxcmm_cust_accounts.management_base_code%TYPE;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- ===================================
    --  拠点コード取得
    -- ===================================
    -- 拠点が百貨店の場合、一律で管理元拠点コードを設定するため、コードを変換を実行
    BEGIN
      -- 棚卸管理用拠点コード取得
      SELECT  xca.management_base_code
      INTO    lt_base_code
      FROM    hz_cust_accounts    hca
             ,xxcmm_cust_accounts xca
      WHERE   hca.cust_account_id       =   xca.customer_id
      AND     hca.account_number        =   it_base_code
      AND     hca.customer_class_code   =   '1'           -- 拠点
      AND     hca.status                =   'A'           -- 有効
      AND     xca.dept_hht_div          =   '1';          -- HHT区分（1:百貨店）
      --
      IF (lt_base_code IS NULL) THEN
        lt_base_code  :=  it_base_code;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_base_code  :=  it_base_code;
    END;
    --
    -- ===================================
    --  棚卸管理情報作成
    -- ===================================
    INSERT INTO xxcoi_inv_control(
      inventory_seq                         -- 01.棚卸SEQ
     ,inventory_kbn                         -- 02.棚卸区分
     ,base_code                             -- 03.拠点コード
     ,subinventory_code                     -- 04.保管場所
     ,warehouse_kbn                         -- 05.倉庫区分
     ,inventory_year_month                  -- 06.年月
     ,inventory_date                        -- 07.棚卸日
     ,inventory_status                      -- 08.棚卸ステータス
     ,last_update_date                      -- 09.最終更新日
     ,last_updated_by                       -- 10.最終更新者
     ,creation_date                         -- 11.作成日
     ,created_by                            -- 12.作成者
     ,last_update_login                     -- 13.最終更新ユーザ
     ,request_id                            -- 14.要求ID
     ,program_application_id                -- 15.プログラムアプリケーションID
     ,program_id                            -- 16.プログラムID
     ,program_update_date                   -- 17.プログラム更新日
    )VALUES(
      xxcoi_inv_control_s01.NEXTVAL         -- 01
     ,gv_param_inventory_kbn                -- 02
     ,lt_base_code                          -- 03
     ,it_subinv_code                        -- 04
     ,it_subinv_type                        -- 05
     ,gv_f_inv_acct_period                  -- 06
     ,gd_f_process_date                     -- 07
     ,cv_invsts_2                           -- 08
     ,SYSDATE                               -- 09
     ,cn_last_updated_by                    -- 10
     ,SYSDATE                               -- 11
     ,cn_created_by                         -- 12
     ,cn_last_update_login                  -- 13
     ,cn_request_id                         -- 14
     ,cn_program_application_id             -- 15
     ,cn_program_id                         -- 16
     ,SYSDATE                               -- 17
    );
    --
    -- ===================================
    --  COMMI処理
    -- ===================================
    -- パフォーマンス考慮のため、COMMITを実行しINSERT時の領域を開放
    COMMIT;
--
  EXCEPTION
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
  END ins_inv_control;
-- == 2009/08/20 V1.14 Added END ===============================================================
--
-- == 2009/08/20 V1.14 Modified START ===============================================================
--  /**********************************************************************************
--   * Procedure Name   : ins_month_balance
--   * Description      : 月首残高出力(A-13)
--   ***********************************************************************************/
--  PROCEDURE ins_month_balance(
--    ir_month_balance  IN  last_month_cur%ROWTYPE,       -- 1.当日取引データ
--    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
--    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
--    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_month_balance'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
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
--    -- ===============================
--    -- ローカル・カーソル
--    -- ===============================
--    -- <カーソル名>
--    -- <カーソル名>レコード型
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ***************************************
--    -- ***        ループ処理の記述         ***
--    -- ***       処理部の呼び出し          ***
--    -- ***************************************
----
--    --==============================================================
--    --メッセージ出力をする必要がある場合は処理を記述
--    --==============================================================
--    -- 更新処理
--    UPDATE  xxcoi_inv_reception_monthly
--    SET     inv_wear                =   inv_wear + ir_month_balance.inv_result        -- 棚卸減耗
--           ,month_begin_quantity    =   ir_month_balance.inv_result                   -- 月首棚卸高
--           ,last_update_date        =   SYSDATE                                       -- 最終更新日
--           ,last_updated_by         =   cn_last_updated_by                            -- 最終更新者
--           ,last_update_login       =   cn_last_update_login                          -- 最終更新ユーザ
--           ,request_id              =   cn_request_id                                 -- 要求ID
--           ,program_application_id  =   cn_program_application_id                     -- プログラムアプリケーションID
--           ,program_id              =   cn_program_id                                 -- プログラムID
--           ,program_update_date     =   SYSDATE                                       -- プログラム更新日
---- == 2009/07/21 V1.12 Modified START ===============================================================
----    WHERE   inv_seq            =   ir_month_balance.inventory_seq
----    AND     inventory_item_id  =   ir_month_balance.inventory_item_id;
----
--    WHERE   base_code           =   ir_month_balance.base_code
--    AND     subinventory_code   =   ir_month_balance.subinventory_code
--    AND     inventory_item_id   =   ir_month_balance.inventory_item_id
--    AND     inventory_kbn       =   gv_param_inventory_kbn
--    AND     practice_month      =   gv_f_inv_acct_period;
---- == 2009/07/21 V1.12 Modified END   ===============================================================
----
--  EXCEPTION
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
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
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END ins_month_balance;
  /**********************************************************************************
   * Procedure Name   : ins_month_balance
   * Description      : 月首残高出力(A-13)
   ***********************************************************************************/
  PROCEDURE ins_month_balance(
    it_base_code      IN  xxcoi_inv_control.base_code%TYPE,
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_month_balance'; -- プログラム名
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
    lt_key_subinv_code    xxcoi_inv_control.subinventory_code%TYPE;
    lt_inv_seq            xxcoi_inv_control.inventory_seq%TYPE;
    lt_standard_cost      xxcoi_inv_reception_monthly.standard_cost%TYPE;
    lt_operation_cost     xxcoi_inv_reception_monthly.operation_cost%TYPE;
    ln_dummy              NUMBER;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --
    -- キー項目初期化
    lt_key_subinv_code  :=  NULL;
    --
    -- ===================================
    --  A-12.前月棚卸結果抽出
    -- ===================================
    OPEN  last_month_cur(
            iv_base_code        =>  it_base_code              -- 拠点コード
          );
    --
    <<month_balance_loop>>    -- 月首残高LOOP
    LOOP
      --  終了判定
      FETCH last_month_cur  INTO  last_month_rec;
      EXIT  month_balance_loop  WHEN  last_month_cur%NOTFOUND;
      --
      -- ===================================
      --  月首棚卸高更新
      -- ===================================
      BEGIN
        -- 当月の月次在庫受払が存在する場合、月首棚卸高を更新
        -- 当月データ存在チェック
        SELECT  1
        INTO    ln_dummy
        FROM    xxcoi_inv_reception_monthly   xirm
        WHERE   xirm.base_code          =   last_month_rec.base_code
        AND     xirm.subinventory_code  =   last_month_rec.subinventory_code
        AND     xirm.inventory_item_id  =   last_month_rec.inventory_item_id
        AND     xirm.inventory_kbn      =   gv_param_inventory_kbn
        AND     xirm.practice_month     =   gv_f_inv_acct_period
        AND     xirm.organization_id    =   gn_f_organization_id
        AND     xirm.request_id         =   cn_request_id
        AND     ROWNUM = 1;
        --
        -- 更新処理
        UPDATE  xxcoi_inv_reception_monthly
        SET     inv_wear                =   inv_wear + last_month_rec.inv_result        -- 棚卸減耗
               ,month_begin_quantity    =   last_month_rec.inv_result                   -- 月首棚卸高
               ,last_update_date        =   SYSDATE                                       -- 最終更新日
               ,last_updated_by         =   cn_last_updated_by                            -- 最終更新者
               ,last_update_login       =   cn_last_update_login                          -- 最終更新ユーザ
               ,request_id              =   cn_request_id                                 -- 要求ID
               ,program_application_id  =   cn_program_application_id                     -- プログラムアプリケーションID
               ,program_id              =   cn_program_id                                 -- プログラムID
               ,program_update_date     =   SYSDATE                                       -- プログラム更新日
         WHERE   base_code          =   last_month_rec.base_code
         AND     subinventory_code  =   last_month_rec.subinventory_code
         AND     inventory_item_id  =   last_month_rec.inventory_item_id
         AND     inventory_kbn      =   gv_param_inventory_kbn
         AND     practice_month     =   gv_f_inv_acct_period
         AND     organization_id    =   gn_f_organization_id
         AND     request_id         =   cn_request_id;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (gv_param_inventory_kbn  = cv_inv_kbn_2) THEN
            -- 当月データが存在しない場合は、棚卸区分：２（月末）の場合にのみ
            -- 月首棚卸高が設定された、月次在庫受払を作成
            -- （月中の場合、棚卸データのない月次在庫受払は作成しない）
            --
            -- ===================================
            --  3.標準原価取得
            -- ===================================
            xxcoi_common_pkg.get_cmpnt_cost(
              in_item_id      =>  last_month_rec.inventory_item_id    -- 品目ID
             ,in_org_id       =>  gn_f_organization_id                -- 組織ID
             ,id_period_date  =>  gd_f_process_date                   -- 対象日
             ,ov_cmpnt_cost   =>  lt_standard_cost                    -- 標準原価
             ,ov_errbuf       =>  lv_errbuf                           -- エラーメッセージ
             ,ov_retcode      =>  lv_retcode                          -- リターン・コード
             ,ov_errmsg       =>  lv_errmsg                           -- ユーザー・エラーメッセージ
            );
            -- 終了パラメータ判定
            IF ((lv_retcode = cv_status_error)
                OR
                (lt_standard_cost IS NULL)
               )
            THEN
              lv_errmsg   := xxccp_common_pkg.get_msg(
                               iv_application  => cv_short_name
                              ,iv_name         => cv_msg_xxcoi1_10285
                             );
              lv_errbuf   := lv_errmsg;
              RAISE global_api_expt;
            END IF;
            --
            -- ===================================
            --  4.営業原価取得
            -- ===================================
            xxcoi_common_pkg.get_discrete_cost(
              in_item_id        =>  last_month_rec.inventory_item_id    -- 品目ID
             ,in_org_id         =>  gn_f_organization_id                -- 組織ID
             ,id_target_date    =>  gd_f_process_date                   -- 対象日
             ,ov_discrete_cost  =>  lt_operation_cost                   -- 営業原価
             ,ov_errbuf         =>  lv_errbuf                           -- エラーメッセージ
             ,ov_retcode        =>  lv_retcode                          -- リターン・コード
             ,ov_errmsg         =>  lv_errmsg                           -- ユーザー・エラーメッセージ
            );
            -- 終了パラメータ判定
            IF ((lv_retcode = cv_status_error)
                OR
                (lt_operation_cost IS NULL)
               )
            THEN
              lv_errmsg   := xxccp_common_pkg.get_msg(
                               iv_application  => cv_short_name
                              ,iv_name         => cv_msg_xxcoi1_10293
                             );
              lv_errbuf   := lv_errmsg;
              RAISE global_api_expt;
            END IF;
            --
            -- ===================================
            --  棚卸管理情報作成
            -- ===================================
            -- 起動フラグ：２（夜間強制確定（棚卸情報取込））で、棚卸情報が存在しない場合に
            -- 保管場所単位に、棚卸管理データを作成する（コンカレント起動時は棚卸情報を作成しない）
            --
            IF (((lt_key_subinv_code IS NULL)
                 OR
                 (lt_key_subinv_code <> last_month_rec.subinventory_code)
                )
                AND
                (gv_param_exec_flag  = cv_exec_2)
               )
            THEN
              BEGIN
                SELECT  1
                INTO    ln_dummy
                FROM    xxcoi_inv_control   xic
                WHERE   xic.subinventory_code     = last_month_rec.subinventory_code
                AND     xic.inventory_kbn         = gv_param_inventory_kbn
                AND     xic.inventory_year_month  = gv_f_inv_acct_period
                AND     ROWNUM = 1;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- ===================================
                  --  6.棚卸データ作成
                  -- ===================================
                  ins_inv_control(
                    it_base_code            =>  last_month_rec.base_code            -- 拠点
                   ,it_subinv_code          =>  last_month_rec.subinventory_code    -- 保管場所
                   ,it_subinv_type          =>  last_month_rec.subinventory_type    -- 保管場所区分
                   ,ov_errbuf               =>  lv_errbuf                           -- エラーメッセージ
                   ,ov_retcode              =>  lv_retcode                          -- リターン・コード
                   ,ov_errmsg               =>  lv_errmsg                           -- ユーザー・エラーメッセージ
                  );
                  -- 終了パラメータ判定
                  IF (lv_retcode = cv_status_error) THEN
                    RAISE global_process_expt;
                  END IF;
              END;
            END IF;
            --
            -- ===================================
            --  7.月首残高作成
            -- ===================================
            INSERT INTO xxcoi_inv_reception_monthly(
              inv_seq                                   -- 01.棚卸SEQ
             ,base_code                                 -- 02.拠点コード
             ,organization_id                           -- 03.組織id
             ,subinventory_code                         -- 04.保管場所
             ,subinventory_type                         -- 05.保管場所区分
             ,practice_month                            -- 06.年月
             ,practice_date                             -- 07.年月日
             ,inventory_kbn                             -- 08.棚卸区分
             ,inventory_item_id                         -- 09.品目ID
             ,operation_cost                            -- 10.営業原価
             ,standard_cost                             -- 11.標準原価
             ,sales_shipped                             -- 12.売上出庫
             ,sales_shipped_b                           -- 13.売上出庫振戻
             ,return_goods                              -- 14.返品
             ,return_goods_b                            -- 15.返品振戻
             ,warehouse_ship                            -- 16.倉庫へ返庫
             ,truck_ship                                -- 17.営業車へ出庫
             ,others_ship                               -- 18.入出庫＿その他出庫
             ,warehouse_stock                           -- 19.倉庫より入庫
             ,truck_stock                               -- 20.営業車より入庫
             ,others_stock                              -- 21.入出庫＿その他入庫
             ,change_stock                              -- 22.倉替入庫
             ,change_ship                               -- 23.倉替出庫
             ,goods_transfer_old                        -- 24.商品振替（旧商品）
             ,goods_transfer_new                        -- 25.商品振替（新商品）
             ,sample_quantity                           -- 26.見本出庫
             ,sample_quantity_b                         -- 27.見本出庫振戻
             ,customer_sample_ship                      -- 28.顧客見本出庫
             ,customer_sample_ship_b                    -- 29.顧客見本出庫振戻
             ,customer_support_ss                       -- 30.顧客協賛見本出庫
             ,customer_support_ss_b                     -- 31.顧客協賛見本出庫振戻
             ,ccm_sample_ship                           -- 32.顧客広告宣伝費a自社商品
             ,ccm_sample_ship_b                         -- 33.顧客広告宣伝費a自社商品振戻
             ,vd_supplement_stock                       -- 34.消化vd補充入庫
             ,vd_supplement_ship                        -- 35.消化vd補充出庫
             ,inventory_change_in                       -- 36.基準在庫変更入庫
             ,inventory_change_out                      -- 37.基準在庫変更出庫
             ,factory_return                            -- 38.工場返品
             ,factory_return_b                          -- 39.工場返品振戻
             ,factory_change                            -- 40.工場倉替
             ,factory_change_b                          -- 41.工場倉替振戻
             ,removed_goods                             -- 42.廃却
             ,removed_goods_b                           -- 43.廃却振戻
             ,factory_stock                             -- 44.工場入庫
             ,factory_stock_b                           -- 45.工場入庫振戻
             ,wear_decrease                             -- 46.棚卸減耗増
             ,wear_increase                             -- 47.棚卸減耗減
             ,selfbase_ship                             -- 48.保管場所移動＿自拠点出庫
             ,selfbase_stock                            -- 49.保管場所移動＿自拠点入庫
             ,inv_result                                -- 50.棚卸結果
             ,inv_result_bad                            -- 51.棚卸結果（不良品）
             ,inv_wear                                  -- 52.棚卸減耗
             ,month_begin_quantity                      -- 53.月首棚卸高
             ,last_update_date                          -- 54.最終更新日
             ,last_updated_by                           -- 55.最終更新者
             ,creation_date                             -- 56.作成日
             ,created_by                                -- 57.作成者
             ,last_update_login                         -- 58.最終更新ユーザ
             ,request_id                                -- 59.要求ID
             ,program_application_id                    -- 60.プログラムアプリケーションID
             ,program_id                                -- 61.プログラムID
             ,program_update_date                       -- 62.プログラム更新日
            )VALUES(
              1                                -- 01
             ,last_month_rec.base_code                  -- 02
             ,gn_f_organization_id                      -- 03
             ,last_month_rec.subinventory_code          -- 04
             ,last_month_rec.subinventory_type          -- 05
             ,gv_f_inv_acct_period                      -- 06
             ,gd_f_process_date                         -- 07
             ,gv_param_inventory_kbn                    -- 08
             ,last_month_rec.inventory_item_id          -- 09
             ,TO_NUMBER(lt_operation_cost)              -- 10
             ,TO_NUMBER(lt_standard_cost)               -- 11
             ,0                                         -- 12
             ,0                                         -- 13
             ,0                                         -- 14
             ,0                                         -- 15
             ,0                                         -- 16
             ,0                                         -- 17
             ,0                                         -- 18
             ,0                                         -- 19
             ,0                                         -- 20
             ,0                                         -- 21
             ,0                                         -- 22
             ,0                                         -- 23
             ,0                                         -- 24
             ,0                                         -- 25
             ,0                                         -- 26
             ,0                                         -- 27
             ,0                                         -- 28
             ,0                                         -- 29
             ,0                                         -- 30
             ,0                                         -- 31
             ,0                                         -- 32
             ,0                                         -- 33
             ,0                                         -- 34
             ,0                                         -- 35
             ,0                                         -- 36
             ,0                                         -- 37
             ,0                                         -- 38
             ,0                                         -- 39
             ,0                                         -- 40
             ,0                                         -- 41
             ,0                                         -- 42
             ,0                                         -- 43
             ,0                                         -- 44
             ,0                                         -- 45
             ,0                                         -- 46
             ,0                                         -- 47
             ,0                                         -- 48
             ,0                                         -- 49
             ,0                                         -- 50
             ,0                                         -- 51
             ,last_month_rec.inv_result                 -- 52
             ,last_month_rec.inv_result                 -- 53
             ,SYSDATE                                   -- 54
             ,cn_last_updated_by                        -- 55
             ,SYSDATE                                   -- 56
             ,cn_created_by                             -- 57
             ,cn_last_update_login                      -- 58
             ,cn_request_id                             -- 59
             ,cn_program_application_id                 -- 60
             ,cn_program_id                             -- 61
             ,SYSDATE                                   -- 62
            );
            --
            -- 成功件数（月次在庫受払の作成レコード数）
            gn_target_cnt :=  gn_target_cnt + 1;
            gn_normal_cnt :=  gn_normal_cnt + 1;
          END IF;
      END;
      -- キー情報（保管場所コード）を保持
      lt_key_subinv_code  :=  last_month_rec.subinventory_code;
      --
    END LOOP month_balance_loop;
    --
    -- ===================================
    --  CURSORクローズ
    -- ===================================
    CLOSE last_month_cur;
    --
  EXCEPTION
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
  END ins_month_balance;
-- == 2009/08/20 V1.14 Modified END   ===============================================================
--
-- == 2009/08/20 V1.14 Deleted START  ===============================================================
--  /**********************************************************************************
--   * Procedure Name   : ins_daily_invcntl
--   * Description      :  棚卸管理出力（当日取引データ）(A-11)
--   ***********************************************************************************/
--  PROCEDURE ins_daily_invcntl(
--    ir_daily_trans    IN  daily_trans_cur%ROWTYPE,      -- 1.当日取引データ
--    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
--    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
--    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_daily_invcntl'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
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
--    lt_base_code    xxcmm_cust_accounts.management_base_code%TYPE;
----
--    -- ===============================
--    -- ローカル・カーソル
--    -- ===============================
--    -- <カーソル名>
--    -- <カーソル名>レコード型
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ***************************************
--    -- ***        ループ処理の記述         ***
--    -- ***       処理部の呼び出し          ***
--    -- ***************************************
----
--    --==============================================================
--    --メッセージ出力をする必要がある場合は処理を記述
--    --==============================================================
----
--    -- 処理１件目ではなく、かつ、前レコードの棚卸SEQがNULLで、
--    -- 月次在庫作成フラグON、かつ、起動フラグ：月次夜間強制確定、かつ
--    -- キー項目（拠点、保管場所）が変更された、または、最終データの場合
--    IF ((gt_save_3_base_code  IS NOT NULL)
--        AND
--        (gt_save_3_inv_seq_sub IS NULL)
--        AND
--        (gv_create_flag = cv_on)
--        AND
--        (gv_param_exec_flag = cv_exec_2)
--        AND
--        (gt_save_3_base_code <> ir_daily_trans.base_code
--         OR
--         gt_save_3_inv_code  <> ir_daily_trans.subinventory_code
--         OR
--         daily_trans_cur%NOTFOUND
--        )
--       )
--    THEN
--      --
--      BEGIN
--        -- 棚卸管理用拠点コード取得
--        SELECT  xca.management_base_code
--        INTO    lt_base_code
--        FROM    hz_cust_accounts    hca
--               ,xxcmm_cust_accounts xca
--        WHERE   hca.cust_account_id       =   xca.customer_id
--        AND     hca.account_number        =   gt_save_3_base_code
--        AND     hca.customer_class_code   =   '1'           -- 拠点
--        AND     hca.status                =   'A'           -- 有効
---- == 2009/03/30 V1.6 Added START ===============================================================
--        AND     xca.dept_hht_div          =   '1';          -- HHT区分（1:百貨店）
---- == 2009/03/30 V1.6 Added END   ===============================================================
--        --
--        IF (lt_base_code IS NULL) THEN
--          lt_base_code  :=  gt_save_3_base_code;
--        END IF;
---- == 2009/03/30 V1.6 Added START ===============================================================
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          lt_base_code  :=  gt_save_3_base_code;
---- == 2009/03/30 V1.6 Added END   ===============================================================
--      END;
--      --
--      INSERT INTO xxcoi_inv_control(
--        inventory_seq                         -- 01.棚卸SEQ
--       ,inventory_kbn                         -- 02.棚卸区分
--       ,base_code                             -- 03.拠点コード
--       ,subinventory_code                     -- 04.保管場所
--       ,warehouse_kbn                         -- 05.倉庫区分
--       ,inventory_year_month                  -- 06.年月
--       ,inventory_date                        -- 07.棚卸日
--       ,inventory_status                      -- 08.棚卸ステータス
--       ,last_update_date                      -- 09.最終更新日
--       ,last_updated_by                       -- 10.最終更新者
--       ,creation_date                         -- 11.作成日
--       ,created_by                            -- 12.作成者
--       ,last_update_login                     -- 13.最終更新ユーザ
--       ,request_id                            -- 14.要求ID
--       ,program_application_id                -- 15.プログラムアプリケーションID
--       ,program_id                            -- 16.プログラムID
--       ,program_update_date                   -- 17.プログラム更新日
--      )VALUES(
--        gt_save_3_inv_seq                     -- 01
--       ,gv_param_inventory_kbn                -- 02
--       ,lt_base_code                          -- 03
--       ,gt_save_3_inv_code                    -- 04
--       ,gt_save_3_inv_type                    -- 05
--       ,gv_f_inv_acct_period                  -- 06
--       ,gd_f_process_date                     -- 07
--       ,cv_invsts_2                           -- 08（2:受払作成）
--       ,SYSDATE                               -- 09
--       ,cn_last_updated_by                    -- 10
--       ,SYSDATE                               -- 11
--       ,cn_created_by                         -- 12
--       ,cn_last_update_login                  -- 13
--       ,cn_request_id                         -- 14
--       ,cn_program_application_id             -- 15
--       ,cn_program_id                         -- 16
--       ,SYSDATE                               -- 17
--      );
--      --
--    END IF;
--    --
--    IF ((gt_save_3_inv_seq_sub IS NULL)
--        AND
--        (gv_create_flag = cv_on)
--       )
--    THEN
--      -- 月次在庫受払作成フラグ初期化
--      gv_create_flag  :=  cv_off;
--    END IF;
--      --
--  EXCEPTION
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
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
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END ins_daily_invcntl;
-- == 2009/08/20 V1.14 Deleted END    ===============================================================
--
-- == 2009/08/20 V1.14 Modified START  ===============================================================
--  /**********************************************************************************
--   * Procedure Name   : ins_daily_data
--   * Description      : 月次在庫受払出力（当日取引データ）(A-10)
--   ***********************************************************************************/
--  PROCEDURE ins_daily_data(
--    ir_daily_trans    IN  daily_trans_cur%ROWTYPE,      -- 1.当日取引データ
--    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
--    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
--    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_daily_data'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
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
--    ln_dummy              NUMBER;       -- ダミー変数
--    lt_operation_cost     cm_cmpt_dtl.cmpnt_cost%TYPE;      -- 営業原価
--    lt_standard_cost      cst_item_costs.item_cost%TYPE;    -- 標準原価
--    ln_exec_flag          NUMBER;
--    ln_inventory_seq      NUMBER;
----
--    -- ===============================
--    -- ローカル・カーソル
--    -- ===============================
--    -- <カーソル名>
--    -- <カーソル名>レコード型
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ***************************************
--    -- ***        ループ処理の記述         ***
--    -- ***       処理部の呼び出し          ***
--    -- ***************************************
----
--    --==============================================================
--    --メッセージ出力をする必要がある場合は処理を記述
--    --==============================================================
----
--    IF ((gt_save_3_base_code  IS NOT NULL)
--        AND
--        (gt_save_3_base_code <> ir_daily_trans.base_code
--         OR
--         gt_save_3_inv_code  <> ir_daily_trans.subinventory_code
--         OR
--         daily_trans_cur%NOTFOUND
--        )
--       )
--    THEN
--      -- 処理１件目ではなく、キー項目（拠点、保管場所）が変更された、または、最終データの集計が完了している場合
--      -- 実行フラグ１：INSERT実行、棚卸SEQ設定
--      ln_exec_flag  :=  1;
--      --
--    ELSIF ((gt_save_3_base_code IS NOT NULL)
--           AND
--           (gt_save_3_item_id <> ir_daily_trans.inventory_item_id)
--          )
--    THEN
--      -- キー項目（品目ID）が変更された場合
--      -- 実行フラグ２：データ保持、棚卸SEQ設定なし
--      ln_exec_flag  :=  2;
--    ELSE
--      -- 実行フラグ０：INSERT実行なし、初期化処理なし
--      ln_exec_flag  :=  0;
--    END IF;
--    --
--    IF (ln_exec_flag <> 0) THEN
--      gn_data_cnt :=  gn_data_cnt + 1;
--      --
--      -- 当日データ保持
--      gt_daily_data(gn_data_cnt).inv_seq                 :=  gt_save_3_inv_seq_sub;
--      gt_daily_data(gn_data_cnt).base_code               :=  gt_save_3_base_code;
--      gt_daily_data(gn_data_cnt).organization_id         :=  gn_f_organization_id;
--      gt_daily_data(gn_data_cnt).subinventory_code       :=  gt_save_3_inv_code;
--      gt_daily_data(gn_data_cnt).subinventory_type       :=  gt_save_3_inv_type;
--      gt_daily_data(gn_data_cnt).practice_month          :=  gv_f_inv_acct_period;
--      gt_daily_data(gn_data_cnt).practice_date           :=  gd_f_process_date;
--      gt_daily_data(gn_data_cnt).inventory_kbn           :=  gv_param_inventory_kbn;
--      gt_daily_data(gn_data_cnt).inventory_item_id       :=  gt_save_3_item_id;
--      gt_daily_data(gn_data_cnt).sales_shipped           :=  gt_quantity(1)  * -1;
--      gt_daily_data(gn_data_cnt).sales_shipped_b         :=  gt_quantity(2)  *  1;
--      gt_daily_data(gn_data_cnt).return_goods            :=  gt_quantity(3)  *  1;
--      gt_daily_data(gn_data_cnt).return_goods_b          :=  gt_quantity(4)  * -1;
--      gt_daily_data(gn_data_cnt).warehouse_ship          :=  gt_quantity(5)  * -1;
--      gt_daily_data(gn_data_cnt).truck_ship              :=  gt_quantity(6)  * -1;
--      gt_daily_data(gn_data_cnt).others_ship             :=  gt_quantity(7)  * -1;
--      gt_daily_data(gn_data_cnt).warehouse_stock         :=  gt_quantity(8)  *  1;
--      gt_daily_data(gn_data_cnt).truck_stock             :=  gt_quantity(9)  *  1;
--      gt_daily_data(gn_data_cnt).others_stock            :=  gt_quantity(10) *  1;
--      gt_daily_data(gn_data_cnt).change_stock            :=  gt_quantity(11) *  1;
--      gt_daily_data(gn_data_cnt).change_ship             :=  gt_quantity(12) * -1;
--      gt_daily_data(gn_data_cnt).goods_transfer_old      :=  gt_quantity(13) * -1;
--      gt_daily_data(gn_data_cnt).goods_transfer_new      :=  gt_quantity(14) *  1;
--      gt_daily_data(gn_data_cnt).sample_quantity         :=  gt_quantity(15) * -1;
--      gt_daily_data(gn_data_cnt).sample_quantity_b       :=  gt_quantity(16) *  1;
--      gt_daily_data(gn_data_cnt).customer_sample_ship    :=  gt_quantity(17) * -1;
--      gt_daily_data(gn_data_cnt).customer_sample_ship_b  :=  gt_quantity(18) *  1;
--      gt_daily_data(gn_data_cnt).customer_support_ss     :=  gt_quantity(19) * -1;
--      gt_daily_data(gn_data_cnt).customer_support_ss_b   :=  gt_quantity(20) *  1;
--      gt_daily_data(gn_data_cnt).vd_supplement_stock     :=  gt_quantity(21) *  1;
--      gt_daily_data(gn_data_cnt).vd_supplement_ship      :=  gt_quantity(22) * -1;
--      gt_daily_data(gn_data_cnt).inventory_change_in     :=  gt_quantity(23) *  1;
--      gt_daily_data(gn_data_cnt).inventory_change_out    :=  gt_quantity(24) * -1;
--      gt_daily_data(gn_data_cnt).factory_return          :=  gt_quantity(25) * -1;
--      gt_daily_data(gn_data_cnt).factory_return_b        :=  gt_quantity(26) *  1;
--      gt_daily_data(gn_data_cnt).factory_change          :=  gt_quantity(27) * -1;
--      gt_daily_data(gn_data_cnt).factory_change_b        :=  gt_quantity(28) *  1;
--      gt_daily_data(gn_data_cnt).removed_goods           :=  gt_quantity(29) * -1;
--      gt_daily_data(gn_data_cnt).removed_goods_b         :=  gt_quantity(30) *  1;
--      gt_daily_data(gn_data_cnt).factory_stock           :=  gt_quantity(31) *  1;
--      gt_daily_data(gn_data_cnt).factory_stock_b         :=  gt_quantity(32) * -1;
--      gt_daily_data(gn_data_cnt).ccm_sample_ship         :=  gt_quantity(33) * -1;
--      gt_daily_data(gn_data_cnt).ccm_sample_ship_b       :=  gt_quantity(34) *  1;
--      gt_daily_data(gn_data_cnt).wear_decrease           :=  gt_quantity(35) *  1;
--      gt_daily_data(gn_data_cnt).wear_increase           :=  gt_quantity(36) * -1;
--      gt_daily_data(gn_data_cnt).selfbase_ship           :=  gt_quantity(37) * -1;
--      gt_daily_data(gn_data_cnt).selfbase_stock          :=  gt_quantity(38) *  1;
--      gt_daily_data(gn_data_cnt).inv_result              :=  0;
--      gt_daily_data(gn_data_cnt).inv_result_bad          :=  0;
--      gt_daily_data(gn_data_cnt).inv_wear                :=   gt_quantity(1)  + gt_quantity(2)  + gt_quantity(3)  + gt_quantity(4)
--                                                            + gt_quantity(5)  + gt_quantity(6)  + gt_quantity(7)  + gt_quantity(8)
--                                                            + gt_quantity(9)  + gt_quantity(10) + gt_quantity(11) + gt_quantity(12)
--                                                            + gt_quantity(13) + gt_quantity(14) + gt_quantity(15) + gt_quantity(16)
--                                                            + gt_quantity(17) + gt_quantity(18) + gt_quantity(19) + gt_quantity(20)
--                                                            + gt_quantity(21) + gt_quantity(22) + gt_quantity(23) + gt_quantity(24)
--                                                            + gt_quantity(25) + gt_quantity(26) + gt_quantity(27) + gt_quantity(28)
--                                                            + gt_quantity(29) + gt_quantity(30) + gt_quantity(31) + gt_quantity(32)
--                                                            + gt_quantity(33) + gt_quantity(34) + gt_quantity(35) + gt_quantity(36)
--                                                            + gt_quantity(37) + gt_quantity(38);
--      gt_daily_data(gn_data_cnt).month_begin_quantity    :=  0;
--      --
--      IF (ln_exec_flag = 1) THEN
--        -- 実行フラグ１の場合
--        --
--        -- ===================================
--        --  1.棚卸SEQ取得
--        -- ===================================
--        <<set_seq_loop>>
--        FOR ln_seq_cnt  IN  1 .. gn_data_cnt  LOOP
--          IF (gt_daily_data(ln_seq_cnt).inv_seq IS NOT NULL) THEN
--            -- 拠点、保管場所単位で、一つでも棚卸SEQが設定されている場合
--            gt_save_3_inv_seq     :=  gt_daily_data(ln_seq_cnt).inv_seq;
--            gt_save_3_inv_seq_sub :=  gt_daily_data(ln_seq_cnt).inv_seq;
--            --
--            EXIT set_seq_loop;
--          ELSIF (ln_seq_cnt = gn_data_cnt) THEN
--            -- 全ての棚卸SEQがNULLの場合、新規採番
--            --
--            SELECT  xxcoi_inv_control_s01.NEXTVAL
--            INTO    gt_save_3_inv_seq
--            FROM    dual;
--            --
--            gt_save_3_inv_seq_sub :=  NULL;
--          END IF;
--        END LOOP set_seq_loop;
--        --
--        --
--        <<daily_set_loop>>
--        FOR ln_loop_cnt IN  1 .. gn_data_cnt  LOOP
--          IF (    (gt_daily_data(ln_loop_cnt).sales_shipped           = 0)
--              AND (gt_daily_data(ln_loop_cnt).sales_shipped_b         = 0)
--              AND (gt_daily_data(ln_loop_cnt).return_goods            = 0)
--              AND (gt_daily_data(ln_loop_cnt).return_goods_b          = 0)
--              AND (gt_daily_data(ln_loop_cnt).warehouse_ship          = 0)
--              AND (gt_daily_data(ln_loop_cnt).truck_ship              = 0)
--              AND (gt_daily_data(ln_loop_cnt).others_ship             = 0)
--              AND (gt_daily_data(ln_loop_cnt).warehouse_stock         = 0)
--              AND (gt_daily_data(ln_loop_cnt).truck_stock             = 0)
--              AND (gt_daily_data(ln_loop_cnt).others_stock            = 0)
--              AND (gt_daily_data(ln_loop_cnt).change_stock            = 0)
--              AND (gt_daily_data(ln_loop_cnt).change_ship             = 0)
--              AND (gt_daily_data(ln_loop_cnt).goods_transfer_old      = 0)
--              AND (gt_daily_data(ln_loop_cnt).goods_transfer_new      = 0)
--              AND (gt_daily_data(ln_loop_cnt).sample_quantity         = 0)
--              AND (gt_daily_data(ln_loop_cnt).sample_quantity_b       = 0)
--              AND (gt_daily_data(ln_loop_cnt).customer_sample_ship    = 0)
--              AND (gt_daily_data(ln_loop_cnt).customer_sample_ship_b  = 0)
--              AND (gt_daily_data(ln_loop_cnt).customer_support_ss     = 0)
--              AND (gt_daily_data(ln_loop_cnt).customer_support_ss_b   = 0)
--              AND (gt_daily_data(ln_loop_cnt).vd_supplement_stock     = 0)
--              AND (gt_daily_data(ln_loop_cnt).vd_supplement_ship      = 0)
--              AND (gt_daily_data(ln_loop_cnt).inventory_change_in     = 0)
--              AND (gt_daily_data(ln_loop_cnt).inventory_change_out    = 0)
--              AND (gt_daily_data(ln_loop_cnt).factory_return          = 0)
--              AND (gt_daily_data(ln_loop_cnt).factory_return_b        = 0)
--              AND (gt_daily_data(ln_loop_cnt).factory_change          = 0)
--              AND (gt_daily_data(ln_loop_cnt).factory_change_b        = 0)
--              AND (gt_daily_data(ln_loop_cnt).removed_goods           = 0)
--              AND (gt_daily_data(ln_loop_cnt).removed_goods_b         = 0)
--              AND (gt_daily_data(ln_loop_cnt).factory_stock           = 0)
--              AND (gt_daily_data(ln_loop_cnt).factory_stock_b         = 0)
--              AND (gt_daily_data(ln_loop_cnt).ccm_sample_ship         = 0)
--              AND (gt_daily_data(ln_loop_cnt).ccm_sample_ship_b       = 0)
--              AND (gt_daily_data(ln_loop_cnt).wear_decrease           = 0)
--              AND (gt_daily_data(ln_loop_cnt).wear_increase           = 0)
--              AND (gt_daily_data(ln_loop_cnt).selfbase_ship           = 0)
--              AND (gt_daily_data(ln_loop_cnt).selfbase_stock          = 0)
--             )
--          THEN
--            -- 売上出庫から、保管場所移動＿自拠点入庫まで全項目０の場合、データ作成を行わない
--            NULL;
--            --
--          ELSIF (gt_daily_data(ln_loop_cnt).inv_seq IS NULL) THEN
--            -- 拠点、保管場所、品目単位で、月次在庫受払データが存在しない場合、かつ、
--            -- 月次夜間強制確定時のみ実行
--            --
--            -- ===================================
--            --  2.標準原価取得
--            -- ===================================
--            xxcoi_common_pkg.get_cmpnt_cost(
--              in_item_id      =>  gt_daily_data(ln_loop_cnt).inventory_item_id  -- 品目ID
--             ,in_org_id       =>  gn_f_organization_id                          -- 組織ID
--             ,id_period_date  =>  gd_f_process_date                             -- 対象日
--             ,ov_cmpnt_cost   =>  lt_standard_cost                              -- 標準原価
--             ,ov_errbuf       =>  lv_errbuf                                     -- エラーメッセージ
--             ,ov_retcode      =>  lv_retcode                                    -- リターン・コード
--             ,ov_errmsg       =>  lv_errmsg                                     -- ユーザー・エラーメッセージ
--            );
--            -- 終了パラメータ判定
--            IF (lv_retcode = cv_status_error) THEN
--              lv_errmsg   := xxccp_common_pkg.get_msg(
--                               iv_application  => cv_short_name
--                              ,iv_name         => cv_msg_xxcoi1_10285
--                             );
--              lv_errbuf   := lv_errmsg;
--              RAISE global_api_expt;
--            END IF;
--            --
--            -- ===================================
--            --  3.営業原価取得
--            -- ===================================
--            xxcoi_common_pkg.get_discrete_cost(
--              in_item_id        =>  gt_daily_data(ln_loop_cnt).inventory_item_id  -- 品目ID
--             ,in_org_id         =>  gn_f_organization_id                          -- 組織ID
--             ,id_target_date    =>  gd_f_process_date                             -- 対象日
--             ,ov_discrete_cost  =>  lt_operation_cost                             -- 営業原価
--             ,ov_errbuf         =>  lv_errbuf                                     -- エラーメッセージ
--             ,ov_retcode        =>  lv_retcode                                    -- リターン・コード
--             ,ov_errmsg         =>  lv_errmsg                                     -- ユーザー・エラーメッセージ
--            );
--            -- 終了パラメータ判定
--            IF (lv_retcode = cv_status_error) THEN
--              lv_errmsg   := xxccp_common_pkg.get_msg(
--                               iv_application  => cv_short_name
--                              ,iv_name         => cv_msg_xxcoi1_10293
--                             );
--              lv_errbuf   := lv_errmsg;
--              RAISE global_api_expt;
--            END IF;
--            --
--            -- ===================================
--            --  4.月次在庫受払テーブル出力
--            -- ===================================
--            INSERT INTO xxcoi_inv_reception_monthly(
--              inv_seq                                   -- 01.棚卸SEQ
--             ,base_code                                 -- 02.拠点コード
--             ,organization_id                           -- 03.組織ID
--             ,subinventory_code                         -- 04.保管場所
--             ,subinventory_type                         -- 05.保管場所区分
--             ,practice_month                            -- 06.年月
--             ,practice_date                             -- 07.年月日
--             ,inventory_kbn                             -- 08.棚卸区分
--             ,inventory_item_id                         -- 09.品目ID
--             ,operation_cost                            -- 10.営業原価
--             ,standard_cost                             -- 11.標準原価
--             ,sales_shipped                             -- 12.売上出庫
--             ,sales_shipped_b                           -- 13.売上出庫振戻
--             ,return_goods                              -- 14.返品
--             ,return_goods_b                            -- 15.返品振戻
--             ,warehouse_ship                            -- 16.倉庫へ返庫
--             ,truck_ship                                -- 17.営業車へ出庫
--             ,others_ship                               -- 18.入出庫＿その他出庫
--             ,warehouse_stock                           -- 19.倉庫より入庫
--             ,truck_stock                               -- 20.営業車より入庫
--             ,others_stock                              -- 21.入出庫＿その他入庫
--             ,change_stock                              -- 22.倉替入庫
--             ,change_ship                               -- 23.倉替出庫
--             ,goods_transfer_old                        -- 24.商品振替（旧商品）
--             ,goods_transfer_new                        -- 25.商品振替（新商品）
--             ,sample_quantity                           -- 26.見本出庫
--             ,sample_quantity_b                         -- 27.見本出庫振戻
--             ,customer_sample_ship                      -- 28.顧客見本出庫
--             ,customer_sample_ship_b                    -- 29.顧客見本出庫振戻
--             ,customer_support_ss                       -- 30.顧客協賛見本出庫
--             ,customer_support_ss_b                     -- 31.顧客協賛見本出庫振戻
--             ,vd_supplement_stock                       -- 32.消化VD補充入庫
--             ,vd_supplement_ship                        -- 33.消化VD補充出庫
--             ,inventory_change_in                       -- 34.基準在庫変更入庫
--             ,inventory_change_out                      -- 35.基準在庫変更出庫
--             ,factory_return                            -- 36.工場返品
--             ,factory_return_b                          -- 37.工場返品振戻
--             ,factory_change                            -- 38.工場倉替
--             ,factory_change_b                          -- 39.工場倉替振戻
--             ,removed_goods                             -- 40.廃却
--             ,removed_goods_b                           -- 41.廃却振戻
--             ,factory_stock                             -- 42.工場入庫
--             ,factory_stock_b                           -- 43.工場入庫振戻
--             ,ccm_sample_ship                           -- 44.顧客広告宣伝費A自社商品
--             ,ccm_sample_ship_b                         -- 45.顧客広告宣伝費A自社商品振戻
--             ,wear_decrease                             -- 46.棚卸減耗増
--             ,wear_increase                             -- 47.棚卸減耗減
--             ,selfbase_ship                             -- 48.保管場所移動＿自拠点出庫
--             ,selfbase_stock                            -- 49.保管場所移動＿自拠点入庫
--             ,inv_result                                -- 50.棚卸結果
--             ,inv_result_bad                            -- 51.棚卸結果（不良品）
--             ,inv_wear                                  -- 52.棚卸減耗
--             ,month_begin_quantity                      -- 53.月首棚卸高
--             ,last_update_date                          -- 54.最終更新日
--             ,last_updated_by                           -- 55.最終更新者
--             ,creation_date                             -- 56.作成日
--             ,created_by                                -- 57.作成者
--             ,last_update_login                         -- 58.最終更新ユーザ
--             ,request_id                                -- 59.要求ID
--             ,program_application_id                    -- 60.プログラムアプリケーションID
--             ,program_id                                -- 61.プログラムID
--             ,program_update_date                       -- 62.プログラム更新日
--            )VALUES(
--              gt_save_3_inv_seq                                   -- 01
--             ,gt_daily_data(ln_loop_cnt).base_code                -- 02
--             ,gt_daily_data(ln_loop_cnt).organization_id          -- 03
--             ,gt_daily_data(ln_loop_cnt).subinventory_code        -- 04
--             ,gt_daily_data(ln_loop_cnt).subinventory_type        -- 05
--             ,gt_daily_data(ln_loop_cnt).practice_month           -- 06
--             ,gt_daily_data(ln_loop_cnt).practice_date            -- 07
--             ,gt_daily_data(ln_loop_cnt).inventory_kbn            -- 08
--             ,gt_daily_data(ln_loop_cnt).inventory_item_id        -- 09
--             ,TO_NUMBER(lt_operation_cost)                        -- 10
--             ,TO_NUMBER(lt_standard_cost)                         -- 11
--             ,gt_daily_data(ln_loop_cnt).sales_shipped            -- 12
--             ,gt_daily_data(ln_loop_cnt).sales_shipped_b          -- 13
--             ,gt_daily_data(ln_loop_cnt).return_goods             -- 14
--             ,gt_daily_data(ln_loop_cnt).return_goods_b           -- 15
--             ,gt_daily_data(ln_loop_cnt).warehouse_ship           -- 16
--             ,gt_daily_data(ln_loop_cnt).truck_ship               -- 17
--             ,gt_daily_data(ln_loop_cnt).others_ship              -- 18
--             ,gt_daily_data(ln_loop_cnt).warehouse_stock          -- 19
--             ,gt_daily_data(ln_loop_cnt).truck_stock              -- 20
--             ,gt_daily_data(ln_loop_cnt).others_stock             -- 21
--             ,gt_daily_data(ln_loop_cnt).change_stock             -- 22
--             ,gt_daily_data(ln_loop_cnt).change_ship              -- 23
--             ,gt_daily_data(ln_loop_cnt).goods_transfer_old       -- 24
--             ,gt_daily_data(ln_loop_cnt).goods_transfer_new       -- 25
--             ,gt_daily_data(ln_loop_cnt).sample_quantity          -- 26
--             ,gt_daily_data(ln_loop_cnt).sample_quantity_b        -- 27
--             ,gt_daily_data(ln_loop_cnt).customer_sample_ship     -- 28
--             ,gt_daily_data(ln_loop_cnt).customer_sample_ship_b   -- 29
--             ,gt_daily_data(ln_loop_cnt).customer_support_ss      -- 30
--             ,gt_daily_data(ln_loop_cnt).customer_support_ss_b    -- 31
--             ,gt_daily_data(ln_loop_cnt).vd_supplement_stock      -- 32
--             ,gt_daily_data(ln_loop_cnt).vd_supplement_ship       -- 33
--             ,gt_daily_data(ln_loop_cnt).inventory_change_in      -- 34
--             ,gt_daily_data(ln_loop_cnt).inventory_change_out     -- 35
--             ,gt_daily_data(ln_loop_cnt).factory_return           -- 36
--             ,gt_daily_data(ln_loop_cnt).factory_return_b         -- 37
--             ,gt_daily_data(ln_loop_cnt).factory_change           -- 38
--             ,gt_daily_data(ln_loop_cnt).factory_change_b         -- 39
--             ,gt_daily_data(ln_loop_cnt).removed_goods            -- 40
--             ,gt_daily_data(ln_loop_cnt).removed_goods_b          -- 41
--             ,gt_daily_data(ln_loop_cnt).factory_stock            -- 42
--             ,gt_daily_data(ln_loop_cnt).factory_stock_b          -- 43
--             ,gt_daily_data(ln_loop_cnt).ccm_sample_ship          -- 44
--             ,gt_daily_data(ln_loop_cnt).ccm_sample_ship_b        -- 45
--             ,gt_daily_data(ln_loop_cnt).wear_decrease            -- 46
--             ,gt_daily_data(ln_loop_cnt).wear_increase            -- 47
--             ,gt_daily_data(ln_loop_cnt).selfbase_ship            -- 48
--             ,gt_daily_data(ln_loop_cnt).selfbase_stock           -- 49
--             ,gt_daily_data(ln_loop_cnt).inv_result               -- 50
--             ,gt_daily_data(ln_loop_cnt).inv_result_bad           -- 51
--             ,gt_daily_data(ln_loop_cnt).inv_wear                 -- 52
--             ,gt_daily_data(ln_loop_cnt).month_begin_quantity     -- 53
--             ,SYSDATE                                             -- 54
--             ,cn_last_updated_by                                  -- 55
--             ,SYSDATE                                             -- 56
--             ,cn_created_by                                       -- 57
--             ,cn_last_update_login                                -- 58
--             ,cn_request_id                                       -- 59
--             ,cn_program_application_id                           -- 60
--             ,cn_program_id                                       -- 61
--             ,SYSDATE                                             -- 62
--            );
--            --
--            -- 月次在庫受払作成フラグON
--            gv_create_flag  :=  cv_on;
--            --
--          ELSE
--            -- 拠点、保管場所、品目単位で、月次在庫受払データが存在する場合
--            -- 更新処理
--            UPDATE  xxcoi_inv_reception_monthly
--            SET     sales_shipped
--                       =   sales_shipped          + gt_daily_data(ln_loop_cnt).sales_shipped            -- 売上出庫
--                   ,sales_shipped_b
--                       =   sales_shipped_b        + gt_daily_data(ln_loop_cnt).sales_shipped_b          -- 売上出庫振戻
--                   ,return_goods
--                       =   return_goods           + gt_daily_data(ln_loop_cnt).return_goods             -- 返品
--                   ,return_goods_b
--                       =   return_goods_b         + gt_daily_data(ln_loop_cnt).return_goods_b           -- 返品振戻
--                   ,warehouse_ship
--                       =   warehouse_ship         + gt_daily_data(ln_loop_cnt).warehouse_ship           -- 倉庫へ返庫
--                   ,truck_ship
--                       =   truck_ship             + gt_daily_data(ln_loop_cnt).truck_ship               -- 営業車へ出庫
--                   ,others_ship
--                       =   others_ship            + gt_daily_data(ln_loop_cnt).others_ship              -- 入出庫＿その他出庫
--                   ,warehouse_stock
--                       =   warehouse_stock        + gt_daily_data(ln_loop_cnt).warehouse_stock          -- 倉庫より入庫
--                   ,truck_stock
--                       =   truck_stock            + gt_daily_data(ln_loop_cnt).truck_stock              -- 営業車より入庫
--                   ,others_stock
--                       =   others_stock           + gt_daily_data(ln_loop_cnt).others_stock             -- 入出庫＿その他入庫
--                   ,change_stock
--                       =   change_stock           + gt_daily_data(ln_loop_cnt).change_stock             -- 倉替入庫
--                   ,change_ship
--                       =   change_ship            + gt_daily_data(ln_loop_cnt).change_ship              -- 倉替出庫
--                   ,goods_transfer_old
--                       =   goods_transfer_old     + gt_daily_data(ln_loop_cnt).goods_transfer_old       -- 商品振替（旧商品）
--                   ,goods_transfer_new
--                       =   goods_transfer_new     + gt_daily_data(ln_loop_cnt).goods_transfer_new       -- 商品振替（新商品）
--                   ,sample_quantity
--                       =   sample_quantity        + gt_daily_data(ln_loop_cnt).sample_quantity          -- 見本出庫
--                   ,sample_quantity_b
--                       =   sample_quantity_b      + gt_daily_data(ln_loop_cnt).sample_quantity_b        -- 見本出庫振戻
--                   ,customer_sample_ship
--                       =   customer_sample_ship   + gt_daily_data(ln_loop_cnt).customer_sample_ship     -- 顧客見本出庫
--                   ,customer_sample_ship_b
--                       =   customer_sample_ship_b + gt_daily_data(ln_loop_cnt).customer_sample_ship_b   -- 顧客見本出庫振戻
--                   ,customer_support_ss
--                       =   customer_support_ss    + gt_daily_data(ln_loop_cnt).customer_support_ss      -- 顧客協賛見本出庫
--                   ,customer_support_ss_b
--                       =   customer_support_ss_b  + gt_daily_data(ln_loop_cnt).customer_support_ss_b    -- 顧客協賛見本出庫振戻
--                   ,vd_supplement_stock
--                       =   vd_supplement_stock    + gt_daily_data(ln_loop_cnt).vd_supplement_stock      -- 消化VD補充入庫
--                   ,vd_supplement_ship
--                       =   vd_supplement_ship     + gt_daily_data(ln_loop_cnt).vd_supplement_ship       -- 消化VD補充出庫
--                   ,inventory_change_in
--                       =   inventory_change_in    + gt_daily_data(ln_loop_cnt).inventory_change_in      -- 基準在庫変更入庫
--                   ,inventory_change_out
--                       =   inventory_change_out   + gt_daily_data(ln_loop_cnt).inventory_change_out     -- 基準在庫変更出庫
--                   ,factory_return
--                       =   factory_return         + gt_daily_data(ln_loop_cnt).factory_return           -- 工場返品
--                   ,factory_return_b
--                       =   factory_return_b       + gt_daily_data(ln_loop_cnt).factory_return_b         -- 工場返品振戻
--                   ,factory_change
--                       =   factory_change         + gt_daily_data(ln_loop_cnt).factory_change           -- 工場倉替
--                   ,factory_change_b
--                       =   factory_change_b       + gt_daily_data(ln_loop_cnt).factory_change_b         -- 工場倉替振戻
--                   ,removed_goods
--                       =   removed_goods          + gt_daily_data(ln_loop_cnt).removed_goods            -- 廃却
--                   ,removed_goods_b
--                       =   removed_goods_b        + gt_daily_data(ln_loop_cnt).removed_goods_b          -- 廃却振戻
--                   ,factory_stock
--                       =   factory_stock          + gt_daily_data(ln_loop_cnt).factory_stock            -- 工場入庫
--                   ,factory_stock_b
--                       =   factory_stock_b        + gt_daily_data(ln_loop_cnt).factory_stock_b          -- 工場入庫振戻
--                   ,ccm_sample_ship
--                       =   ccm_sample_ship        + gt_daily_data(ln_loop_cnt).ccm_sample_ship          -- 顧客広告宣伝費A自社商品
--                   ,ccm_sample_ship_b
--                       =   ccm_sample_ship_b      + gt_daily_data(ln_loop_cnt).ccm_sample_ship_b        -- 顧客広告宣伝費A自社商品振戻
--                   ,wear_decrease
--                       =   wear_decrease          + gt_daily_data(ln_loop_cnt).wear_decrease            -- 棚卸減耗増
--                   ,wear_increase
--                       =   wear_increase          + gt_daily_data(ln_loop_cnt).wear_increase            -- 棚卸減耗減
--                   ,selfbase_ship
--                       =   selfbase_ship          + gt_daily_data(ln_loop_cnt).selfbase_ship            -- 保管場所移動＿自拠点出庫
--                   ,selfbase_stock
--                       =   selfbase_stock         + gt_daily_data(ln_loop_cnt).selfbase_stock           -- 保管場所移動＿自拠点入庫
--                   ,inv_wear
--                       =   inv_wear               + gt_daily_data(ln_loop_cnt).inv_wear                 -- 棚卸減耗
--                   ,last_update_date
--                       =   SYSDATE                                                                      -- 最終更新日
--                   ,last_updated_by
--                       =   cn_last_updated_by                                                           -- 最終更新者
--                   ,last_update_login
--                       =   cn_last_update_login                                                         -- 最終更新ユーザ
--                   ,request_id
--                       =   cn_request_id                                                                -- 要求ID
--                   ,program_application_id
--                       =   cn_program_application_id                                                    -- プログラムアプリケーションID
--                   ,program_id
--                       =   cn_program_id                                                                -- プログラムID
--                   ,program_update_date
--                       =   SYSDATE                                                                      -- プログラム更新日
--            WHERE   inv_seq            =   gt_save_3_inv_seq
--            AND     inventory_item_id  =   gt_daily_data(ln_loop_cnt).inventory_item_id;
--            --
--          END IF;
--        END LOOP daily_set_loop;
--        --
--        -- ループカウンタ、資材取引データ初期化
--        gn_data_cnt   :=  0;
--        gt_daily_data.DELETE;
--      END IF;
--      --
--      -- 各数量を初期化
--      FOR i IN  1 .. 38 LOOP
--        gt_quantity(i)  :=  0;
--      END LOOP;
--    END IF;
--    --
--    IF NOT(daily_trans_cur%NOTFOUND) THEN
--      -- 受払集計（取引タイプ別）
--      CASE  ir_daily_trans.transaction_type
--        WHEN  cv_trans_type_010  THEN   -- 01.売上出庫
--          gt_quantity(1)   :=  gt_quantity(1) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_020  THEN   -- 02.売上出庫振戻
--          gt_quantity(2)   :=  gt_quantity(2) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_030  THEN   -- 03.返品
--          gt_quantity(3)   :=  gt_quantity(3) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_040  THEN   -- 04.返品振戻
--          gt_quantity(4)   :=  gt_quantity(4) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_050  THEN
--          IF (    (ir_daily_trans.transaction_qty    < 0)
--              AND (ir_daily_trans.inventory_type     = cv_subinv_2)
--              AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--             )
--          THEN
--            -- 05.倉庫へ返庫
--            gt_quantity(5)   :=  gt_quantity(5) + ir_daily_trans.transaction_qty;
--          ELSIF (    (ir_daily_trans.transaction_qty    < 0)
--                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--                 AND (ir_daily_trans.subinventory_type  = cv_subinv_2)
--                )
--          THEN
--            -- 06.営業車へ出庫
--            gt_quantity(6)   :=  gt_quantity(6) + ir_daily_trans.transaction_qty;
--          ELSIF (    (ir_daily_trans.transaction_qty    < 0)
--                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--                 AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--                )
--          THEN
--            -- 07.入出庫＿その他出庫
--            gt_quantity(7)   :=  gt_quantity(7) + ir_daily_trans.transaction_qty;
--          ELSIF (    (ir_daily_trans.transaction_qty    > 0)
--                 AND (ir_daily_trans.inventory_type     = cv_subinv_2)
--                 AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--                )
--          THEN
--            -- 08.倉庫より入庫
--            gt_quantity(8)   :=  gt_quantity(8) + ir_daily_trans.transaction_qty;
--          ELSIF (    (ir_daily_trans.transaction_qty    > 0)
--                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--                 AND (ir_daily_trans.subinventory_type  = cv_subinv_2)
--                )
--          THEN
--            -- 09.営業車より入庫
--            gt_quantity(9)   :=  gt_quantity(9) + ir_daily_trans.transaction_qty;
--          ELSIF (    (ir_daily_trans.transaction_qty    > 0)
--                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--                 AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--                )
--          THEN
--            -- 10.入出庫＿その他入庫
--            gt_quantity(10)  :=  gt_quantity(10) + ir_daily_trans.transaction_qty;
--          END IF;
--        WHEN  cv_trans_type_060  THEN
---- == 2009/05/14 V1.9 Modified START ===============================================================
----          IF (ir_daily_trans.transaction_qty >= 0) THEN
----            -- 11.倉替入庫
----            gt_quantity(11)  :=  gt_quantity(11) + ir_daily_trans.transaction_qty;
----          ELSIF (ir_daily_trans.transaction_qty < 0) THEN
----            -- 12.倉替出庫
----            gt_quantity(12)  :=  gt_quantity(12) + ir_daily_trans.transaction_qty;
----          END IF;
----
--          IF (    (ir_daily_trans.transaction_qty    < 0)
--              AND (ir_daily_trans.inventory_type     = cv_subinv_2)
--              AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--             )
--          THEN
--            -- 05.倉庫へ返庫
--            gt_quantity(5)   :=  gt_quantity(5) + ir_daily_trans.transaction_qty;
--          ELSIF (    (ir_daily_trans.transaction_qty    < 0)
--                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--                 AND (ir_daily_trans.subinventory_type  = cv_subinv_2)
--                )
--          THEN
--            -- 06.営業車へ出庫
--            gt_quantity(6)   :=  gt_quantity(6) + ir_daily_trans.transaction_qty;
--          ELSIF (    (ir_daily_trans.transaction_qty    < 0)
--                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--                 AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--                )
--          THEN
--            -- 12.倉替出庫
--            gt_quantity(12)  :=  gt_quantity(12) + ir_daily_trans.transaction_qty;
--          ELSIF (    (ir_daily_trans.transaction_qty    > 0)
--                 AND (ir_daily_trans.inventory_type     = cv_subinv_2)
--                 AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--                )
--          THEN
--            -- 08.倉庫より入庫
--            gt_quantity(8)   :=  gt_quantity(8) + ir_daily_trans.transaction_qty;
--          ELSIF (    (ir_daily_trans.transaction_qty    > 0)
--                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--                 AND (ir_daily_trans.subinventory_type  = cv_subinv_2)
--                )
--          THEN
--            -- 09.営業車より入庫
--            gt_quantity(9)   :=  gt_quantity(9) + ir_daily_trans.transaction_qty;
--          ELSIF (    (ir_daily_trans.transaction_qty    > 0)
--                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--                 AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
--                )
--          THEN
--            -- 11.倉替入庫
--            gt_quantity(11)  :=  gt_quantity(11) + ir_daily_trans.transaction_qty;
--          END IF;
---- == 2009/05/14 V1.9 Modified END   ===============================================================
--        WHEN  cv_trans_type_070  THEN   -- 13.商品振替（旧商品）
--          gt_quantity(13)  :=  gt_quantity(13) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_080  THEN   -- 14.商品振替（新商品）
--          gt_quantity(14)  :=  gt_quantity(14) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_090  THEN   -- 15.見本出庫
--          gt_quantity(15)  :=  gt_quantity(15) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_100 THEN   -- 16.見本出庫振戻
--          gt_quantity(16)  :=  gt_quantity(16) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_110 THEN   -- 17.顧客見本出庫
--          gt_quantity(17)  :=  gt_quantity(17) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_120 THEN   -- 18.顧客見本出庫振戻
--          gt_quantity(18)  :=  gt_quantity(18) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_130 THEN   -- 19.顧客協賛見本出庫
--          gt_quantity(19)  :=  gt_quantity(19) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_140 THEN   -- 20.顧客協賛見本出庫振戻
--          gt_quantity(20)  :=  gt_quantity(20) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_150 THEN
--          IF (ir_daily_trans.transaction_qty >= 0) THEN
--            -- 21.消化VD補充入庫
--            gt_quantity(21)  :=  gt_quantity(21) + ir_daily_trans.transaction_qty;
--          ELSIF (ir_daily_trans.transaction_qty < 0) THEN
--            -- 22.消化VD補充出庫
--            gt_quantity(22)  :=  gt_quantity(22) + ir_daily_trans.transaction_qty;
--          END IF;
--        WHEN  cv_trans_type_160 THEN
---- == 2009/06/04 V1.11 Modified START ===============================================================
----          IF (ir_daily_trans.transaction_qty   >= 0) THEN
----            -- 23.基準在庫変更入庫
----            gt_quantity(23)  :=  gt_quantity(23) + ir_daily_trans.transaction_qty;
----          ELSIF (ir_daily_trans.transaction_qty < 0) THEN
----            -- 24.基準在庫変更出庫
----            gt_quantity(24)  :=  gt_quantity(24) + ir_daily_trans.transaction_qty;
----          END IF;
----
--          IF (ir_daily_trans.subinv_class = cv_subinv_class_7)  THEN
--            -- 消化VDは対象外
--            NULL;
--          ELSIF (ir_daily_trans.transaction_qty   >= 0) THEN
--            -- 23.基準在庫変更入庫
--            gt_quantity(23)  :=  gt_quantity(23) + ir_daily_trans.transaction_qty;
--          ELSIF (ir_daily_trans.transaction_qty < 0) THEN
--            -- 24.基準在庫変更出庫
--            gt_quantity(24)  :=  gt_quantity(24) + ir_daily_trans.transaction_qty;
--          END IF;
---- == 2009/06/04 V1.11 Modified END   ===============================================================
--        WHEN  cv_trans_type_170 THEN   -- 25.工場返品
--          gt_quantity(25)  :=  gt_quantity(25) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_180 THEN   -- 26.工場返品振戻
--          gt_quantity(26)  :=  gt_quantity(26) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_190 THEN   -- 27.工場倉替
--          gt_quantity(27)  :=  gt_quantity(27) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_200 THEN   -- 28.工場倉替振戻
--          gt_quantity(28)  :=  gt_quantity(28) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_210 THEN   -- 29.廃却
--          gt_quantity(29)  :=  gt_quantity(29) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_220 THEN   -- 30.廃却振戻
--          gt_quantity(30)  :=  gt_quantity(30) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_230 THEN   -- 31.工場入庫
--          gt_quantity(31)  :=  gt_quantity(31) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_240 THEN   -- 32.工場入庫振戻
--          gt_quantity(32)  :=  gt_quantity(32) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_250 THEN   -- 33.顧客広告宣伝費A自社商品
--          gt_quantity(33)  :=  gt_quantity(33) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_260 THEN   -- 34.顧客広告宣伝費A自社商品振戻
--          gt_quantity(34)  :=  gt_quantity(34) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_270 THEN   -- 35.棚卸減耗増
--          gt_quantity(35)  :=  gt_quantity(35) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_280 THEN   -- 36.棚卸減耗減
--          gt_quantity(36)  :=  gt_quantity(36) + ir_daily_trans.transaction_qty;
--        WHEN  cv_trans_type_290 THEN
---- == 2009/05/11 V1.8 Deleted START ===============================================================
----          IF (ir_daily_trans.base_code = ir_daily_trans.sub_base_code) THEN
---- == 2009/05/11 V1.8 Deleted END   ===============================================================
--            IF (ir_daily_trans.transaction_qty < 0) THEN
--              -- 37.保管場所移動＿自拠点出庫
--              gt_quantity(37)  :=  gt_quantity(37) + ir_daily_trans.transaction_qty;
--            ELSIF (ir_daily_trans.transaction_qty >= 0) THEN
--              -- 38.保管場所移動＿自拠点入庫
--              gt_quantity(38)  :=  gt_quantity(38) + ir_daily_trans.transaction_qty;
--            END IF;
---- == 2009/05/11 V1.8 Deleted START ===============================================================
----          END IF;
---- == 2009/05/11 V1.8 Deleted END   ===============================================================
--        ELSE  NULL;
--      END CASE;
--    END IF;
--    --
--  EXCEPTION
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
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
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END ins_daily_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_daily_data
   * Description      : 月次在庫受払出力（当日取引データ）(A-10)
   ***********************************************************************************/
  PROCEDURE ins_daily_data(
    it_base_code      IN  xxcoi_inv_control.base_code%TYPE,
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_daily_data'; -- プログラム名
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
    ln_dummy              NUMBER;       -- ダミー変数
    lt_operation_cost     cm_cmpt_dtl.cmpnt_cost%TYPE;      -- 営業原価
    lt_standard_cost      cst_item_costs.item_cost%TYPE;    -- 標準原価
    ln_exec_flag          NUMBER;
    ln_inventory_seq      NUMBER;
    --
    lt_key_base_code            xxcoi_inv_reception_monthly.base_code%TYPE;
    lt_key_subinv_code          xxcoi_inv_reception_monthly.subinventory_code%TYPE;
    lt_key_subinv_type          xxcoi_inv_reception_monthly.subinventory_type%TYPE;
    lt_key_inventory_item_id    xxcoi_inv_reception_monthly.inventory_item_id%TYPE;
    lt_key_inventory_seq        xxcoi_inv_reception_monthly.inv_seq%TYPE;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- キー項目初期化
    lt_key_base_code            :=  NULL;
    lt_key_subinv_code          :=  NULL;
    lt_key_subinv_type          :=  NULL;
    lt_key_inventory_item_id    :=  NULL;
    lt_key_inventory_seq        :=  NULL;
    --
    -- ================================================
    --  A-9.当日取引データ取得（CURSOR:daily_trans_cur)
    -- ================================================
    OPEN  daily_trans_cur(
            iv_base_code        =>  it_base_code              -- 拠点コード
          );
    --
    <<the_day_output_loop>>   -- 当日取引出力LOOP
    LOOP
      FETCH daily_trans_cur INTO  daily_trans_rec;
      --
      IF ((lt_key_subinv_code IS NOT NULL)
          AND
          ((lt_key_subinv_code <> daily_trans_rec.subinventory_code)
           OR
           (lt_key_inventory_item_id <> daily_trans_rec.inventory_item_id)
           OR
           (daily_trans_cur%NOTFOUND)
          )
         )
      THEN
        -- 受払項目を集計しており、保管場所が変更された、品目が変更された、最終データの集計が完了のいずれかの状態の場合
        -- 月次在庫受払を作成し、受払集計項目を初期化する
        IF (    (gt_quantity(1)  = 0)
            AND (gt_quantity(2)  = 0)
            AND (gt_quantity(3)  = 0)
            AND (gt_quantity(4)  = 0)
            AND (gt_quantity(5)  = 0)
            AND (gt_quantity(6)  = 0)
            AND (gt_quantity(7)  = 0)
            AND (gt_quantity(8)  = 0)
            AND (gt_quantity(9)  = 0)
            AND (gt_quantity(10) = 0)
            AND (gt_quantity(11) = 0)
            AND (gt_quantity(12) = 0)
            AND (gt_quantity(13) = 0)
            AND (gt_quantity(14) = 0)
            AND (gt_quantity(15) = 0)
            AND (gt_quantity(16) = 0)
            AND (gt_quantity(17) = 0)
            AND (gt_quantity(18) = 0)
            AND (gt_quantity(19) = 0)
            AND (gt_quantity(20) = 0)
            AND (gt_quantity(21) = 0)
            AND (gt_quantity(22) = 0)
            AND (gt_quantity(23) = 0)
            AND (gt_quantity(24) = 0)
            AND (gt_quantity(25) = 0)
            AND (gt_quantity(26) = 0)
            AND (gt_quantity(27) = 0)
            AND (gt_quantity(28) = 0)
            AND (gt_quantity(29) = 0)
            AND (gt_quantity(30) = 0)
            AND (gt_quantity(31) = 0)
            AND (gt_quantity(32) = 0)
            AND (gt_quantity(33) = 0)
            AND (gt_quantity(34) = 0)
            AND (gt_quantity(35) = 0)
            AND (gt_quantity(36) = 0)
            AND (gt_quantity(37) = 0)
            AND (gt_quantity(38) = 0)
           )
        THEN
          -- 集計項目が全て０の場合、月次受払情報を作成しない
          NULL;
        ELSIF (lt_key_inventory_seq IS NULL) THEN
          -- 当月の月次受払データが存在しない場合、新規作成
          --
          -- ===================================
          --  2.標準原価取得
          -- ===================================
          xxcoi_common_pkg.get_cmpnt_cost(
            in_item_id      =>  lt_key_inventory_item_id    -- 品目ID
           ,in_org_id       =>  gn_f_organization_id        -- 組織ID
           ,id_period_date  =>  gd_f_process_date           -- 対象日
           ,ov_cmpnt_cost   =>  lt_standard_cost            -- 標準原価
           ,ov_errbuf       =>  lv_errbuf                   -- エラーメッセージ
           ,ov_retcode      =>  lv_retcode                  -- リターン・コード
           ,ov_errmsg       =>  lv_errmsg                   -- ユーザー・エラーメッセージ
          );
          -- 終了パラメータ判定
          IF ((lv_retcode = cv_status_error)
              OR
              (lt_standard_cost IS NULL)
             )
          THEN
            lv_errmsg   := xxccp_common_pkg.get_msg(
                             iv_application  => cv_short_name
                            ,iv_name         => cv_msg_xxcoi1_10285
                           );
            lv_errbuf   := lv_errmsg;
            RAISE global_api_expt;
          END IF;
          --
          -- ===================================
          --  3.営業原価取得
          -- ===================================
          xxcoi_common_pkg.get_discrete_cost(
            in_item_id        =>  lt_key_inventory_item_id    -- 品目ID
           ,in_org_id         =>  gn_f_organization_id        -- 組織ID
           ,id_target_date    =>  gd_f_process_date           -- 対象日
           ,ov_discrete_cost  =>  lt_operation_cost           -- 営業原価
           ,ov_errbuf         =>  lv_errbuf                   -- エラーメッセージ
           ,ov_retcode        =>  lv_retcode                  -- リターン・コード
           ,ov_errmsg         =>  lv_errmsg                   -- ユーザー・エラーメッセージ
          );
          -- 終了パラメータ判定
          IF ((lv_retcode = cv_status_error)
              OR
              (lt_operation_cost IS NULL)
             )
          THEN
            lv_errmsg   := xxccp_common_pkg.get_msg(
                             iv_application  => cv_short_name
                            ,iv_name         => cv_msg_xxcoi1_10293
                           );
            lv_errbuf   := lv_errmsg;
            RAISE global_api_expt;
          END IF;
          --
          -- ===================================
          --  4.月次在庫受払テーブル出力
          -- ===================================
          INSERT INTO xxcoi_inv_reception_monthly(
            inv_seq                                   -- 01.棚卸SEQ
           ,base_code                                 -- 02.拠点コード
           ,organization_id                           -- 03.組織ID
           ,subinventory_code                         -- 04.保管場所
           ,subinventory_type                         -- 05.保管場所区分
           ,practice_month                            -- 06.年月
           ,practice_date                             -- 07.年月日
           ,inventory_kbn                             -- 08.棚卸区分
           ,inventory_item_id                         -- 09.品目ID
           ,operation_cost                            -- 10.営業原価
           ,standard_cost                             -- 11.標準原価
           ,sales_shipped                             -- 12.売上出庫
           ,sales_shipped_b                           -- 13.売上出庫振戻
           ,return_goods                              -- 14.返品
           ,return_goods_b                            -- 15.返品振戻
           ,warehouse_ship                            -- 16.倉庫へ返庫
           ,truck_ship                                -- 17.営業車へ出庫
           ,others_ship                               -- 18.入出庫＿その他出庫
           ,warehouse_stock                           -- 19.倉庫より入庫
           ,truck_stock                               -- 20.営業車より入庫
           ,others_stock                              -- 21.入出庫＿その他入庫
           ,change_stock                              -- 22.倉替入庫
           ,change_ship                               -- 23.倉替出庫
           ,goods_transfer_old                        -- 24.商品振替（旧商品）
           ,goods_transfer_new                        -- 25.商品振替（新商品）
           ,sample_quantity                           -- 26.見本出庫
           ,sample_quantity_b                         -- 27.見本出庫振戻
           ,customer_sample_ship                      -- 28.顧客見本出庫
           ,customer_sample_ship_b                    -- 29.顧客見本出庫振戻
           ,customer_support_ss                       -- 30.顧客協賛見本出庫
           ,customer_support_ss_b                     -- 31.顧客協賛見本出庫振戻
           ,vd_supplement_stock                       -- 32.消化VD補充入庫
           ,vd_supplement_ship                        -- 33.消化VD補充出庫
           ,inventory_change_in                       -- 34.基準在庫変更入庫
           ,inventory_change_out                      -- 35.基準在庫変更出庫
           ,factory_return                            -- 36.工場返品
           ,factory_return_b                          -- 37.工場返品振戻
           ,factory_change                            -- 38.工場倉替
           ,factory_change_b                          -- 39.工場倉替振戻
           ,removed_goods                             -- 40.廃却
           ,removed_goods_b                           -- 41.廃却振戻
           ,factory_stock                             -- 42.工場入庫
           ,factory_stock_b                           -- 43.工場入庫振戻
           ,ccm_sample_ship                           -- 44.顧客広告宣伝費A自社商品
           ,ccm_sample_ship_b                         -- 45.顧客広告宣伝費A自社商品振戻
           ,wear_decrease                             -- 46.棚卸減耗増
           ,wear_increase                             -- 47.棚卸減耗減
           ,selfbase_ship                             -- 48.保管場所移動＿自拠点出庫
           ,selfbase_stock                            -- 49.保管場所移動＿自拠点入庫
           ,inv_result                                -- 50.棚卸結果
           ,inv_result_bad                            -- 51.棚卸結果（不良品）
           ,inv_wear                                  -- 52.棚卸減耗
           ,month_begin_quantity                      -- 53.月首棚卸高
           ,last_update_date                          -- 54.最終更新日
           ,last_updated_by                           -- 55.最終更新者
           ,creation_date                             -- 56.作成日
           ,created_by                                -- 57.作成者
           ,last_update_login                         -- 58.最終更新ユーザ
           ,request_id                                -- 59.要求ID
           ,program_application_id                    -- 60.プログラムアプリケーションID
           ,program_id                                -- 61.プログラムID
           ,program_update_date                       -- 62.プログラム更新日
          )VALUES(
            1                                         -- 01
           ,lt_key_base_code                          -- 02
           ,gn_f_organization_id                      -- 03
           ,lt_key_subinv_code                        -- 04
           ,lt_key_subinv_type                        -- 05
           ,gv_f_inv_acct_period                      -- 06
           ,gd_f_process_date                         -- 07
           ,gv_param_inventory_kbn                    -- 08
           ,lt_key_inventory_item_id                  -- 09
           ,TO_NUMBER(lt_operation_cost)              -- 10
           ,TO_NUMBER(lt_standard_cost)               -- 11
           ,gt_quantity(1)  * -1                      -- 12
           ,gt_quantity(2)  *  1                      -- 13
           ,gt_quantity(3)  *  1                      -- 14
           ,gt_quantity(4)  * -1                      -- 15
           ,gt_quantity(5)  * -1                      -- 16
           ,gt_quantity(6)  * -1                      -- 17
           ,gt_quantity(7)  * -1                      -- 18
           ,gt_quantity(8)  *  1                      -- 19
           ,gt_quantity(9)  *  1                      -- 20
           ,gt_quantity(10) *  1                      -- 21
           ,gt_quantity(11) *  1                      -- 22
           ,gt_quantity(12) * -1                      -- 23
           ,gt_quantity(13) * -1                      -- 24
           ,gt_quantity(14) *  1                      -- 25
           ,gt_quantity(15) * -1                      -- 26
           ,gt_quantity(16) *  1                      -- 27
           ,gt_quantity(17) * -1                      -- 28
           ,gt_quantity(18) *  1                      -- 29
           ,gt_quantity(19) * -1                      -- 30
           ,gt_quantity(20) *  1                      -- 31
           ,gt_quantity(21) *  1                      -- 32
           ,gt_quantity(22) * -1                      -- 33
           ,gt_quantity(23) *  1                      -- 34
           ,gt_quantity(24) * -1                      -- 35
           ,gt_quantity(25) * -1                      -- 36
           ,gt_quantity(26) *  1                      -- 37
           ,gt_quantity(27) * -1                      -- 38
           ,gt_quantity(28) *  1                      -- 39
           ,gt_quantity(29) * -1                      -- 40
           ,gt_quantity(30) *  1                      -- 41
           ,gt_quantity(31) *  1                      -- 42
           ,gt_quantity(32) * -1                      -- 43
           ,gt_quantity(33) * -1                      -- 44
           ,gt_quantity(34) *  1                      -- 45
           ,gt_quantity(35) *  1                      -- 46
           ,gt_quantity(36) * -1                      -- 47
           ,gt_quantity(37) * -1                      -- 48
           ,gt_quantity(38) *  1                      -- 49
           ,0                                         -- 50
           ,0                                         -- 51
           ,  gt_quantity(1)  + gt_quantity(2)  + gt_quantity(3)  + gt_quantity(4)
            + gt_quantity(5)  + gt_quantity(6)  + gt_quantity(7)  + gt_quantity(8)
            + gt_quantity(9)  + gt_quantity(10) + gt_quantity(11) + gt_quantity(12)
            + gt_quantity(13) + gt_quantity(14) + gt_quantity(15) + gt_quantity(16)
            + gt_quantity(17) + gt_quantity(18) + gt_quantity(19) + gt_quantity(20)
            + gt_quantity(21) + gt_quantity(22) + gt_quantity(23) + gt_quantity(24)
            + gt_quantity(25) + gt_quantity(26) + gt_quantity(27) + gt_quantity(28)
            + gt_quantity(29) + gt_quantity(30) + gt_quantity(31) + gt_quantity(32)
            + gt_quantity(33) + gt_quantity(34) + gt_quantity(35) + gt_quantity(36)
            + gt_quantity(37) + gt_quantity(38)       -- 52
           ,0                                         -- 53
           ,SYSDATE                                   -- 54
           ,cn_last_updated_by                        -- 55
           ,SYSDATE                                   -- 56
           ,cn_created_by                             -- 57
           ,cn_last_update_login                      -- 58
           ,cn_request_id                             -- 59
           ,cn_program_application_id                 -- 60
           ,cn_program_id                             -- 61
           ,SYSDATE                                   -- 62
          );
          --
          -- 成功件数（月次在庫受払の作成レコード数）
          gn_target_cnt :=  gn_target_cnt + 1;
          gn_normal_cnt :=  gn_normal_cnt + 1;
          -- 
        ELSE
          -- 当月の月次受払データが存在する場合、受払項目を更新
          UPDATE  xxcoi_inv_reception_monthly
          SET     sales_shipped           =   sales_shipped          + gt_quantity(1)  * -1         -- 売上出庫
                 ,sales_shipped_b         =   sales_shipped_b        + gt_quantity(2)  *  1         -- 売上出庫振戻
                 ,return_goods            =   return_goods           + gt_quantity(3)  *  1         -- 返品
                 ,return_goods_b          =   return_goods_b         + gt_quantity(4)  * -1         -- 返品振戻
                 ,warehouse_ship          =   warehouse_ship         + gt_quantity(5)  * -1         -- 倉庫へ返庫
                 ,truck_ship              =   truck_ship             + gt_quantity(6)  * -1         -- 営業車へ出庫
                 ,others_ship             =   others_ship            + gt_quantity(7)  * -1         -- 入出庫＿その他出庫
                 ,warehouse_stock         =   warehouse_stock        + gt_quantity(8)  *  1         -- 倉庫より入庫
                 ,truck_stock             =   truck_stock            + gt_quantity(9)  *  1         -- 営業車より入庫
                 ,others_stock            =   others_stock           + gt_quantity(10) *  1         -- 入出庫＿その他入庫
                 ,change_stock            =   change_stock           + gt_quantity(11) *  1         -- 倉替入庫
                 ,change_ship             =   change_ship            + gt_quantity(12) * -1         -- 倉替出庫
                 ,goods_transfer_old      =   goods_transfer_old     + gt_quantity(13) * -1         -- 商品振替（旧商品）
                 ,goods_transfer_new      =   goods_transfer_new     + gt_quantity(14) *  1         -- 商品振替（新商品）
                 ,sample_quantity         =   sample_quantity        + gt_quantity(15) * -1         -- 見本出庫
                 ,sample_quantity_b       =   sample_quantity_b      + gt_quantity(16) *  1         -- 見本出庫振戻
                 ,customer_sample_ship    =   customer_sample_ship   + gt_quantity(17) * -1         -- 顧客見本出庫
                 ,customer_sample_ship_b  =   customer_sample_ship_b + gt_quantity(18) *  1         -- 顧客見本出庫振戻
                 ,customer_support_ss     =   customer_support_ss    + gt_quantity(19) * -1         -- 顧客協賛見本出庫
                 ,customer_support_ss_b   =   customer_support_ss_b  + gt_quantity(20) *  1         -- 顧客協賛見本出庫振戻
                 ,vd_supplement_stock     =   vd_supplement_stock    + gt_quantity(21) *  1         -- 消化VD補充入庫
                 ,vd_supplement_ship      =   vd_supplement_ship     + gt_quantity(22) * -1         -- 消化VD補充出庫
                 ,inventory_change_in     =   inventory_change_in    + gt_quantity(23) *  1         -- 基準在庫変更入庫
                 ,inventory_change_out    =   inventory_change_out   + gt_quantity(24) * -1         -- 基準在庫変更出庫
                 ,factory_return          =   factory_return         + gt_quantity(25) * -1         -- 工場返品
                 ,factory_return_b        =   factory_return_b       + gt_quantity(26) *  1         -- 工場返品振戻
                 ,factory_change          =   factory_change         + gt_quantity(27) * -1         -- 工場倉替
                 ,factory_change_b        =   factory_change_b       + gt_quantity(28) *  1         -- 工場倉替振戻
                 ,removed_goods           =   removed_goods          + gt_quantity(29) * -1         -- 廃却
                 ,removed_goods_b         =   removed_goods_b        + gt_quantity(30) *  1         -- 廃却振戻
                 ,factory_stock           =   factory_stock          + gt_quantity(31) *  1         -- 工場入庫
                 ,factory_stock_b         =   factory_stock_b        + gt_quantity(32) * -1         -- 工場入庫振戻
                 ,ccm_sample_ship         =   ccm_sample_ship        + gt_quantity(33) * -1         -- 顧客広告宣伝費A自社商品
                 ,ccm_sample_ship_b       =   ccm_sample_ship_b      + gt_quantity(34) *  1         -- 顧客広告宣伝費A自社商品振戻
                 ,wear_decrease           =   wear_decrease          + gt_quantity(35) *  1         -- 棚卸減耗増
                 ,wear_increase           =   wear_increase          + gt_quantity(36) * -1         -- 棚卸減耗減
                 ,selfbase_ship           =   selfbase_ship          + gt_quantity(37) * -1         -- 保管場所移動＿自拠点出庫
                 ,selfbase_stock          =   selfbase_stock         + gt_quantity(38) *  1         -- 保管場所移動＿自拠点入庫
                 ,inv_wear                =   inv_wear               + gt_quantity(1)  + gt_quantity(2)  + gt_quantity(3)  + gt_quantity(4)
                                                                     + gt_quantity(5)  + gt_quantity(6)  + gt_quantity(7)  + gt_quantity(8)
                                                                     + gt_quantity(9)  + gt_quantity(10) + gt_quantity(11) + gt_quantity(12)
                                                                     + gt_quantity(13) + gt_quantity(14) + gt_quantity(15) + gt_quantity(16)
                                                                     + gt_quantity(17) + gt_quantity(18) + gt_quantity(19) + gt_quantity(20)
                                                                     + gt_quantity(21) + gt_quantity(22) + gt_quantity(23) + gt_quantity(24)
                                                                     + gt_quantity(25) + gt_quantity(26) + gt_quantity(27) + gt_quantity(28)
                                                                     + gt_quantity(29) + gt_quantity(30) + gt_quantity(31) + gt_quantity(32)
                                                                     + gt_quantity(33) + gt_quantity(34) + gt_quantity(35) + gt_quantity(36)
                                                                     + gt_quantity(37) + gt_quantity(38)
                                                                                                    -- 棚卸減耗
                 ,last_update_date        =   SYSDATE                                               -- 最終更新日
                 ,last_updated_by         =   cn_last_updated_by                                    -- 最終更新者
                 ,last_update_login       =   cn_last_update_login                                  -- 最終更新ユーザ
                 ,request_id              =   cn_request_id                                         -- 要求ID
                 ,program_application_id  =   cn_program_application_id                             -- プログラムアプリケーションID
                 ,program_id              =   cn_program_id                                         -- プログラムID
                 ,program_update_date     =   SYSDATE                                               -- プログラム更新日
          WHERE   base_code               =   lt_key_base_code
          AND     subinventory_code       =   lt_key_subinv_code
          AND     inventory_item_id       =   lt_key_inventory_item_id
          AND     organization_id         =   gn_f_organization_id
          AND     inventory_kbn           =   gv_param_inventory_kbn
          AND     practice_month          =   gv_f_inv_acct_period;
        END IF;
        --
        -- 受払集計項目初期化
        FOR i IN  1 .. 38 LOOP
          gt_quantity(i)  :=  0;
        END LOOP;
      END IF;
      --
      -- ===================================
      --  受払項目集計
      -- ===================================
      -- 保管場所、品目が同一のデータについては、取引タイプ毎に取引数量を集計する
      IF NOT(daily_trans_cur%NOTFOUND) THEN
        -- 受払集計（取引タイプ別）
        CASE  daily_trans_rec.transaction_type
          WHEN  cv_trans_type_010  THEN   -- 01.売上出庫
            gt_quantity(1)   :=  gt_quantity(1) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_020  THEN   -- 02.売上出庫振戻
            gt_quantity(2)   :=  gt_quantity(2) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_030  THEN   -- 03.返品
            gt_quantity(3)   :=  gt_quantity(3) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_040  THEN   -- 04.返品振戻
            gt_quantity(4)   :=  gt_quantity(4) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_050  THEN
            IF (    (daily_trans_rec.transaction_qty    < 0)
                AND (daily_trans_rec.inventory_type     = cv_subinv_2)
                AND (daily_trans_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
               )
            THEN
              -- 05.倉庫へ返庫
              gt_quantity(5)   :=  gt_quantity(5) + daily_trans_rec.transaction_qty;
            ELSIF (    (daily_trans_rec.transaction_qty    < 0)
                   AND (daily_trans_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                   AND (daily_trans_rec.subinventory_type  = cv_subinv_2)
                  )
            THEN
              -- 06.営業車へ出庫
              gt_quantity(6)   :=  gt_quantity(6) + daily_trans_rec.transaction_qty;
            ELSIF (    (daily_trans_rec.transaction_qty    < 0)
                   AND (daily_trans_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                   AND (daily_trans_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                  )
            THEN
              -- 07.入出庫＿その他出庫
              gt_quantity(7)   :=  gt_quantity(7) + daily_trans_rec.transaction_qty;
            ELSIF (    (daily_trans_rec.transaction_qty    > 0)
                   AND (daily_trans_rec.inventory_type     = cv_subinv_2)
                   AND (daily_trans_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                  )
            THEN
              -- 08.倉庫より入庫
              gt_quantity(8)   :=  gt_quantity(8) + daily_trans_rec.transaction_qty;
            ELSIF (    (daily_trans_rec.transaction_qty    > 0)
                   AND (daily_trans_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                   AND (daily_trans_rec.subinventory_type  = cv_subinv_2)
                  )
            THEN
              -- 09.営業車より入庫
              gt_quantity(9)   :=  gt_quantity(9) + daily_trans_rec.transaction_qty;
            ELSIF (    (daily_trans_rec.transaction_qty    > 0)
                   AND (daily_trans_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                   AND (daily_trans_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                  )
            THEN
              -- 10.入出庫＿その他入庫
              gt_quantity(10)  :=  gt_quantity(10) + daily_trans_rec.transaction_qty;
            END IF;
          WHEN  cv_trans_type_060  THEN
            IF (    (daily_trans_rec.transaction_qty    < 0)
                AND (daily_trans_rec.inventory_type     = cv_subinv_2)
                AND (daily_trans_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
               )
            THEN
              -- 05.倉庫へ返庫
              gt_quantity(5)   :=  gt_quantity(5) + daily_trans_rec.transaction_qty;
            ELSIF (    (daily_trans_rec.transaction_qty    < 0)
                   AND (daily_trans_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                   AND (daily_trans_rec.subinventory_type  = cv_subinv_2)
                  )
            THEN
              -- 06.営業車へ出庫
              gt_quantity(6)   :=  gt_quantity(6) + daily_trans_rec.transaction_qty;
            ELSIF (    (daily_trans_rec.transaction_qty    < 0)
                   AND (daily_trans_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                   AND (daily_trans_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                  )
            THEN
              -- 12.倉替出庫
              gt_quantity(12)  :=  gt_quantity(12) + daily_trans_rec.transaction_qty;
            ELSIF (    (daily_trans_rec.transaction_qty    > 0)
                   AND (daily_trans_rec.inventory_type     = cv_subinv_2)
                   AND (daily_trans_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                  )
            THEN
              -- 08.倉庫より入庫
              gt_quantity(8)   :=  gt_quantity(8) + daily_trans_rec.transaction_qty;
            ELSIF (    (daily_trans_rec.transaction_qty    > 0)
                   AND (daily_trans_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                   AND (daily_trans_rec.subinventory_type  = cv_subinv_2)
                  )
            THEN
              -- 09.営業車より入庫
              gt_quantity(9)   :=  gt_quantity(9) + daily_trans_rec.transaction_qty;
            ELSIF (    (daily_trans_rec.transaction_qty    > 0)
                   AND (daily_trans_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                   AND (daily_trans_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                  )
            THEN
              -- 11.倉替入庫
              gt_quantity(11)  :=  gt_quantity(11) + daily_trans_rec.transaction_qty;
            END IF;
          WHEN  cv_trans_type_070  THEN   -- 13.商品振替（旧商品）
            gt_quantity(13)  :=  gt_quantity(13) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_080  THEN   -- 14.商品振替（新商品）
            gt_quantity(14)  :=  gt_quantity(14) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_090  THEN   -- 15.見本出庫
            gt_quantity(15)  :=  gt_quantity(15) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_100 THEN   -- 16.見本出庫振戻
            gt_quantity(16)  :=  gt_quantity(16) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_110 THEN   -- 17.顧客見本出庫
            gt_quantity(17)  :=  gt_quantity(17) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_120 THEN   -- 18.顧客見本出庫振戻
            gt_quantity(18)  :=  gt_quantity(18) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_130 THEN   -- 19.顧客協賛見本出庫
            gt_quantity(19)  :=  gt_quantity(19) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_140 THEN   -- 20.顧客協賛見本出庫振戻
            gt_quantity(20)  :=  gt_quantity(20) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_150 THEN
            IF (daily_trans_rec.transaction_qty >= 0) THEN
              -- 21.消化VD補充入庫
              gt_quantity(21)  :=  gt_quantity(21) + daily_trans_rec.transaction_qty;
            ELSIF (daily_trans_rec.transaction_qty < 0) THEN
              -- 22.消化VD補充出庫
              gt_quantity(22)  :=  gt_quantity(22) + daily_trans_rec.transaction_qty;
            END IF;
          WHEN  cv_trans_type_160 THEN
            IF (daily_trans_rec.subinv_class = cv_subinv_class_7)  THEN
              -- 消化VDは対象外
              NULL;
            ELSIF (daily_trans_rec.transaction_qty   >= 0) THEN
              -- 23.基準在庫変更入庫
              gt_quantity(23)  :=  gt_quantity(23) + daily_trans_rec.transaction_qty;
            ELSIF (daily_trans_rec.transaction_qty < 0) THEN
              -- 24.基準在庫変更出庫
              gt_quantity(24)  :=  gt_quantity(24) + daily_trans_rec.transaction_qty;
            END IF;
          WHEN  cv_trans_type_170 THEN   -- 25.工場返品
            gt_quantity(25)  :=  gt_quantity(25) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_180 THEN   -- 26.工場返品振戻
            gt_quantity(26)  :=  gt_quantity(26) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_190 THEN   -- 27.工場倉替
            gt_quantity(27)  :=  gt_quantity(27) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_200 THEN   -- 28.工場倉替振戻
            gt_quantity(28)  :=  gt_quantity(28) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_210 THEN   -- 29.廃却
            gt_quantity(29)  :=  gt_quantity(29) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_220 THEN   -- 30.廃却振戻
            gt_quantity(30)  :=  gt_quantity(30) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_230 THEN   -- 31.工場入庫
            gt_quantity(31)  :=  gt_quantity(31) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_240 THEN   -- 32.工場入庫振戻
            gt_quantity(32)  :=  gt_quantity(32) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_250 THEN   -- 33.顧客広告宣伝費A自社商品
            gt_quantity(33)  :=  gt_quantity(33) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_260 THEN   -- 34.顧客広告宣伝費A自社商品振戻
            gt_quantity(34)  :=  gt_quantity(34) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_270 THEN   -- 35.棚卸減耗増
            gt_quantity(35)  :=  gt_quantity(35) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_280 THEN   -- 36.棚卸減耗減
            gt_quantity(36)  :=  gt_quantity(36) + daily_trans_rec.transaction_qty;
          WHEN  cv_trans_type_290 THEN
            IF (daily_trans_rec.transaction_qty < 0) THEN
              -- 37.保管場所移動＿自拠点出庫
              gt_quantity(37)  :=  gt_quantity(37) + daily_trans_rec.transaction_qty;
            ELSIF (daily_trans_rec.transaction_qty >= 0) THEN
              -- 38.保管場所移動＿自拠点入庫
              gt_quantity(38)  :=  gt_quantity(38) + daily_trans_rec.transaction_qty;
            END IF;
          ELSE  NULL;
        END CASE;
      END IF;
      --
      -- 終了判定
      EXIT  the_day_output_loop WHEN  daily_trans_cur%NOTFOUND;
      --
      -- キー情報を保持
      lt_key_base_code            :=  daily_trans_rec.base_code;
      lt_key_subinv_code          :=  daily_trans_rec.subinventory_code;
      lt_key_subinv_type          :=  daily_trans_rec.inventory_type;
      lt_key_inventory_item_id    :=  daily_trans_rec.inventory_item_id;
      lt_key_inventory_seq        :=  daily_trans_rec.inventory_seq;
      --
    END LOOP the_day_output_loop;
    --
    -- =======================================
    --  CURSORクローズ
    -- =======================================
    CLOSE daily_trans_cur;
    --
  EXCEPTION
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
  END ins_daily_data;
-- == 2009/08/20 V1.14 Modified END    ===============================================================
--
-- == 2009/08/20 V1.14 Modified START ===============================================================
--  /**********************************************************************************
--   * Procedure Name   : upd_inv_control
--   * Description      : 棚卸管理出力（棚卸結果データ）(A-8)
--   ***********************************************************************************/
--  PROCEDURE upd_inv_control(
--    ir_inv_result     IN  inv_result_1_cur%ROWTYPE,     -- 1.棚卸結果情報
--    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
--    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
--    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_inv_control'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
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
--    ln_dummy      NUMBER;             -- ダミー変数
--    ld_end_date   DATE;               -- 棚卸日の範囲（終端）
----
--    -- ===============================
--    -- ローカル・カーソル
--    -- ===============================
--    -- <カーソル名>
--    CURSOR  xic_lock_cur
--    IS
--      SELECT  1
--      INTO    ln_dummy
--      FROM    xxcoi_inv_control   xic     -- 棚卸管理テーブル
--      WHERE   subinventory_code       =   ir_inv_result.subinventory_code
--      AND     inventory_status        =   cv_invsts_1
--      AND     inventory_kbn           =   gv_param_inventory_kbn
--      AND     inventory_date  BETWEEN TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
--                              AND     ld_end_date
--      FOR UPDATE NOWAIT;
--    --
--    -- <カーソル名>レコード型
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ***************************************
--    -- ***        ループ処理の記述         ***
--    -- ***       処理部の呼び出し          ***
--    -- ***************************************
----
--    --==============================================================
--    --メッセージ出力をする必要がある場合は処理を記述
--    --==============================================================
----
--    -- 処理１件目、または、いずれかのキー項目が変更された場合以下を実行
--    IF ((gt_save_2_base_code IS NULL)
--        OR
--        (gt_save_2_base_code <> ir_inv_result.base_code)
--        OR
--        (gt_save_2_subinv_code <> ir_inv_result.subinventory_code)
--       )
--    THEN
--      BEGIN
--        -- 棚卸日の範囲（終端）を設定
--        IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
--          -- 月中の場合、取得した最大棚卸日まで
--          ld_end_date :=  ir_inv_result.inventory_date;
--        ELSE
--          -- 月末の場合、
--          ld_end_date :=  LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month));
--        END IF;
--        --
--        -- ロック処理
--        OPEN  xic_lock_cur;
--        CLOSE xic_lock_cur;
--        --
--        -- 更新処理
--        UPDATE  xxcoi_inv_control
--        SET     inventory_status        =   cv_invsts_2                 -- 棚卸ステータス
--               ,last_update_date        =   SYSDATE                     -- 最終更新日
--               ,last_updated_by         =   cn_last_updated_by          -- 最終更新者
--               ,last_update_login       =   cn_last_update_login        -- 最終更新ユーザ
--               ,request_id              =   cn_request_id               -- 要求ID
--               ,program_application_id  =   cn_program_application_id   -- プログラムアプリケーションID
--               ,program_id              =   cn_program_id               -- プログラムID
--               ,program_update_date     =   SYSDATE                     -- プログラム更新日
--        WHERE   subinventory_code       =   ir_inv_result.subinventory_code
--        AND     inventory_status        =   cv_invsts_1
--        AND     inventory_kbn           =   gv_param_inventory_kbn
--        AND     inventory_date  BETWEEN TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
--                                AND     ld_end_date;
--        --
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          -- 更新対象がない場合は、後続処理を実行
--          NULL;
--          --
--        WHEN lock_error_expt THEN     -- ロック取得失敗時
--          lv_errmsg   := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_short_name
--                          ,iv_name         => cv_msg_xxcoi1_10144
--                         );
--          lv_errbuf   := lv_errmsg;
--          RAISE global_process_expt;
--      END;
--    END IF;
----
--  EXCEPTION
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
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
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END upd_inv_control;
--
  /**********************************************************************************
   * Procedure Name   : upd_inv_control
   * Description      : 棚卸管理出力（棚卸結果データ）(A-8)
   ***********************************************************************************/
  PROCEDURE upd_inv_control(
    it_subinv_code    IN  xxcoi_inv_control.subinventory_code%TYPE,
    it_inventory_date IN  xxcoi_inv_control.inventory_date%TYPE,
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_inv_control'; -- プログラム名
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
    ln_dummy      NUMBER;             -- ダミー変数
    ld_end_date   DATE;               -- 棚卸日の範囲（終端）
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    CURSOR  xic_lock_cur
    IS
      SELECT  1
      INTO    ln_dummy
      FROM    xxcoi_inv_control   xic     -- 棚卸管理テーブル
      WHERE   inventory_kbn           =   gv_param_inventory_kbn
      AND     subinventory_code       =   it_subinv_code
      AND     inventory_status        =   cv_invsts_1
      AND     inventory_date  BETWEEN TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
                              AND     it_inventory_date
      FOR UPDATE NOWAIT;
    --
    -- <カーソル名>レコード型
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    BEGIN
      -- =======================================
      --  棚卸ステータス更新
      -- =======================================
      -- ロック処理
      OPEN  xic_lock_cur;
      CLOSE xic_lock_cur;
      --
      -- 更新処理
      UPDATE  xxcoi_inv_control
      SET     inventory_status        =   cv_invsts_2                 -- 棚卸ステータス
             ,last_update_date        =   SYSDATE                     -- 最終更新日
             ,last_updated_by         =   cn_last_updated_by          -- 最終更新者
             ,last_update_login       =   cn_last_update_login        -- 最終更新ユーザ
             ,request_id              =   cn_request_id               -- 要求ID
             ,program_application_id  =   cn_program_application_id   -- プログラムアプリケーションID
             ,program_id              =   cn_program_id               -- プログラムID
             ,program_update_date     =   SYSDATE                     -- プログラム更新日
      WHERE   inventory_kbn           =   gv_param_inventory_kbn
      AND     subinventory_code       =   it_subinv_code
      AND     inventory_status        =   cv_invsts_1
      AND     inventory_date  BETWEEN TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
                              AND     it_inventory_date;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 更新対象がない場合は、後続処理を実行
        NULL;
        --
      WHEN lock_error_expt THEN     -- ロック取得失敗時
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name
                        ,iv_name         => cv_msg_xxcoi1_10144
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
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
  END upd_inv_control;
-- == 2009/08/20 V1.14 Modified END   ===============================================================
--
-- == 2009/08/20 V1.14 Modified START ===============================================================
--  /**********************************************************************************
--   * Procedure Name   : ins_inv_result
--   * Description      : 月次在庫受払出力（棚卸結果データ）(A-7)
--   ***********************************************************************************/
--  PROCEDURE ins_inv_result(
--    ir_inv_result     IN  inv_result_1_cur%ROWTYPE,     -- 1.棚卸結果情報
--    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
--    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
--    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inv_result'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
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
--    ln_dummy              NUMBER;       -- ダミー変数
--    lt_operation_cost     cm_cmpt_dtl.cmpnt_cost%TYPE;      -- 営業原価
--    lt_standard_cost      cst_item_costs.item_cost%TYPE;    -- 標準原価
--    ln_inventory_seq      NUMBER;
----
--    -- ===============================
--    -- ローカル・カーソル
--    -- ===============================
--    -- <カーソル名>
--    -- <カーソル名>レコード型
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ***************************************
--    -- ***        ループ処理の記述         ***
--    -- ***       処理部の呼び出し          ***
--    -- ***************************************
----
--    --==============================================================
--    --メッセージ出力をする必要がある場合は処理を記述
--    --==============================================================
----
--    BEGIN
--      -- 月次在庫受払表データ存在チェック
--      SELECT  1
--      INTO    ln_dummy
--      FROM    xxcoi_inv_reception_monthly   xirm
--      WHERE   xirm.inv_seq            =   ir_inv_result.xir_inv_seq
--      AND     xirm.inventory_item_id  =   ir_inv_result.inventory_item_id
--      AND     ROWNUM  = 1;
--      --
--      -- 月次在庫受払表に対象データが存在した場合、更新処理を実行
--      UPDATE  xxcoi_inv_reception_monthly
--      SET     inv_result              =   ir_inv_result.standard_article_qty        -- 棚卸結果
--             ,inv_result_bad          =   ir_inv_result.sub_standard_article_qty    -- 棚卸結果（不良品）
--             ,inv_wear                =   inv_wear
--                                        + (ir_inv_result.standard_article_qty + ir_inv_result.sub_standard_article_qty) * -1
--                                                                                    -- 棚卸減耗
--             ,last_update_date        =   SYSDATE                                   -- 最終更新日
--             ,last_updated_by         =   cn_last_updated_by                        -- 最終更新者
--             ,last_update_login       =   cn_last_update_login                      -- 最終更新ユーザ
--             ,request_id              =   cn_request_id                             -- 要求ID
--             ,program_application_id  =   cn_program_application_id                 -- プログラムアプリケーションID
--             ,program_id              =   cn_program_id                             -- プログラムID
--             ,program_update_date     =   SYSDATE                                   -- プログラム更新日
--      WHERE   inv_seq               =   ir_inv_result.xir_inv_seq
--      AND     inventory_item_id     =   ir_inv_result.inventory_item_id;
--      --
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        -- 月次在庫受払表に対象データが存在しない場合、作成処理を実行
--        -- ===================================
--        --  2.標準原価取得
--        -- ===================================
--        xxcoi_common_pkg.get_cmpnt_cost(
--          in_item_id      =>  ir_inv_result.inventory_item_id     -- 品目ID
--         ,in_org_id       =>  gn_f_organization_id                -- 組織ID
--         ,id_period_date  =>  ir_inv_result.inventory_date        -- 対象日
--         ,ov_cmpnt_cost   =>  lt_standard_cost                    -- 標準原価
--         ,ov_errbuf       =>  lv_errbuf                           -- エラーメッセージ
--         ,ov_retcode      =>  lv_retcode                          -- リターン・コード
--         ,ov_errmsg       =>  lv_errmsg                           -- ユーザー・エラーメッセージ
--        );
--        -- 終了パラメータ判定
--        IF (lv_retcode = cv_status_error) THEN
--          lv_errmsg   := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_short_name
--                          ,iv_name         => cv_msg_xxcoi1_10285
--                         );
--          lv_errbuf   := lv_errmsg;
--          RAISE global_api_expt;
--        END IF;
--        --
--        -- ===================================
--        --  2.営業原価取得
--        -- ===================================
--        xxcoi_common_pkg.get_discrete_cost(
--          in_item_id        =>  ir_inv_result.inventory_item_id     -- 品目ID
--         ,in_org_id         =>  gn_f_organization_id                -- 組織ID
--         ,id_target_date    =>  ir_inv_result.inventory_date        -- 対象日
--         ,ov_discrete_cost  =>  lt_operation_cost                   -- 営業原価
--         ,ov_errbuf         =>  lv_errbuf                           -- エラーメッセージ
--         ,ov_retcode        =>  lv_retcode                          -- リターン・コード
--         ,ov_errmsg         =>  lv_errmsg                           -- ユーザー・エラーメッセージ
--        );
--        -- 終了パラメータ判定
--        IF (lv_retcode = cv_status_error) THEN
--          lv_errmsg   := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_short_name
--                          ,iv_name         => cv_msg_xxcoi1_10293
--                         );
--          lv_errbuf   := lv_errmsg;
--          RAISE global_api_expt;
--        END IF;
--        --
--        -- ===================================
--        --  3.月次在庫受払テーブル出力
--        -- ===================================
--        INSERT INTO xxcoi_inv_reception_monthly(
--          inv_seq                                   -- 01.棚卸SEQ
--         ,base_code                                 -- 02.拠点コード
--         ,organization_id                           -- 03.組織id
--         ,subinventory_code                         -- 04.保管場所
--         ,subinventory_type                         -- 05.保管場所区分
--         ,practice_month                            -- 06.年月
--         ,practice_date                             -- 07.年月日
--         ,inventory_kbn                             -- 08.棚卸区分
--         ,inventory_item_id                         -- 09.品目ID
--         ,operation_cost                            -- 10.営業原価
--         ,standard_cost                             -- 11.標準原価
--         ,sales_shipped                             -- 12.売上出庫
--         ,sales_shipped_b                           -- 13.売上出庫振戻
--         ,return_goods                              -- 14.返品
--         ,return_goods_b                            -- 15.返品振戻
--         ,warehouse_ship                            -- 16.倉庫へ返庫
--         ,truck_ship                                -- 17.営業車へ出庫
--         ,others_ship                               -- 18.入出庫＿その他出庫
--         ,warehouse_stock                           -- 19.倉庫より入庫
--         ,truck_stock                               -- 20.営業車より入庫
--         ,others_stock                              -- 21.入出庫＿その他入庫
--         ,change_stock                              -- 22.倉替入庫
--         ,change_ship                               -- 23.倉替出庫
--         ,goods_transfer_old                        -- 24.商品振替（旧商品）
--         ,goods_transfer_new                        -- 25.商品振替（新商品）
--         ,sample_quantity                           -- 26.見本出庫
--         ,sample_quantity_b                         -- 27.見本出庫振戻
--         ,customer_sample_ship                      -- 28.顧客見本出庫
--         ,customer_sample_ship_b                    -- 29.顧客見本出庫振戻
--         ,customer_support_ss                       -- 30.顧客協賛見本出庫
--         ,customer_support_ss_b                     -- 31.顧客協賛見本出庫振戻
--         ,ccm_sample_ship                           -- 32.顧客広告宣伝費a自社商品
--         ,ccm_sample_ship_b                         -- 33.顧客広告宣伝費a自社商品振戻
--         ,vd_supplement_stock                       -- 34.消化vd補充入庫
--         ,vd_supplement_ship                        -- 35.消化vd補充出庫
--         ,inventory_change_in                       -- 36.基準在庫変更入庫
--         ,inventory_change_out                      -- 37.基準在庫変更出庫
--         ,factory_return                            -- 38.工場返品
--         ,factory_return_b                          -- 39.工場返品振戻
--         ,factory_change                            -- 40.工場倉替
--         ,factory_change_b                          -- 41.工場倉替振戻
--         ,removed_goods                             -- 42.廃却
--         ,removed_goods_b                           -- 43.廃却振戻
--         ,factory_stock                             -- 44.工場入庫
--         ,factory_stock_b                           -- 45.工場入庫振戻
--         ,wear_decrease                             -- 46.棚卸減耗増
--         ,wear_increase                             -- 47.棚卸減耗減
--         ,selfbase_ship                             -- 48.保管場所移動＿自拠点出庫
--         ,selfbase_stock                            -- 49.保管場所移動＿自拠点入庫
--         ,inv_result                                -- 50.棚卸結果
--         ,inv_result_bad                            -- 51.棚卸結果（不良品）
--         ,inv_wear                                  -- 52.棚卸減耗
--         ,month_begin_quantity                      -- 53.月首棚卸高
--         ,last_update_date                          -- 54.最終更新日
--         ,last_updated_by                           -- 55.最終更新者
--         ,creation_date                             -- 56.作成日
--         ,created_by                                -- 57.作成者
--         ,last_update_login                         -- 58.最終更新ユーザ
--         ,request_id                                -- 59.要求ID
--         ,program_application_id                    -- 60.プログラムアプリケーションID
--         ,program_id                                -- 61.プログラムID
--         ,program_update_date                       -- 62.プログラム更新日
--        )VALUES(
--          ir_inv_result.xir_inv_seq                 -- 01
--         ,ir_inv_result.base_code                   -- 02
--         ,gn_f_organization_id                      -- 03
--         ,ir_inv_result.subinventory_code           -- 04
--         ,ir_inv_result.warehouse_kbn               -- 05
--         ,gv_f_inv_acct_period                      -- 06
--         ,ir_inv_result.inventory_date              -- 07
--         ,gv_param_inventory_kbn                    -- 08
--         ,ir_inv_result.inventory_item_id           -- 09
--         ,TO_NUMBER(lt_operation_cost)              -- 10
--         ,TO_NUMBER(lt_standard_cost)               -- 11
--         ,0                                         -- 12
--         ,0                                         -- 13
--         ,0                                         -- 14
--         ,0                                         -- 15
--         ,0                                         -- 16
--         ,0                                         -- 17
--         ,0                                         -- 18
--         ,0                                         -- 19
--         ,0                                         -- 20
--         ,0                                         -- 21
--         ,0                                         -- 22
--         ,0                                         -- 23
--         ,0                                         -- 24
--         ,0                                         -- 25
--         ,0                                         -- 26
--         ,0                                         -- 27
--         ,0                                         -- 28
--         ,0                                         -- 29
--         ,0                                         -- 30
--         ,0                                         -- 31
--         ,0                                         -- 32
--         ,0                                         -- 33
--         ,0                                         -- 34
--         ,0                                         -- 35
--         ,0                                         -- 36
--         ,0                                         -- 37
--         ,0                                         -- 38
--         ,0                                         -- 39
--         ,0                                         -- 40
--         ,0                                         -- 41
--         ,0                                         -- 42
--         ,0                                         -- 43
--         ,0                                         -- 44
--         ,0                                         -- 45
--         ,0                                         -- 46
--         ,0                                         -- 47
--         ,0                                         -- 48
--         ,0                                         -- 49
--         ,ir_inv_result.standard_article_qty        -- 50
--         ,ir_inv_result.sub_standard_article_qty    -- 51
--         ,(ir_inv_result.standard_article_qty + ir_inv_result.sub_standard_article_qty) * -1
--                                                    -- 52
--         ,0                                         -- 53
--         ,SYSDATE                                   -- 54
--         ,cn_last_updated_by                        -- 55
--         ,SYSDATE                                   -- 56
--         ,cn_created_by                             -- 57
--         ,cn_last_update_login                      -- 58
--         ,cn_request_id                             -- 59
--         ,cn_program_application_id                 -- 60
--         ,cn_program_id                             -- 61
--         ,SYSDATE                                   -- 62
--        );
--        --
--    END;
----
--  EXCEPTION
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
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
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END ins_inv_result;
--
  /**********************************************************************************
   * Procedure Name   : ins_inv_result
   * Description      : 月次在庫受払出力（棚卸結果データ）(A-7)
   ***********************************************************************************/
  PROCEDURE ins_inv_result(
    it_base_code      IN  xxcoi_inv_control.base_code%TYPE,
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inv_result'; -- プログラム名
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
    ln_dummy              NUMBER;       -- ダミー変数
    lt_operation_cost     cm_cmpt_dtl.cmpnt_cost%TYPE;      -- 営業原価
    lt_standard_cost      cst_item_costs.item_cost%TYPE;    -- 標準原価
    ln_inventory_seq      NUMBER;
    lt_key_subinv_code    xxcoi_inv_control.subinventory_code%TYPE;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- キー項目初期化
    lt_key_subinv_code  :=  NULL;
    --
    -- ===================================
    --  A-6.棚卸結果情報抽出
    -- ===================================
    IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
      -- 棚卸区分：１（月中）の場合
      OPEN  inv_result_1_cur(
              iv_base_code        =>  it_base_code              -- 拠点コード
            );
    ELSE
      -- 棚卸区分：２（月末）の場合
      OPEN  inv_result_2_cur(
              iv_base_code        =>  it_base_code              -- 拠点コード
           );
    END IF;
    --
    <<inv_conseq_loop>>   -- 棚卸結果出力LOOP
    LOOP
      -- ===================================
      --  棚卸結果出力終了判定
      -- ===================================
      IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
        FETCH inv_result_1_cur  INTO  inv_result_rec;
        EXIT  inv_conseq_loop WHEN  inv_result_1_cur%NOTFOUND;
      ELSE
        FETCH inv_result_2_cur  INTO  inv_result_rec;
        EXIT  inv_conseq_loop WHEN  inv_result_2_cur%NOTFOUND;
      END IF;
      --
      BEGIN
      --
        -- ===================================
        --  月次在庫受払表作成
        -- ===================================
        IF (gv_param_exec_flag = cv_exec_1) THEN
          -- 起動フラグ：１（コンカレント起動）で、月次情報が既に存在する場合、棚卸情報を上書き
          -- 存在しない場合は、新規作成
          --
          SELECT  1
          INTO    ln_dummy
          FROM    xxcoi_inv_reception_monthly   xirm
          WHERE   xirm.base_code            =   inv_result_rec.base_code
          AND     xirm.organization_id      =   gn_f_organization_id
          AND     xirm.subinventory_code    =   inv_result_rec.subinventory_code
          AND     xirm.inventory_kbn        =   gv_param_inventory_kbn
          AND     xirm.practice_month       =   gv_f_inv_acct_period
          AND     xirm.inventory_item_id    =   inv_result_rec.inventory_item_id
          AND     xirm.request_id           =   cn_request_id
          AND     ROWNUM = 1;
          --
          -- 月次在庫受払表に対象データが存在した場合、更新処理を実行
          UPDATE  xxcoi_inv_reception_monthly
          SET     inv_result              =   inv_result_rec.standard_article_qty        -- 棚卸結果
                 ,inv_result_bad          =   inv_result_rec.sub_standard_article_qty    -- 棚卸結果（不良品）
                 ,inv_wear                =   inv_wear
                                            + (inv_result_rec.standard_article_qty + inv_result_rec.sub_standard_article_qty) * -1
                                                                                        -- 棚卸減耗
                 ,last_update_date        =   SYSDATE                                   -- 最終更新日
                 ,last_updated_by         =   cn_last_updated_by                        -- 最終更新者
                 ,last_update_login       =   cn_last_update_login                      -- 最終更新ユーザ
                 ,request_id              =   cn_request_id                             -- 要求ID
                 ,program_application_id  =   cn_program_application_id                 -- プログラムアプリケーションID
                 ,program_id              =   cn_program_id                             -- プログラムID
                 ,program_update_date     =   SYSDATE                                   -- プログラム更新日
          WHERE   base_code            =   inv_result_rec.base_code
          AND     organization_id      =   gn_f_organization_id
          AND     subinventory_code    =   inv_result_rec.subinventory_code
          AND     inventory_kbn        =   gv_param_inventory_kbn
          AND     practice_month       =   gv_f_inv_acct_period
          AND     inventory_item_id    =   inv_result_rec.inventory_item_id
          AND     request_id           =   cn_request_id;
        ELSE
          -- 起動フラグ：２（夜間強制確定（棚卸情報取込））の場合、常に新規作成
          RAISE NO_DATA_FOUND;
          --
        END IF;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ===================================
          --  標準原価取得
          -- ===================================
          xxcoi_common_pkg.get_cmpnt_cost(
            in_item_id      =>  inv_result_rec.inventory_item_id     -- 品目ID
           ,in_org_id       =>  gn_f_organization_id                -- 組織ID
           ,id_period_date  =>  inv_result_rec.inventory_date        -- 対象日
           ,ov_cmpnt_cost   =>  lt_standard_cost                    -- 標準原価
           ,ov_errbuf       =>  lv_errbuf                           -- エラーメッセージ
           ,ov_retcode      =>  lv_retcode                          -- リターン・コード
           ,ov_errmsg       =>  lv_errmsg                           -- ユーザー・エラーメッセージ
          );
          -- 終了パラメータ判定
          IF ((lv_retcode = cv_status_error)
              OR
              (lt_standard_cost IS NULL)
             )
          THEN
            lv_errmsg   := xxccp_common_pkg.get_msg(
                             iv_application  => cv_short_name
                            ,iv_name         => cv_msg_xxcoi1_10285
                           );
            lv_errbuf   := lv_errmsg;
            RAISE global_api_expt;
          END IF;
          --
          -- ===================================
          --  営業原価取得
          -- ===================================
          xxcoi_common_pkg.get_discrete_cost(
            in_item_id        =>  inv_result_rec.inventory_item_id     -- 品目ID
           ,in_org_id         =>  gn_f_organization_id                -- 組織ID
           ,id_target_date    =>  inv_result_rec.inventory_date        -- 対象日
           ,ov_discrete_cost  =>  lt_operation_cost                   -- 営業原価
           ,ov_errbuf         =>  lv_errbuf                           -- エラーメッセージ
           ,ov_retcode        =>  lv_retcode                          -- リターン・コード
           ,ov_errmsg         =>  lv_errmsg                           -- ユーザー・エラーメッセージ
          );
          -- 終了パラメータ判定
          IF ((lv_retcode = cv_status_error)
              OR
              (lt_operation_cost IS NULL)
             )
          THEN
            lv_errmsg   := xxccp_common_pkg.get_msg(
                             iv_application  => cv_short_name
                            ,iv_name         => cv_msg_xxcoi1_10293
                           );
            lv_errbuf   := lv_errmsg;
            RAISE global_api_expt;
          END IF;
          --
          -- 月次在庫受払表作成
          INSERT INTO xxcoi_inv_reception_monthly(
            inv_seq                                   -- 01.棚卸SEQ
           ,base_code                                 -- 02.拠点コード
           ,organization_id                           -- 03.組織id
           ,subinventory_code                         -- 04.保管場所
           ,subinventory_type                         -- 05.保管場所区分
           ,practice_month                            -- 06.年月
           ,practice_date                             -- 07.年月日
           ,inventory_kbn                             -- 08.棚卸区分
           ,inventory_item_id                         -- 09.品目ID
           ,operation_cost                            -- 10.営業原価
           ,standard_cost                             -- 11.標準原価
           ,sales_shipped                             -- 12.売上出庫
           ,sales_shipped_b                           -- 13.売上出庫振戻
           ,return_goods                              -- 14.返品
           ,return_goods_b                            -- 15.返品振戻
           ,warehouse_ship                            -- 16.倉庫へ返庫
           ,truck_ship                                -- 17.営業車へ出庫
           ,others_ship                               -- 18.入出庫＿その他出庫
           ,warehouse_stock                           -- 19.倉庫より入庫
           ,truck_stock                               -- 20.営業車より入庫
           ,others_stock                              -- 21.入出庫＿その他入庫
           ,change_stock                              -- 22.倉替入庫
           ,change_ship                               -- 23.倉替出庫
           ,goods_transfer_old                        -- 24.商品振替（旧商品）
           ,goods_transfer_new                        -- 25.商品振替（新商品）
           ,sample_quantity                           -- 26.見本出庫
           ,sample_quantity_b                         -- 27.見本出庫振戻
           ,customer_sample_ship                      -- 28.顧客見本出庫
           ,customer_sample_ship_b                    -- 29.顧客見本出庫振戻
           ,customer_support_ss                       -- 30.顧客協賛見本出庫
           ,customer_support_ss_b                     -- 31.顧客協賛見本出庫振戻
           ,ccm_sample_ship                           -- 32.顧客広告宣伝費a自社商品
           ,ccm_sample_ship_b                         -- 33.顧客広告宣伝費a自社商品振戻
           ,vd_supplement_stock                       -- 34.消化vd補充入庫
           ,vd_supplement_ship                        -- 35.消化vd補充出庫
           ,inventory_change_in                       -- 36.基準在庫変更入庫
           ,inventory_change_out                      -- 37.基準在庫変更出庫
           ,factory_return                            -- 38.工場返品
           ,factory_return_b                          -- 39.工場返品振戻
           ,factory_change                            -- 40.工場倉替
           ,factory_change_b                          -- 41.工場倉替振戻
           ,removed_goods                             -- 42.廃却
           ,removed_goods_b                           -- 43.廃却振戻
           ,factory_stock                             -- 44.工場入庫
           ,factory_stock_b                           -- 45.工場入庫振戻
           ,wear_decrease                             -- 46.棚卸減耗増
           ,wear_increase                             -- 47.棚卸減耗減
           ,selfbase_ship                             -- 48.保管場所移動＿自拠点出庫
           ,selfbase_stock                            -- 49.保管場所移動＿自拠点入庫
           ,inv_result                                -- 50.棚卸結果
           ,inv_result_bad                            -- 51.棚卸結果（不良品）
           ,inv_wear                                  -- 52.棚卸減耗
           ,month_begin_quantity                      -- 53.月首棚卸高
           ,last_update_date                          -- 54.最終更新日
           ,last_updated_by                           -- 55.最終更新者
           ,creation_date                             -- 56.作成日
           ,created_by                                -- 57.作成者
           ,last_update_login                         -- 58.最終更新ユーザ
           ,request_id                                -- 59.要求ID
           ,program_application_id                    -- 60.プログラムアプリケーションID
           ,program_id                                -- 61.プログラムID
           ,program_update_date                       -- 62.プログラム更新日
          )VALUES(
            1                                         -- 01
           ,inv_result_rec.base_code                  -- 02
           ,gn_f_organization_id                      -- 03
           ,inv_result_rec.subinventory_code          -- 04
           ,inv_result_rec.warehouse_kbn              -- 05
           ,gv_f_inv_acct_period                      -- 06
           ,CASE WHEN gv_param_exec_flag = cv_exec_1 THEN inv_result_rec.inventory_date
                 ELSE gd_f_process_date
            END                                       -- 07
           ,gv_param_inventory_kbn                    -- 08
           ,inv_result_rec.inventory_item_id          -- 09
           ,TO_NUMBER(lt_operation_cost)              -- 10
           ,TO_NUMBER(lt_standard_cost)               -- 11
           ,0                                         -- 12
           ,0                                         -- 13
           ,0                                         -- 14
           ,0                                         -- 15
           ,0                                         -- 16
           ,0                                         -- 17
           ,0                                         -- 18
           ,0                                         -- 19
           ,0                                         -- 20
           ,0                                         -- 21
           ,0                                         -- 22
           ,0                                         -- 23
           ,0                                         -- 24
           ,0                                         -- 25
           ,0                                         -- 26
           ,0                                         -- 27
           ,0                                         -- 28
           ,0                                         -- 29
           ,0                                         -- 30
           ,0                                         -- 31
           ,0                                         -- 32
           ,0                                         -- 33
           ,0                                         -- 34
           ,0                                         -- 35
           ,0                                         -- 36
           ,0                                         -- 37
           ,0                                         -- 38
           ,0                                         -- 39
           ,0                                         -- 40
           ,0                                         -- 41
           ,0                                         -- 42
           ,0                                         -- 43
           ,0                                         -- 44
           ,0                                         -- 45
           ,0                                         -- 46
           ,0                                         -- 47
           ,0                                         -- 48
           ,0                                         -- 49
           ,inv_result_rec.standard_article_qty       -- 50
           ,inv_result_rec.sub_standard_article_qty   -- 51
           ,(inv_result_rec.standard_article_qty + inv_result_rec.sub_standard_article_qty) * -1
                                                      -- 52
           ,0                                         -- 53
           ,SYSDATE                                   -- 54
           ,cn_last_updated_by                        -- 55
           ,SYSDATE                                   -- 56
           ,cn_created_by                             -- 57
           ,cn_last_update_login                      -- 58
           ,cn_request_id                             -- 59
           ,cn_program_application_id                 -- 60
           ,cn_program_id                             -- 61
           ,SYSDATE                                   -- 62
          );
          --
          -- 成功件数（月次在庫受払の作成レコード数）
          gn_target_cnt :=  gn_target_cnt + 1;
          gn_normal_cnt :=  gn_normal_cnt + 1;
      END;
      --
      -- =======================================
      --  棚卸ステータスの更新
      -- =======================================
      IF ((lt_key_subinv_code IS NULL)
          OR
          (lt_key_subinv_code <> inv_result_rec.subinventory_code)
         )
      THEN
        -- 保管場所単位に棚卸ステータスを２（受払作成済み）に更新
        --
        -- =======================================
        --  A-8.棚卸管理出力（棚卸結果データ）
        -- =======================================
        upd_inv_control(
          it_subinv_code    =>  inv_result_rec.subinventory_code
         ,it_inventory_date =>  gd_f_process_date
         ,ov_errbuf         =>  lv_errbuf         --  エラー・メッセージ           --# 固定 #
         ,ov_retcode        =>  lv_retcode        --  リターン・コード             --# 固定 #
         ,ov_errmsg         =>  lv_errmsg         --  ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 終了パラメータ判定
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
      END IF;
      --
      -- キー情報（保管場所コード）を保持
      lt_key_subinv_code  :=  inv_result_rec.subinventory_code;
      --
    END LOOP inv_conseq_loop;
    --
    -- =======================================
    --  CURSORクローズ
    -- =======================================
    IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
      CLOSE inv_result_1_cur;
    ELSE
      CLOSE inv_result_2_cur;
    END IF;
--
  EXCEPTION
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
  END ins_inv_result;
-- == 2009/08/20 V1.14 Modified END   ===============================================================
--
-- == 2009/08/20 V1.14 Deleted START ===============================================================
--  /**********************************************************************************
--   * Procedure Name   : ins_inv_control
--   * Description      :  棚卸管理出力（日次データ）(A-5)
--   ***********************************************************************************/
--  PROCEDURE ins_inv_control(
--    ir_invrcp_daily   IN  invrcp_daily_1_cur%ROWTYPE,   -- 1.月次在庫受払（日次）情報
--    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
--    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
--    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inv_control'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
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
--    ln_dummy      NUMBER(1);          -- ダミー変数
--    lt_base_code  xxcmm_cust_accounts.management_base_code%TYPE;
----
--    -- ===============================
--    -- ローカル・カーソル
--    -- ===============================
--    -- <カーソル名>
--    -- <カーソル名>レコード型
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ***************************************
--    -- ***        ループ処理の記述         ***
--    -- ***       処理部の呼び出し          ***
--    -- ***************************************
----
--    --==============================================================
--    --メッセージ出力をする必要がある場合は処理を記述
--    --==============================================================
----
--    -- 処理１件目、または、いずれかのキー項目（拠点、保管場所）が変更された場合以下を実行
--    IF  ((gt_save_1_base_code IS NULL)
--         OR
--         (gt_save_1_base_code   <> ir_invrcp_daily.base_code)
--         OR
--         (gt_save_1_subinv_code <> ir_invrcp_daily.subinventory_code)
--        )
--    THEN
--      IF (    (ir_invrcp_daily.inventory_seq IS NULL)
--          AND (gv_param_exec_flag = cv_exec_2)
--         )
--      THEN
--        -- 棚卸SEQがNULL、かつ、起動フラグ：月次夜間強制確定の場合
--        BEGIN
--          -- 棚卸管理用拠点コード取得
--          SELECT  xca.management_base_code
--          INTO    lt_base_code
--          FROM    hz_cust_accounts    hca
--                 ,xxcmm_cust_accounts xca
--          WHERE   hca.cust_account_id       =   xca.customer_id
--          AND     hca.account_number        =   ir_invrcp_daily.base_code
--          AND     hca.customer_class_code   =   '1'           -- 拠点
--          AND     hca.status                =   'A'           -- 有効
---- == 2009/03/30 V1.6 Added START ===============================================================
--          AND     xca.dept_hht_div          =   '1';          -- HHT区分（1:百貨店）
---- == 2009/03/30 V1.6 Added END   ===============================================================
--          --
--          IF (lt_base_code IS NULL) THEN
--            lt_base_code  :=  ir_invrcp_daily.base_code;
--          END IF;
---- == 2009/03/30 V1.6 Added START ===============================================================
--        EXCEPTION
--          WHEN NO_DATA_FOUND THEN
--            lt_base_code  :=  ir_invrcp_daily.base_code;
---- == 2009/03/30 V1.6 Added END   ===============================================================
--        END;
--        --
--        -- 棚卸SEQがNULLの場合
--        INSERT INTO xxcoi_inv_control(
--          inventory_seq                         -- 01.棚卸SEQ
--         ,inventory_kbn                         -- 02.棚卸区分
--         ,base_code                             -- 03.拠点コード
--         ,subinventory_code                     -- 04.保管場所
--         ,warehouse_kbn                         -- 05.倉庫区分
--         ,inventory_year_month                  -- 06.年月
--         ,inventory_date                        -- 07.棚卸日
--         ,inventory_status                      -- 08.棚卸ステータス
--         ,last_update_date                      -- 09.最終更新日
--         ,last_updated_by                       -- 10.最終更新者
--         ,creation_date                         -- 11.作成日
--         ,created_by                            -- 12.作成者
--         ,last_update_login                     -- 13.最終更新ユーザ
--         ,request_id                            -- 14.要求ID
--         ,program_application_id                -- 15.プログラムアプリケーションID
--         ,program_id                            -- 16.プログラムID
--         ,program_update_date                   -- 17.プログラム更新日
--        )VALUES(
--          gt_save_1_inv_seq                     -- 01
--         ,gv_param_inventory_kbn                -- 02
--         ,lt_base_code                          -- 03
--         ,ir_invrcp_daily.subinventory_code     -- 04
--         ,ir_invrcp_daily.subinventory_type     -- 05
--         ,gv_f_inv_acct_period                  -- 06
--         ,gd_f_process_date                     -- 07
--         ,cv_invsts_2                           -- 08
--         ,SYSDATE                               -- 09
--         ,cn_last_updated_by                    -- 10
--         ,SYSDATE                               -- 11
--         ,cn_created_by                         -- 12
--         ,cn_last_update_login                  -- 13
--         ,cn_request_id                         -- 14
--         ,cn_program_application_id             -- 15
--         ,cn_program_id                         -- 16
--         ,SYSDATE                               -- 17
--        );
--      END IF;
---- == 2009/07/21 V1.12 Added START ===============================================================
--      -- パフォーマンス考慮のため、COMMITを実行しINSERT時の領域を開放（A-4の日時在庫受払表のINSERT）
--      COMMIT;
---- == 2009/07/21 V1.12 Added END   ===============================================================
--    END IF;
----
--  EXCEPTION
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
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
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END ins_inv_control;
-- == 2009/08/20 V1.14 Deleted END   ===============================================================
--
-- == 2009/08/20 V1.14 Modified START ===============================================================
--  /**********************************************************************************
--   * Procedure Name   : ins_invrcp_daily
--   * Description      : 月次在庫受払出力（日次データ）(A-4)
--   ***********************************************************************************/
--  PROCEDURE ins_invrcp_daily(
--    ir_invrcp_daily   IN  invrcp_daily_1_cur%ROWTYPE,   -- 1.月次在庫受払（日次）情報
--    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
--    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
--    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_invrcp_daily'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
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
--    lt_inventory_seq        xxcoi_inv_control.inventory_seq%TYPE;     -- 棚卸SEQ
--    ln_inv_wear             NUMBER;                                   -- 棚卸減耗
---- == 2009/04/27 V1.7 Added START ===============================================================
--    ld_practice_date        DATE;                                     -- 年月日
---- == 2009/04/27 V1.7 Added END   ===============================================================
----
--    -- ===============================
--    -- ローカル・カーソル
--    -- ===============================
--    -- <カーソル名>
--    -- <カーソル名>レコード型
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ***************************************
--    -- ***        ループ処理の記述         ***
--    -- ***       処理部の呼び出し          ***
--    -- ***************************************
----
--    --==============================================================
--    --メッセージ出力をする必要がある場合は処理を記述
--    --==============================================================
----
--    -- ===================================
--    --  1.棚卸SEQ採番
--    -- ===================================
--    IF (ir_invrcp_daily.inventory_seq IS NOT NULL) THEN
--      -- 棚卸SEQが取得された場合
--      lt_inventory_seq  :=  ir_invrcp_daily.inventory_seq;
---- == 2009/04/27 V1.7 Added START ===============================================================
--      IF (gv_param_inventory_kbn = cv_inv_kbn_1) THEN
--        -- コンカレント起動時
--        ld_practice_date  :=  ir_invrcp_daily.inventory_date;
--      ELSE
--        ld_practice_date  :=  gd_f_process_date;
--      END IF;
---- == 2009/04/27 V1.7 Added END   ===============================================================
--      --
--    ELSIF ((gt_save_1_base_code IS NULL)
--           OR
--           (gt_save_1_base_code   <> ir_invrcp_daily.base_code)
--           OR
--           (gt_save_1_subinv_code <> ir_invrcp_daily.subinventory_code)
--          )
--    THEN
--      -- 処理１件目、または、いずれかのキー項目（拠点、保管場所）が変更された場合
--      SELECT  xxcoi_inv_control_s01.NEXTVAL
--      INTO    lt_inventory_seq
--      FROM    dual;
---- == 2009/04/27 V1.7 Added START ===============================================================
--      IF (gv_param_inventory_kbn = cv_inv_kbn_1) THEN
--        -- コンカレント起動時
--        ld_practice_date  :=  ir_invrcp_daily.practice_date;
--      ELSE
--        ld_practice_date  :=  gd_f_process_date;
--      END IF;
---- == 2009/04/27 V1.7 Added END   ===============================================================
--    ELSE
--      -- 上記以外の場合
--      lt_inventory_seq  :=  gt_save_1_inv_seq;
---- == 2009/04/27 V1.7 Added START ===============================================================
--      IF (gv_param_inventory_kbn = cv_inv_kbn_1) THEN
--        -- コンカレント起動時
--        ld_practice_date  :=  ir_invrcp_daily.practice_date;
--      ELSE
--        ld_practice_date  :=  gd_f_process_date;
--      END IF;
---- == 2009/04/27 V1.7 Added END   ===============================================================
--    END IF;
--    --
--    -- ===================================
--    --  2.月次在庫受払テーブル出力
--    -- ===================================
--    -- 棚卸減耗を算出
--    ln_inv_wear   :=    ir_invrcp_daily.sales_shipped           * -1    -- 売上出庫
--                      + ir_invrcp_daily.sales_shipped_b         *  1    -- 売上出庫振戻
--                      + ir_invrcp_daily.return_goods            *  1    -- 返品
--                      + ir_invrcp_daily.return_goods_b          * -1    -- 返品振戻
--                      + ir_invrcp_daily.warehouse_ship          * -1    -- 倉庫へ返庫
--                      + ir_invrcp_daily.truck_ship              * -1    -- 営業車へ出庫
--                      + ir_invrcp_daily.others_ship             * -1    -- 入出庫＿その他出庫
--                      + ir_invrcp_daily.warehouse_stock         *  1    -- 倉庫より入庫
--                      + ir_invrcp_daily.truck_stock             *  1    -- 営業車より入庫
--                      + ir_invrcp_daily.others_stock            *  1    -- 入出庫＿その他入庫
--                      + ir_invrcp_daily.change_stock            *  1    -- 倉替入庫
--                      + ir_invrcp_daily.change_ship             * -1    -- 倉替出庫
--                      + ir_invrcp_daily.goods_transfer_old      * -1    -- 商品振替（旧商品）
--                      + ir_invrcp_daily.goods_transfer_new      *  1    -- 商品振替（新商品）
--                      + ir_invrcp_daily.sample_quantity         * -1    -- 見本出庫
--                      + ir_invrcp_daily.sample_quantity_b       *  1    -- 見本出庫振戻
--                      + ir_invrcp_daily.customer_sample_ship    * -1    -- 顧客見本出庫
--                      + ir_invrcp_daily.customer_sample_ship_b  *  1    -- 顧客見本出庫振戻
--                      + ir_invrcp_daily.customer_support_ss     * -1    -- 顧客協賛見本出庫
--                      + ir_invrcp_daily.customer_support_ss_b   *  1    -- 顧客協賛見本出庫振戻
--                      + ir_invrcp_daily.vd_supplement_stock     *  1    -- 消化VD補充入庫
--                      + ir_invrcp_daily.vd_supplement_ship      * -1    -- 消化VD補充出庫
--                      + ir_invrcp_daily.inventory_change_in     *  1    -- 基準在庫変更入庫
--                      + ir_invrcp_daily.inventory_change_out    * -1    -- 基準在庫変更出庫
--                      + ir_invrcp_daily.factory_return          * -1    -- 工場返品
--                      + ir_invrcp_daily.factory_return_b        *  1    -- 工場返品振戻
--                      + ir_invrcp_daily.factory_change          * -1    -- 工場倉替
--                      + ir_invrcp_daily.factory_change_b        *  1    -- 工場倉替振戻
--                      + ir_invrcp_daily.removed_goods           * -1    -- 廃却
--                      + ir_invrcp_daily.removed_goods_b         *  1    -- 廃却振戻
--                      + ir_invrcp_daily.factory_stock           *  1    -- 工場入庫
--                      + ir_invrcp_daily.factory_stock_b         * -1    -- 工場入庫振戻
--                      + ir_invrcp_daily.ccm_sample_ship         * -1    -- 顧客広告宣伝費A自社商品
--                      + ir_invrcp_daily.ccm_sample_ship_b       *  1    -- 顧客広告宣伝費A自社商品振戻
--                      + ir_invrcp_daily.wear_decrease           *  1    -- 棚卸減耗増
--                      + ir_invrcp_daily.wear_increase           * -1    -- 棚卸減耗減
--                      + ir_invrcp_daily.selfbase_ship           * -1    -- 保管場所移動＿自拠点出庫
--                      + ir_invrcp_daily.selfbase_stock          *  1;   -- 保管場所移動＿自拠点入庫
--    --
--    -- 月次在庫受払表（月次）INSERT
--    INSERT INTO xxcoi_inv_reception_monthly(
--      inv_seq                                   -- 01.棚卸SEQ
--     ,base_code                                 -- 02.拠点コード
--     ,organization_id                           -- 03.組織id
--     ,subinventory_code                         -- 04.保管場所
--     ,subinventory_type                         -- 05.保管場所区分
--     ,practice_month                            -- 06.年月
--     ,practice_date                             -- 07.年月日
--     ,inventory_kbn                             -- 08.棚卸区分
--     ,inventory_item_id                         -- 09.品目ID
--     ,operation_cost                            -- 10.営業原価
--     ,standard_cost                             -- 11.標準原価
--     ,sales_shipped                             -- 12.売上出庫
--     ,sales_shipped_b                           -- 13.売上出庫振戻
--     ,return_goods                              -- 14.返品
--     ,return_goods_b                            -- 15.返品振戻
--     ,warehouse_ship                            -- 16.倉庫へ返庫
--     ,truck_ship                                -- 17.営業車へ出庫
--     ,others_ship                               -- 18.入出庫＿その他出庫
--     ,warehouse_stock                           -- 19.倉庫より入庫
--     ,truck_stock                               -- 20.営業車より入庫
--     ,others_stock                              -- 21.入出庫＿その他入庫
--     ,change_stock                              -- 22.倉替入庫
--     ,change_ship                               -- 23.倉替出庫
--     ,goods_transfer_old                        -- 24.商品振替（旧商品）
--     ,goods_transfer_new                        -- 25.商品振替（新商品）
--     ,sample_quantity                           -- 26.見本出庫
--     ,sample_quantity_b                         -- 27.見本出庫振戻
--     ,customer_sample_ship                      -- 28.顧客見本出庫
--     ,customer_sample_ship_b                    -- 29.顧客見本出庫振戻
--     ,customer_support_ss                       -- 30.顧客協賛見本出庫
--     ,customer_support_ss_b                     -- 31.顧客協賛見本出庫振戻
--     ,ccm_sample_ship                           -- 32.顧客広告宣伝費a自社商品
--     ,ccm_sample_ship_b                         -- 33.顧客広告宣伝費a自社商品振戻
--     ,vd_supplement_stock                       -- 34.消化vd補充入庫
--     ,vd_supplement_ship                        -- 35.消化vd補充出庫
--     ,inventory_change_in                       -- 36.基準在庫変更入庫
--     ,inventory_change_out                      -- 37.基準在庫変更出庫
--     ,factory_return                            -- 38.工場返品
--     ,factory_return_b                          -- 39.工場返品振戻
--     ,factory_change                            -- 40.工場倉替
--     ,factory_change_b                          -- 41.工場倉替振戻
--     ,removed_goods                             -- 42.廃却
--     ,removed_goods_b                           -- 43.廃却振戻
--     ,factory_stock                             -- 44.工場入庫
--     ,factory_stock_b                           -- 45.工場入庫振戻
--     ,wear_decrease                             -- 46.棚卸減耗増
--     ,wear_increase                             -- 47.棚卸減耗減
--     ,selfbase_ship                             -- 48.保管場所移動＿自拠点出庫
--     ,selfbase_stock                            -- 49.保管場所移動＿自拠点入庫
--     ,inv_result                                -- 50.棚卸結果
--     ,inv_result_bad                            -- 51.棚卸結果（不良品）
--     ,inv_wear                                  -- 52.棚卸減耗
--     ,month_begin_quantity                      -- 53.月首棚卸高
--     ,last_update_date                          -- 54.最終更新日
--     ,last_updated_by                           -- 55.最終更新者
--     ,creation_date                             -- 56.作成日
--     ,created_by                                -- 57.作成者
--     ,last_update_login                         -- 58.最終更新ユーザ
--     ,request_id                                -- 59.要求ID
--     ,program_application_id                    -- 60.プログラムアプリケーションID
--     ,program_id                                -- 61.プログラムID
--     ,program_update_date                       -- 62.プログラム更新日
--    )VALUES(
--      lt_inventory_seq                          -- 01
--     ,ir_invrcp_daily.base_code                 -- 02
--     ,ir_invrcp_daily.organization_id           -- 03
--     ,ir_invrcp_daily.subinventory_code         -- 04
--     ,ir_invrcp_daily.subinventory_type         -- 05
--     ,gv_f_inv_acct_period                      -- 06
---- == 2009/04/27 V1.7 Modified START ===============================================================
----    ,gd_f_process_date                          -- 07
--     ,ld_practice_date                          -- 07
---- == 2009/04/27 V1.7 Modified END   ===============================================================
--     ,gv_param_inventory_kbn                    -- 08
--     ,ir_invrcp_daily.inventory_item_id         -- 09
--     ,ir_invrcp_daily.operation_cost            -- 10
--     ,ir_invrcp_daily.standard_cost             -- 11
--     ,ir_invrcp_daily.sales_shipped             -- 12
--     ,ir_invrcp_daily.sales_shipped_b           -- 13
--     ,ir_invrcp_daily.return_goods              -- 14
--     ,ir_invrcp_daily.return_goods_b            -- 15
--     ,ir_invrcp_daily.warehouse_ship            -- 16
--     ,ir_invrcp_daily.truck_ship                -- 17
--     ,ir_invrcp_daily.others_ship               -- 18
--     ,ir_invrcp_daily.warehouse_stock           -- 19
--     ,ir_invrcp_daily.truck_stock               -- 20
--     ,ir_invrcp_daily.others_stock              -- 21
--     ,ir_invrcp_daily.change_stock              -- 22
--     ,ir_invrcp_daily.change_ship               -- 23
--     ,ir_invrcp_daily.goods_transfer_old        -- 24
--     ,ir_invrcp_daily.goods_transfer_new        -- 25
--     ,ir_invrcp_daily.sample_quantity           -- 26
--     ,ir_invrcp_daily.sample_quantity_b         -- 27
--     ,ir_invrcp_daily.customer_sample_ship      -- 28
--     ,ir_invrcp_daily.customer_sample_ship_b    -- 29
--     ,ir_invrcp_daily.customer_support_ss       -- 30
--     ,ir_invrcp_daily.customer_support_ss_b     -- 31
--     ,ir_invrcp_daily.ccm_sample_ship           -- 32
--     ,ir_invrcp_daily.ccm_sample_ship_b         -- 33
--     ,ir_invrcp_daily.vd_supplement_stock       -- 34
--     ,ir_invrcp_daily.vd_supplement_ship        -- 35
--     ,ir_invrcp_daily.inventory_change_in       -- 36
--     ,ir_invrcp_daily.inventory_change_out      -- 37
--     ,ir_invrcp_daily.factory_return            -- 38
--     ,ir_invrcp_daily.factory_return_b          -- 39
--     ,ir_invrcp_daily.factory_change            -- 40
--     ,ir_invrcp_daily.factory_change_b          -- 41
--     ,ir_invrcp_daily.removed_goods             -- 42
--     ,ir_invrcp_daily.removed_goods_b           -- 43
--     ,ir_invrcp_daily.factory_stock             -- 44
--     ,ir_invrcp_daily.factory_stock_b           -- 45
--     ,ir_invrcp_daily.wear_decrease             -- 46
--     ,ir_invrcp_daily.wear_increase             -- 47
--     ,ir_invrcp_daily.selfbase_ship             -- 48
--     ,ir_invrcp_daily.selfbase_stock            -- 49
--     ,0                                         -- 50
--     ,0                                         -- 51
--     ,ln_inv_wear                               -- 52
--     ,0                                         -- 53
--     ,SYSDATE                                   -- 54
--     ,cn_last_updated_by                        -- 55
--     ,SYSDATE                                   -- 56
--     ,cn_created_by                             -- 57
--     ,cn_last_update_login                      -- 58
--     ,cn_request_id                             -- 59
--     ,cn_program_application_id                 -- 60
--     ,cn_program_id                             -- 61
--     ,SYSDATE                                   -- 62
--    );
--    --
--    -- 棚卸SEQを保持
--    gt_save_1_inv_seq     :=  lt_inventory_seq;
--    --
--  EXCEPTION
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
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
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END ins_invrcp_daily;
--
  /**********************************************************************************
   * Procedure Name   : ins_invrcp_daily
   * Description      : 月次在庫受払出力（日次データ）(A-4)
   ***********************************************************************************/
  PROCEDURE ins_invrcp_daily(
    it_base_code      IN  xxcoi_inv_reception_monthly.base_code%TYPE,
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_invrcp_daily'; -- プログラム名
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
    lt_inventory_seq        xxcoi_inv_control.inventory_seq%TYPE;     -- 棚卸SEQ
    ln_inv_wear             NUMBER;                                   -- 棚卸減耗
    ld_practice_date        DATE;                                     -- 年月日
    lt_key_subinv_code      xxcoi_inv_control.subinventory_code%TYPE;
    ln_dummy                NUMBER;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- キー項目を初期化
    lt_key_subinv_code  :=  NULL;
    --
    -- ===========================================
    --  A-2.月次在庫受払（日次）情報取得（CURSOR）
    -- ===========================================
    --
    IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
      -- 棚卸区分：１（月中）の場合
      OPEN  invrcp_daily_1_cur(
              iv_base_code        =>  it_base_code                  -- 拠点コード
            );
    ELSE
      -- 棚卸区分：２（月末）の場合
-- == 2010/01/05 V1.15 Modified START ===============================================================
--      OPEN  invrcp_daily_2_cur(
--              iv_base_code        =>  it_base_code                  -- 拠点コード
--           );
      --
      IF  (gv_param_exec_flag = cv_exec_1)  THEN
        -- 起動フラグ：１（コンカレント起動）
        OPEN  invrcp_daily_2_cur(
                iv_base_code        =>  it_base_code                  -- 拠点コード
             );
      ELSE
        -- 起動フラグ：３（夜間強制確定（日次情報取込））
        OPEN  invrcp_daily_3_cur;
      END IF;
-- == 2010/01/05 V1.15 Modified END   ===============================================================
    END IF;
    --
    <<daily_data_loop>>    -- 日次データ出力LOOP
    LOOP
      --
      -- ===================================
      --  日次データ出力終了判定
      -- ===================================
      IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
        FETCH invrcp_daily_1_cur  INTO  invrcp_daily_rec;
        EXIT  daily_data_loop   WHEN  invrcp_daily_1_cur%NOTFOUND;
        --
      ELSE
-- == 2010/01/05 V1.15 Modified START ===============================================================
--        FETCH invrcp_daily_2_cur  INTO  invrcp_daily_rec;
--        EXIT  daily_data_loop   WHEN  invrcp_daily_2_cur%NOTFOUND;
        IF  (gv_param_exec_flag = cv_exec_1)  THEN
          -- 起動フラグ：１（コンカレント起動）
          FETCH invrcp_daily_2_cur  INTO  invrcp_daily_rec;
          EXIT  daily_data_loop   WHEN  invrcp_daily_2_cur%NOTFOUND;
        ELSE
          -- 起動フラグ：３（夜間強制確定（日次情報取込））
          FETCH invrcp_daily_3_cur  INTO  invrcp_daily_rec;
          EXIT  daily_data_loop   WHEN  invrcp_daily_3_cur%NOTFOUND;
        END IF;
-- == 2010/01/05 V1.15 Modified END   ===============================================================
        --
        BEGIN
          -- 棚卸区分：２（月末）の場合、棚卸情報（棚卸日）を取得
          --
          SELECT   MAX(xic.inventory_date)       inventory_date
          INTO     invrcp_daily_rec.inventory_date
          FROM     xxcoi_inv_control           xic
          WHERE    xic.inventory_kbn      =   gv_param_inventory_kbn
          AND      xic.subinventory_code  =   invrcp_daily_rec.subinventory_code
          AND      xic.inventory_date BETWEEN TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
                                      AND     LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month))
          GROUP BY  xic.subinventory_code;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            invrcp_daily_rec.inventory_date :=  NULL;
        END;
      END IF;
      --
      -- ===================================
      --  月次在庫受払の年月日設定
      -- ===================================
      IF (gv_param_exec_flag = cv_exec_1) THEN
        -- 起動フラグ：１（コンカレント起動）
        ld_practice_date  :=  NVL(invrcp_daily_rec.inventory_date, invrcp_daily_rec.practice_date);
      ELSE
        -- 起動フラグ：３（夜間強制確定（日次情報取込））
        ld_practice_date  :=  gd_f_process_date;
      END IF;
      --
      -- ===================================
      --  棚卸管理情報作成
      -- ===================================
      IF (((lt_key_subinv_code IS NULL)
           OR
           (lt_key_subinv_code <> invrcp_daily_rec.subinventory_code)
          )
          AND
          (gv_param_exec_flag = cv_exec_3)
          AND
          (invrcp_daily_rec.inventory_date IS NULL)
         )
      THEN
          -- 起動フラグ：３（夜間強制確定（日次情報取込））時に、
          -- 棚卸管理情報が存在しない場合、保管場所単に、棚卸管理情報を作成
          --
          -- ===================================
          --  A-5.棚卸管理作成
          -- ===================================
          ins_inv_control(
            it_base_code      =>  invrcp_daily_rec.base_code
           ,it_subinv_code    =>  invrcp_daily_rec.subinventory_code
           ,it_subinv_type    =>  invrcp_daily_rec.subinventory_type
           ,ov_errbuf         =>  lv_errbuf         --  エラー・メッセージ           --# 固定 #
           ,ov_retcode        =>  lv_retcode        --  リターン・コード             --# 固定 #
           ,ov_errmsg         =>  lv_errmsg         --  ユーザー・エラー・メッセージ --# 固定 #
          );
          --
          -- 終了パラメータ判定
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
      END IF;
      --
      -- ===================================
      --  棚卸減耗を算出
      -- ===================================
      ln_inv_wear   :=    invrcp_daily_rec.sales_shipped           * -1    -- 売上出庫
                        + invrcp_daily_rec.sales_shipped_b         *  1    -- 売上出庫振戻
                        + invrcp_daily_rec.return_goods            *  1    -- 返品
                        + invrcp_daily_rec.return_goods_b          * -1    -- 返品振戻
                        + invrcp_daily_rec.warehouse_ship          * -1    -- 倉庫へ返庫
                        + invrcp_daily_rec.truck_ship              * -1    -- 営業車へ出庫
                        + invrcp_daily_rec.others_ship             * -1    -- 入出庫＿その他出庫
                        + invrcp_daily_rec.warehouse_stock         *  1    -- 倉庫より入庫
                        + invrcp_daily_rec.truck_stock             *  1    -- 営業車より入庫
                        + invrcp_daily_rec.others_stock            *  1    -- 入出庫＿その他入庫
                        + invrcp_daily_rec.change_stock            *  1    -- 倉替入庫
                        + invrcp_daily_rec.change_ship             * -1    -- 倉替出庫
                        + invrcp_daily_rec.goods_transfer_old      * -1    -- 商品振替（旧商品）
                        + invrcp_daily_rec.goods_transfer_new      *  1    -- 商品振替（新商品）
                        + invrcp_daily_rec.sample_quantity         * -1    -- 見本出庫
                        + invrcp_daily_rec.sample_quantity_b       *  1    -- 見本出庫振戻
                        + invrcp_daily_rec.customer_sample_ship    * -1    -- 顧客見本出庫
                        + invrcp_daily_rec.customer_sample_ship_b  *  1    -- 顧客見本出庫振戻
                        + invrcp_daily_rec.customer_support_ss     * -1    -- 顧客協賛見本出庫
                        + invrcp_daily_rec.customer_support_ss_b   *  1    -- 顧客協賛見本出庫振戻
                        + invrcp_daily_rec.vd_supplement_stock     *  1    -- 消化VD補充入庫
                        + invrcp_daily_rec.vd_supplement_ship      * -1    -- 消化VD補充出庫
                        + invrcp_daily_rec.inventory_change_in     *  1    -- 基準在庫変更入庫
                        + invrcp_daily_rec.inventory_change_out    * -1    -- 基準在庫変更出庫
                        + invrcp_daily_rec.factory_return          * -1    -- 工場返品
                        + invrcp_daily_rec.factory_return_b        *  1    -- 工場返品振戻
                        + invrcp_daily_rec.factory_change          * -1    -- 工場倉替
                        + invrcp_daily_rec.factory_change_b        *  1    -- 工場倉替振戻
                        + invrcp_daily_rec.removed_goods           * -1    -- 廃却
                        + invrcp_daily_rec.removed_goods_b         *  1    -- 廃却振戻
                        + invrcp_daily_rec.factory_stock           *  1    -- 工場入庫
                        + invrcp_daily_rec.factory_stock_b         * -1    -- 工場入庫振戻
                        + invrcp_daily_rec.ccm_sample_ship         * -1    -- 顧客広告宣伝費A自社商品
                        + invrcp_daily_rec.ccm_sample_ship_b       *  1    -- 顧客広告宣伝費A自社商品振戻
                        + invrcp_daily_rec.wear_decrease           *  1    -- 棚卸減耗増
                        + invrcp_daily_rec.wear_increase           * -1    -- 棚卸減耗減
                        + invrcp_daily_rec.selfbase_ship           * -1    -- 保管場所移動＿自拠点出庫
                        + invrcp_daily_rec.selfbase_stock          *  1;   -- 保管場所移動＿自拠点入庫
      --
      -- ===================================
      --  月次在庫受払表作成
      -- ===================================
      BEGIN
        IF (gv_param_exec_flag = cv_exec_3) THEN
          -- 起動フラグ：３（夜間強制確定（日次情報取込））で、月次情報が既に存在する場合、日次情報を上書き
          -- 存在しない場合は、新規作成
          --
          SELECT  1
          INTO    ln_dummy
          FROM    xxcoi_inv_reception_monthly   xirm
          WHERE   xirm.base_code            =   invrcp_daily_rec.base_code
          AND     xirm.subinventory_code    =   invrcp_daily_rec.subinventory_code
          AND     xirm.inventory_item_id    =   invrcp_daily_rec.inventory_item_id
          AND     xirm.organization_id      =   gn_f_organization_id
          AND     xirm.practice_month       =   gv_f_inv_acct_period
          AND     xirm.inventory_kbn        =   gv_param_inventory_kbn
          AND     ROWNUM = 1
          FOR UPDATE NOWAIT;
          --
          -- 更新
          UPDATE  xxcoi_inv_reception_monthly
          SET     sales_shipped             =   invrcp_daily_rec.sales_shipped            -- 12.売上出庫
                 ,sales_shipped_b           =   invrcp_daily_rec.sales_shipped_b          -- 13.売上出庫振戻
                 ,return_goods              =   invrcp_daily_rec.return_goods             -- 14.返品
                 ,return_goods_b            =   invrcp_daily_rec.return_goods_b           -- 15.返品振戻
                 ,warehouse_ship            =   invrcp_daily_rec.warehouse_ship           -- 16.倉庫へ返庫
                 ,truck_ship                =   invrcp_daily_rec.truck_ship               -- 17.営業車へ出庫
                 ,others_ship               =   invrcp_daily_rec.others_ship              -- 18.入出庫＿その他出庫
                 ,warehouse_stock           =   invrcp_daily_rec.warehouse_stock          -- 19.倉庫より入庫
                 ,truck_stock               =   invrcp_daily_rec.truck_stock              -- 20.営業車より入庫
                 ,others_stock              =   invrcp_daily_rec.others_stock             -- 21.入出庫＿その他入庫
                 ,change_stock              =   invrcp_daily_rec.change_stock             -- 22.倉替入庫
                 ,change_ship               =   invrcp_daily_rec.change_ship              -- 23.倉替出庫
                 ,goods_transfer_old        =   invrcp_daily_rec.goods_transfer_old       -- 24.商品振替（旧商品）
                 ,goods_transfer_new        =   invrcp_daily_rec.goods_transfer_new       -- 25.商品振替（新商品）
                 ,sample_quantity           =   invrcp_daily_rec.sample_quantity          -- 26.見本出庫
                 ,sample_quantity_b         =   invrcp_daily_rec.sample_quantity_b        -- 27.見本出庫振戻
                 ,customer_sample_ship      =   invrcp_daily_rec.customer_sample_ship     -- 28.顧客見本出庫
                 ,customer_sample_ship_b    =   invrcp_daily_rec.customer_sample_ship_b   -- 29.顧客見本出庫振戻
                 ,customer_support_ss       =   invrcp_daily_rec.customer_support_ss      -- 30.顧客協賛見本出庫
                 ,customer_support_ss_b     =   invrcp_daily_rec.customer_support_ss_b    -- 31.顧客協賛見本出庫振戻
                 ,ccm_sample_ship           =   invrcp_daily_rec.ccm_sample_ship          -- 32.顧客広告宣伝費a自社商品
                 ,ccm_sample_ship_b         =   invrcp_daily_rec.ccm_sample_ship_b        -- 33.顧客広告宣伝費a自社商品振戻
                 ,vd_supplement_stock       =   invrcp_daily_rec.vd_supplement_stock      -- 34.消化vd補充入庫
                 ,vd_supplement_ship        =   invrcp_daily_rec.vd_supplement_ship       -- 35.消化vd補充出庫
                 ,inventory_change_in       =   invrcp_daily_rec.inventory_change_in      -- 36.基準在庫変更入庫
                 ,inventory_change_out      =   invrcp_daily_rec.inventory_change_out     -- 37.基準在庫変更出庫
                 ,factory_return            =   invrcp_daily_rec.factory_return           -- 38.工場返品
                 ,factory_return_b          =   invrcp_daily_rec.factory_return_b         -- 39.工場返品振戻
                 ,factory_change            =   invrcp_daily_rec.factory_change           -- 40.工場倉替
                 ,factory_change_b          =   invrcp_daily_rec.factory_change_b         -- 41.工場倉替振戻
                 ,removed_goods             =   invrcp_daily_rec.removed_goods            -- 42.廃却
                 ,removed_goods_b           =   invrcp_daily_rec.removed_goods_b          -- 43.廃却振戻
                 ,factory_stock             =   invrcp_daily_rec.factory_stock            -- 44.工場入庫
                 ,factory_stock_b           =   invrcp_daily_rec.factory_stock_b          -- 45.工場入庫振戻
                 ,wear_decrease             =   invrcp_daily_rec.wear_decrease            -- 46.棚卸減耗増
                 ,wear_increase             =   invrcp_daily_rec.wear_increase            -- 47.棚卸減耗減
                 ,selfbase_ship             =   invrcp_daily_rec.selfbase_ship            -- 48.保管場所移動＿自拠点出庫
                 ,selfbase_stock            =   invrcp_daily_rec.selfbase_stock           -- 49.保管場所移動＿自拠点入庫
                 ,inv_wear                  =   inv_wear + ln_inv_wear                    -- 52.棚卸減耗
                 ,last_update_date          =   SYSDATE                                   -- 最終更新日
                 ,last_updated_by           =   cn_last_updated_by                        -- 最終更新者
                 ,last_update_login         =   cn_last_update_login                      -- 最終更新ユーザ
                 ,request_id                =   cn_request_id                             -- 要求ID
                 ,program_application_id    =   cn_program_application_id                 -- プログラムアプリケーションID
                 ,program_id                =   cn_program_id                             -- プログラムID
                 ,program_update_date       =   SYSDATE                                   -- プログラム更新日
          WHERE   base_code            =   invrcp_daily_rec.base_code
          AND     subinventory_code    =   invrcp_daily_rec.subinventory_code
          AND     inventory_item_id    =   invrcp_daily_rec.inventory_item_id
          AND     organization_id      =   gn_f_organization_id
          AND     practice_month       =   gv_f_inv_acct_period
          AND     inventory_kbn        =   gv_param_inventory_kbn;
        ELSE
          -- 起動フラグ：１（コンカレント起動）の場合、常に新規作成
          RAISE NO_DATA_FOUND;
          --
        END IF;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 月次在庫受払表作成
          --
          INSERT INTO xxcoi_inv_reception_monthly(
            inv_seq                                   -- 01.棚卸SEQ
           ,base_code                                 -- 02.拠点コード
           ,organization_id                           -- 03.組織id
           ,subinventory_code                         -- 04.保管場所
           ,subinventory_type                         -- 05.保管場所区分
           ,practice_month                            -- 06.年月
           ,practice_date                             -- 07.年月日
           ,inventory_kbn                             -- 08.棚卸区分
           ,inventory_item_id                         -- 09.品目ID
           ,operation_cost                            -- 10.営業原価
           ,standard_cost                             -- 11.標準原価
           ,sales_shipped                             -- 12.売上出庫
           ,sales_shipped_b                           -- 13.売上出庫振戻
           ,return_goods                              -- 14.返品
           ,return_goods_b                            -- 15.返品振戻
           ,warehouse_ship                            -- 16.倉庫へ返庫
           ,truck_ship                                -- 17.営業車へ出庫
           ,others_ship                               -- 18.入出庫＿その他出庫
           ,warehouse_stock                           -- 19.倉庫より入庫
           ,truck_stock                               -- 20.営業車より入庫
           ,others_stock                              -- 21.入出庫＿その他入庫
           ,change_stock                              -- 22.倉替入庫
           ,change_ship                               -- 23.倉替出庫
           ,goods_transfer_old                        -- 24.商品振替（旧商品）
           ,goods_transfer_new                        -- 25.商品振替（新商品）
           ,sample_quantity                           -- 26.見本出庫
           ,sample_quantity_b                         -- 27.見本出庫振戻
           ,customer_sample_ship                      -- 28.顧客見本出庫
           ,customer_sample_ship_b                    -- 29.顧客見本出庫振戻
           ,customer_support_ss                       -- 30.顧客協賛見本出庫
           ,customer_support_ss_b                     -- 31.顧客協賛見本出庫振戻
           ,ccm_sample_ship                           -- 32.顧客広告宣伝費a自社商品
           ,ccm_sample_ship_b                         -- 33.顧客広告宣伝費a自社商品振戻
           ,vd_supplement_stock                       -- 34.消化vd補充入庫
           ,vd_supplement_ship                        -- 35.消化vd補充出庫
           ,inventory_change_in                       -- 36.基準在庫変更入庫
           ,inventory_change_out                      -- 37.基準在庫変更出庫
           ,factory_return                            -- 38.工場返品
           ,factory_return_b                          -- 39.工場返品振戻
           ,factory_change                            -- 40.工場倉替
           ,factory_change_b                          -- 41.工場倉替振戻
           ,removed_goods                             -- 42.廃却
           ,removed_goods_b                           -- 43.廃却振戻
           ,factory_stock                             -- 44.工場入庫
           ,factory_stock_b                           -- 45.工場入庫振戻
           ,wear_decrease                             -- 46.棚卸減耗増
           ,wear_increase                             -- 47.棚卸減耗減
           ,selfbase_ship                             -- 48.保管場所移動＿自拠点出庫
           ,selfbase_stock                            -- 49.保管場所移動＿自拠点入庫
           ,inv_result                                -- 50.棚卸結果
           ,inv_result_bad                            -- 51.棚卸結果（不良品）
           ,inv_wear                                  -- 52.棚卸減耗
           ,month_begin_quantity                      -- 53.月首棚卸高
           ,last_update_date                          -- 54.最終更新日
           ,last_updated_by                           -- 55.最終更新者
           ,creation_date                             -- 56.作成日
           ,created_by                                -- 57.作成者
           ,last_update_login                         -- 58.最終更新ユーザ
           ,request_id                                -- 59.要求ID
           ,program_application_id                    -- 60.プログラムアプリケーションID
           ,program_id                                -- 61.プログラムID
           ,program_update_date                       -- 62.プログラム更新日
          )VALUES(
            1                                         -- 01
           ,invrcp_daily_rec.base_code                -- 02
           ,invrcp_daily_rec.organization_id          -- 03
           ,invrcp_daily_rec.subinventory_code        -- 04
           ,invrcp_daily_rec.subinventory_type        -- 05
           ,gv_f_inv_acct_period                      -- 06
           ,ld_practice_date                          -- 07
           ,gv_param_inventory_kbn                    -- 08
           ,invrcp_daily_rec.inventory_item_id        -- 09
           ,invrcp_daily_rec.operation_cost           -- 10
           ,invrcp_daily_rec.standard_cost            -- 11
           ,invrcp_daily_rec.sales_shipped            -- 12
           ,invrcp_daily_rec.sales_shipped_b          -- 13
           ,invrcp_daily_rec.return_goods             -- 14
           ,invrcp_daily_rec.return_goods_b           -- 15
           ,invrcp_daily_rec.warehouse_ship           -- 16
           ,invrcp_daily_rec.truck_ship               -- 17
           ,invrcp_daily_rec.others_ship              -- 18
           ,invrcp_daily_rec.warehouse_stock          -- 19
           ,invrcp_daily_rec.truck_stock              -- 20
           ,invrcp_daily_rec.others_stock             -- 21
           ,invrcp_daily_rec.change_stock             -- 22
           ,invrcp_daily_rec.change_ship              -- 23
           ,invrcp_daily_rec.goods_transfer_old       -- 24
           ,invrcp_daily_rec.goods_transfer_new       -- 25
           ,invrcp_daily_rec.sample_quantity          -- 26
           ,invrcp_daily_rec.sample_quantity_b        -- 27
           ,invrcp_daily_rec.customer_sample_ship     -- 28
           ,invrcp_daily_rec.customer_sample_ship_b   -- 29
           ,invrcp_daily_rec.customer_support_ss      -- 30
           ,invrcp_daily_rec.customer_support_ss_b    -- 31
           ,invrcp_daily_rec.ccm_sample_ship          -- 32
           ,invrcp_daily_rec.ccm_sample_ship_b        -- 33
           ,invrcp_daily_rec.vd_supplement_stock      -- 34
           ,invrcp_daily_rec.vd_supplement_ship       -- 35
           ,invrcp_daily_rec.inventory_change_in      -- 36
           ,invrcp_daily_rec.inventory_change_out     -- 37
           ,invrcp_daily_rec.factory_return           -- 38
           ,invrcp_daily_rec.factory_return_b         -- 39
           ,invrcp_daily_rec.factory_change           -- 40
           ,invrcp_daily_rec.factory_change_b         -- 41
           ,invrcp_daily_rec.removed_goods            -- 42
           ,invrcp_daily_rec.removed_goods_b          -- 43
           ,invrcp_daily_rec.factory_stock            -- 44
           ,invrcp_daily_rec.factory_stock_b          -- 45
           ,invrcp_daily_rec.wear_decrease            -- 46
           ,invrcp_daily_rec.wear_increase            -- 47
           ,invrcp_daily_rec.selfbase_ship            -- 48
           ,invrcp_daily_rec.selfbase_stock           -- 49
           ,0                                         -- 50
           ,0                                         -- 51
           ,ln_inv_wear                               -- 52
           ,0                                         -- 53
           ,SYSDATE                                   -- 54
           ,cn_last_updated_by                        -- 55
           ,SYSDATE                                   -- 56
           ,cn_created_by                             -- 57
           ,cn_last_update_login                      -- 58
           ,cn_request_id                             -- 59
           ,cn_program_application_id                 -- 60
           ,cn_program_id                             -- 61
           ,SYSDATE                                   -- 62
          );
          -- 成功件数（月次在庫受払の作成レコード数）
          gn_target_cnt :=  gn_target_cnt + 1;
          gn_normal_cnt :=  gn_normal_cnt + 1;
          --
        WHEN lock_error_expt THEN
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10145
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_process_expt;
      END;
        --
        -- キー情報（保管場所コード）を保持
        lt_key_subinv_code  :=  invrcp_daily_rec.subinventory_code;
        --
      END LOOP daily_data_loop;
      --
      -- ===================================
      --  CURSORクローズ
      -- ===================================
      IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
        CLOSE invrcp_daily_1_cur;
      ELSE
-- == 2010/01/05 V1.15 Modified START ===============================================================
--        CLOSE invrcp_daily_2_cur;
        --
        IF  (gv_param_exec_flag = cv_exec_1)  THEN
          -- 起動フラグ：１（コンカレント起動）
          CLOSE invrcp_daily_2_cur;
        ELSE
          -- 起動フラグ：３（夜間強制確定（日次情報取込））
          CLOSE invrcp_daily_3_cur;
        END IF;
-- == 2010/01/05 V1.15 Modified END   ===============================================================
      END IF;
    --
  EXCEPTION
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
  END ins_invrcp_daily;
-- == 2009/08/20 V1.14 Modified END   ===============================================================
--
  /**********************************************************************************
   * Procedure Name   : del_invrcp_daily
   * Description      : 作成済み月次在庫受払データ削除(A-3)
   ***********************************************************************************/
  PROCEDURE del_invrcp_monthly(
    it_base_code      IN  xxcoi_inv_reception_monthly.base_code%TYPE,
                                                        -- 1.拠点コード
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_invrcp_monthly'; -- プログラム名
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
    ln_dummy      NUMBER(1);                    -- ダミー変数
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    CURSOR  monthly_lock_conc_cur
    IS
      SELECT  1
      FROM    xxcoi_inv_reception_monthly   xirm            -- 月次在庫受払表（月次）
      WHERE   xirm.organization_id    =   gn_f_organization_id
      AND     xirm.base_code          =   it_base_code
      AND     xirm.inventory_kbn      =   gv_param_inventory_kbn
      AND     xirm.practice_month     =   gv_f_inv_acct_period
      FOR UPDATE NOWAIT;
    --
    CURSOR  monthly_lock_cur
    IS
      SELECT  1
      FROM    xxcoi_inv_reception_monthly   xirm            -- 月次在庫受払表（月次）
      WHERE   xirm.organization_id    =   gn_f_organization_id
      AND     xirm.inventory_kbn      =   gv_param_inventory_kbn
      AND     xirm.practice_month     =   gv_f_inv_acct_period
      FOR UPDATE NOWAIT;
    --
-- == 2010/12/14 V1.17 Added START ===============================================================
    CURSOR  tmp_lock_conc_cur
    IS
      SELECT  1
      FROM    xxcoi_inv_rcp_monthly_tmp   xirmt
      WHERE   xirmt.base_code         =   it_base_code
      FOR UPDATE NOWAIT;
    --
    CURSOR  tmp_lock_cur
    IS
      SELECT  1
      FROM    xxcoi_inv_rcp_monthly_tmp   xirmt
      FOR UPDATE NOWAIT;
-- == 2010/12/14 V1.17 Added END   ===============================================================
    --
    -- <カーソル名>レコード型
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- ===================================
    --  1.月次在庫受払表削除
    -- ===================================
    BEGIN
      IF (gv_param_exec_flag = cv_exec_1) THEN
        -- 「コンカレント起動」の場合
        -- ロック取得
        OPEN  monthly_lock_conc_cur;
        CLOSE monthly_lock_conc_cur;
        --
        -- 削除処理
        DELETE FROM xxcoi_inv_reception_monthly
        WHERE   organization_id    =   gn_f_organization_id
        AND     base_code          =   it_base_code
        AND     inventory_kbn      =   gv_param_inventory_kbn
        AND     practice_month     =   gv_f_inv_acct_period;
        --
      ELSIF (gv_param_exec_flag = cv_exec_2) THEN
        -- 「月次夜間強制確定｣の場合
        -- ロック取得
        OPEN  monthly_lock_cur;
        CLOSE monthly_lock_cur;
        --
        -- 削除処理
        DELETE FROM xxcoi_inv_reception_monthly
        WHERE   organization_id    =   gn_f_organization_id
        AND     inventory_kbn      =   gv_param_inventory_kbn
        AND     practice_month     =   gv_f_inv_acct_period;
        --
      END IF;
      --
    EXCEPTION
      WHEN lock_error_expt THEN     -- ロック取得失敗時
        IF (monthly_lock_conc_cur%ISOPEN) THEN
          CLOSE monthly_lock_conc_cur;
        END IF;
        IF (monthly_lock_cur%ISOPEN) THEN
          CLOSE monthly_lock_cur;
        END IF;
        --
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name
                        ,iv_name         => cv_msg_xxcoi1_10145
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_process_expt;
    END;
-- == 2010/12/14 V1.17 Added START ===============================================================
    -- ===================================
    --  2.月次在庫一時表削除
    -- ===================================
    BEGIN
      IF (gv_param_exec_flag = cv_exec_1) THEN
        -- 「コンカレント起動」の場合
        --  一時表ロック
        OPEN  tmp_lock_conc_cur;
        CLOSE tmp_lock_conc_cur;
        --  一時表削除
        DELETE FROM xxcoi_inv_rcp_monthly_tmp
        WHERE   base_code         =   it_base_code;
      ELSIF (gv_param_exec_flag = cv_exec_2) THEN
        -- 「月次夜間強制確定｣の場合
        --  一時表ロック
        OPEN  tmp_lock_cur;
        CLOSE tmp_lock_cur;
        --  一時表削除
        DELETE FROM xxcoi_inv_rcp_monthly_tmp;
      END IF;
      --
    EXCEPTION
      WHEN lock_error_expt THEN     -- ロック取得失敗時
        IF (tmp_lock_conc_cur%ISOPEN) THEN
          CLOSE tmp_lock_conc_cur;
        END IF;
        IF (tmp_lock_cur%ISOPEN) THEN
          CLOSE tmp_lock_cur;
        END IF;
        --
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name
                        ,iv_name         => cv_msg_xxcoi1_10428
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_process_expt;
    END;
-- == 2010/12/14 V1.17 Added END   ===============================================================
--
  EXCEPTION
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
  END del_invrcp_monthly;
-- == 2010/12/14 V1.17 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : ins_inv_data(A-15, A-16)
   * Description      : 月首在庫、棚卸確定処理
   ***********************************************************************************/
  PROCEDURE ins_inv_data(
      it_base_code      IN  VARCHAR2                      --  対象拠点
    , ov_errbuf         OUT VARCHAR2                      --  エラー・メッセージ                  --# 固定 #
    , ov_retcode        OUT VARCHAR2                      --  リターン・コード                    --# 固定 #
    , ov_errmsg         OUT VARCHAR2                      --  ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inv_data'; -- プログラム名
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
    lt_standard_cost      xxcoi_inv_rcp_monthly_tmp.standard_cost%TYPE;
    lt_operation_cost     xxcoi_inv_rcp_monthly_tmp.operation_cost%TYPE;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    --  棚卸情報取得カーソル
    CURSOR  inv_qty_cur
    IS
      SELECT  msi.attribute7                                  base_code                         --  拠点コード
            , sub.subinventory_code                           subinventory_code                 --  保管場所コード
            , msib.inventory_item_id                          inventory_item_id                 --  品目ID
            , msi.attribute1                                  subinventory_type                 --  保管場所区分
            , SUM(CASE  WHEN  sub.month_type = 0
                          THEN  sub.inventory_quantity  ELSE  0 END
              )                                               month_begin_quantity              --  月首在庫数
            , SUM(CASE  WHEN  sub.month_type = 1 AND  sub.quality_goods_kbn = cv_quality_0
                          THEN  sub.inventory_quantity  ELSE  0 END
              )                                               inv_result                        --  棚卸数（良品）
            , SUM(CASE  WHEN  sub.month_type = 1 AND  sub.quality_goods_kbn = cv_quality_1
                          THEN  sub.inventory_quantity  ELSE  0 END
              )                                               inv_result_bad                    --  棚卸数（不良品）
      FROM    (
                --  月首在庫数（前月棚卸数）
                SELECT  xic.subinventory_code                           subinventory_code       --  保管場所
                      , xir.item_code                                   item_code               --  品目コード
                      , 0                                               month_type              --  月区分
                      , xir.quality_goods_kbn                           quality_goods_kbn       --  良品区分
                      , xir.case_qty * xir.case_in_qty + xir.quantity   inventory_quantity      --  棚卸数
                FROM    xxcoi_inv_control   xic
                      , xxcoi_inv_result    xir
                WHERE   xic.inventory_seq         =     xir.inventory_seq
                AND     xic.inventory_date        >=    ADD_MONTHS(TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month)), -1)
                AND     xic.inventory_date        <     TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
                AND     xic.inventory_kbn         =     cv_inv_kbn_2
                UNION ALL
                --  当月棚卸数
                SELECT  xic.subinventory_code                           subinventory_code       --  保管場所
                      , xir.item_code                                   item_code               --  品目コード
                      , 1                                               month_type              --  月区分
                      , xir.quality_goods_kbn                           quality_goods_kbn       --  良品区分
                      , xir.case_qty * xir.case_in_qty + xir.quantity   inventory_quantity      --  棚卸数
                FROM    xxcoi_inv_control   xic
                      , xxcoi_inv_result    xir
                WHERE   xic.inventory_seq         =     xir.inventory_seq
                AND     xic.inventory_date        >=    TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
                AND     xic.inventory_date        <     LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month)) + 1
                AND     xic.inventory_kbn         =     cv_inv_kbn_2
              )     sub
            , mtl_secondary_inventories   msi
            , mtl_system_items_b          msib
      WHERE   sub.subinventory_code     =   msi.secondary_inventory_name
      AND     sub.item_code             =   msib.segment1
      AND     msi.organization_id       =   gn_f_organization_id
      AND     msib.organization_id      =   gn_f_organization_id
      AND     msi.attribute7            =   NVL(it_base_code, msi.attribute7)
      GROUP BY  msi.attribute7
              , sub.subinventory_code
              , msib.inventory_item_id
              , msi.attribute1
      ;
    -- <カーソル名>レコード型
    TYPE rec_inv_qty  IS RECORD(
        base_code               xxcoi_inv_rcp_monthly_tmp.base_code%TYPE
      , subinventory_code       xxcoi_inv_rcp_monthly_tmp.subinventory_code%TYPE
      , inventory_item_id       xxcoi_inv_rcp_monthly_tmp.inventory_item_id%TYPE
      , subinventory_type       xxcoi_inv_rcp_monthly_tmp.subinventory_type%TYPE
      , month_begin_quantity    xxcoi_inv_rcp_monthly_tmp.month_begin_quantity%TYPE
      , inv_result              xxcoi_inv_rcp_monthly_tmp.inv_result%TYPE
      , inv_result_bad          xxcoi_inv_rcp_monthly_tmp.inv_result_bad%TYPE
    );
    TYPE  tab_inv_qty IS TABLE OF rec_inv_qty INDEX BY BINARY_INTEGER;
    inv_qty_tab                    tab_inv_qty;
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
    inv_qty_tab.DELETE;
    --
    OPEN  inv_qty_cur;
    --
    <<inv_qty_loop>>
    LOOP
      FETCH inv_qty_cur BULK COLLECT INTO inv_qty_tab LIMIT 50000;
      EXIT WHEN inv_qty_tab.COUNT = 0;
      --
      IF  (gv_param_exec_flag = cv_exec_2)  THEN
        --  夜間処理の場合別起動の為、カウントする
        gn_target_cnt   :=    gn_target_cnt + inv_qty_tab.COUNT;
      END IF;
      --
      -- ===============================
      --  原価取得
      -- ===============================
      <<set_cost_loop>>
      FOR ln_cnt IN 1 .. inv_qty_tab.COUNT LOOP
        IF  (inv_qty_tab(ln_cnt).inv_result = 0)
            AND
            (inv_qty_tab(ln_cnt).inv_result_bad = 0)
            AND
            (inv_qty_tab(ln_cnt).month_begin_quantity = 0)
        THEN
          --  月首在庫、在庫（良品）、在庫（不良品）が全て０の場合、レコードを作成しない
          IF  (gv_param_exec_flag = cv_exec_2)  THEN
            --  夜間処理の場合別起動の為、カウントする
            gn_target_cnt :=  gn_target_cnt - 1;
          END IF;
        ELSE
          -- ===================================
          --  標準原価取得
          -- ===================================
          xxcoi_common_pkg.get_cmpnt_cost(
              in_item_id        =>  inv_qty_tab(ln_cnt).inventory_item_id               --  品目ID
            , in_org_id         =>  gn_f_organization_id                                --  組織ID
            , id_period_date    =>  LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month))   --  対象日
            , ov_cmpnt_cost     =>  lt_standard_cost                                    --  標準原価
            , ov_errbuf         =>  lv_errbuf                                           --  エラーメッセージ
            , ov_retcode        =>  lv_retcode                                          --  リターン・コード
            , ov_errmsg         =>  lv_errmsg                                           --  ユーザー・エラーメッセージ
          );
          -- 終了パラメータ判定
          IF (lv_retcode = cv_status_error) OR (lt_standard_cost IS NULL) THEN
            lv_errmsg   :=  xxccp_common_pkg.get_msg(
                                iv_application    =>  cv_short_name
                              , iv_name           =>  cv_msg_xxcoi1_10285
                            );
            lv_errbuf   :=  lv_errmsg;
            RAISE global_api_expt;
          END IF;
          --
          -- ===================================
          --  営業原価取得
          -- ===================================
          xxcoi_common_pkg.get_discrete_cost(
              in_item_id        =>  inv_qty_tab(ln_cnt).inventory_item_id               --  品目ID
            , in_org_id         =>  gn_f_organization_id                                --  組織ID
            , id_target_date    =>  LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month))   --  対象日
            , ov_discrete_cost  =>  lt_operation_cost                                   --  営業原価
            , ov_errbuf         =>  lv_errbuf                                           --  エラーメッセージ
            , ov_retcode        =>  lv_retcode                                          --  リターン・コード
            , ov_errmsg         =>  lv_errmsg                                           --  ユーザー・エラーメッセージ
          );
          -- 終了パラメータ判定
          IF (lv_retcode = cv_status_error) OR (lt_operation_cost IS NULL) THEN
            lv_errmsg   :=  xxccp_common_pkg.get_msg(
                                iv_application    =>  cv_short_name
                              , iv_name           =>  cv_msg_xxcoi1_10293
                            );
            lv_errbuf   :=  lv_errmsg;
            RAISE global_api_expt;
          END IF;
          --
          -- ===============================
          --  月首在庫、棚卸確定
          -- ===============================
          INSERT INTO xxcoi_inv_rcp_monthly_tmp(
              base_code
            , subinventory_code
            , inventory_item_id
            , subinventory_type
            , operation_cost
            , standard_cost
            , sales_shipped
            , sales_shipped_b
            , return_goods
            , return_goods_b
            , warehouse_ship
            , truck_ship
            , others_ship
            , warehouse_stock
            , truck_stock
            , others_stock
            , change_stock
            , change_ship
            , goods_transfer_old
            , goods_transfer_new
            , sample_quantity
            , sample_quantity_b
            , customer_sample_ship
            , customer_sample_ship_b
            , customer_support_ss
            , customer_support_ss_b
            , ccm_sample_ship
            , ccm_sample_ship_b
            , vd_supplement_stock
            , vd_supplement_ship
            , inventory_change_in
            , inventory_change_out
            , factory_return
            , factory_return_b
            , factory_change
            , factory_change_b
            , removed_goods
            , removed_goods_b
            , factory_stock
            , factory_stock_b
            , wear_decrease
            , wear_increase
            , selfbase_ship
            , selfbase_stock
            , inv_result
            , inv_result_bad
            , inv_wear
            , month_begin_quantity
          )VALUES(
              inv_qty_tab(ln_cnt).base_code
            , inv_qty_tab(ln_cnt).subinventory_code
            , inv_qty_tab(ln_cnt).inventory_item_id
            , inv_qty_tab(ln_cnt).subinventory_type
            , lt_operation_cost
            , lt_standard_cost
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , 0
            , inv_qty_tab(ln_cnt).inv_result
            , inv_qty_tab(ln_cnt).inv_result_bad
            , 0
            , inv_qty_tab(ln_cnt).month_begin_quantity
          );
        END IF;
      END LOOP set_cost_loop;
      --
    END LOOP  inv_qty_loop;
    --
    CLOSE inv_qty_cur;
    --
    -- ===============================
    --  棚卸ステータス更新
    -- ===============================
    UPDATE    xxcoi_inv_control   xic
    SET       xic.inventory_status          =   cv_invsts_2
            , xic.last_updated_by           =   cn_created_by
            , xic.last_update_date          =   SYSDATE
            , xic.last_update_login         =   cn_last_update_login
            , xic.request_id                =   cn_request_id
            , xic.program_application_id    =   cn_program_application_id
            , xic.program_id                =   cn_program_id
            , xic.program_update_date       =   SYSDATE
    WHERE xic.inventory_kbn     =   cv_inv_kbn_2
    AND   xic.inventory_date    >=  TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
    AND   xic.inventory_date    <   LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month)) + 1
    AND   xic.inventory_status  =   cv_invsts_1
    AND EXISTS( SELECT  1                             --  手動実行の場合、該当する拠点（保管場所）のみ更新
                FROM    mtl_secondary_inventories   msi
                WHERE   msi.attribute7                  =   NVL(it_base_code, msi.attribute7)
                AND     msi.secondary_inventory_name    =   xic.subinventory_code
        )
    ;
    --  成功件数
    IF  (gv_param_exec_flag = cv_exec_2)  THEN
      --  夜間処理の場合別起動の為、カウントする
      gn_normal_cnt :=  gn_target_cnt;
    END IF;
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
  END ins_inv_data;
  --
  /**********************************************************************************
   * Procedure Name   : ins_month_tran_data(A-17, A-18)
   * Description      : 受払情報確定処理
   ***********************************************************************************/
  PROCEDURE ins_month_tran_data(
      it_base_code      IN  VARCHAR2                      --  対象拠点
    , ov_errbuf         OUT VARCHAR2                      --  エラー・メッセージ                  --# 固定 #
    , ov_retcode        OUT VARCHAR2                      --  リターン・コード                    --# 固定 #
    , ov_errmsg         OUT VARCHAR2                      --  ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_month_tran_data'; -- プログラム名
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
    TYPE rec_chk_inv  IS RECORD(
        base_code           xxcoi_inv_control.base_code%TYPE
      , subinventory_code   xxcoi_inv_control.subinventory_code%TYPE
      , subinventory_type   xxcoi_inv_control.warehouse_kbn%TYPE
    );
    TYPE  tab_chk_inv IS TABLE OF rec_chk_inv INDEX BY VARCHAR2(30);
    lt_chk_inv            tab_chk_inv;
    lt_add_inv            tab_chk_inv;
    --
    ln_set_cnt        NUMBER;
    ln_dummy          NUMBER;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    --  月末コンカレント実行（拠点指定）
    CURSOR  invrcp1_qty_cur
    IS
      SELECT  /*+ LEADING(msi)  */
          xirs.base_code                      base_code                       --  拠点コード
        , xirs.subinventory_code              subinventory_code               --  保管場所
        , xirs.inventory_item_id              inventory_item_id               --  品目ID
        , xirs.subinventory_type              subinventory_type               --  保管場所区分
        , xirs.operation_cost                 operation_cost                  --  営業原価
        , xirs.standard_cost                  standard_cost                   --  標準原価
        , xirs.sales_shipped                  sales_shipped                   --  売上出庫
        , xirs.sales_shipped_b                sales_shipped_b                 --  売上出庫振戻
        , xirs.return_goods                   return_goods                    --  返品
        , xirs.return_goods_b                 return_goods_b                  --  返品振戻
        , xirs.warehouse_ship                 warehouse_ship                  --  倉庫へ返庫
        , xirs.truck_ship                     truck_ship                      --  営業車へ出庫
        , xirs.others_ship                    others_ship                     --  入出庫＿その他出庫
        , xirs.warehouse_stock                warehouse_stock                 --  倉庫より入庫
        , xirs.truck_stock                    truck_stock                     --  営業車より入庫
        , xirs.others_stock                   others_stock                    --  入出庫＿その他入庫
        , xirs.change_stock                   change_stock                    --  倉替入庫
        , xirs.change_ship                    change_ship                     --  倉替出庫
        , xirs.goods_transfer_old             goods_transfer_old              --  商品振替（旧商品）
        , xirs.goods_transfer_new             goods_transfer_new              --  商品振替（新商品）
        , xirs.sample_quantity                sample_quantity                 --  見本出庫
        , xirs.sample_quantity_b              sample_quantity_b               --  見本出庫振戻
        , xirs.customer_sample_ship           customer_sample_ship            --  顧客見本出庫
        , xirs.customer_sample_ship_b         customer_sample_ship_b          --  顧客見本出庫振戻
        , xirs.customer_support_ss            customer_support_ss             --  顧客協賛見本出庫
        , xirs.customer_support_ss_b          customer_support_ss_b           --  顧客協賛見本出庫振戻
        , xirs.ccm_sample_ship                ccm_sample_ship                 --  顧客広告宣伝費A自社商品
        , xirs.ccm_sample_ship_b              ccm_sample_ship_b               --  顧客広告宣伝費A自社商品振戻
        , xirs.vd_supplement_stock            vd_supplement_stock             --  消化VD補充入庫
        , xirs.vd_supplement_ship             vd_supplement_ship              --  消化VD補充出庫
        , xirs.inventory_change_in            inventory_change_in             --  基準在庫変更入庫
        , xirs.inventory_change_out           inventory_change_out            --  基準在庫変更出庫
        , xirs.factory_return                 factory_return                  --  工場返品
        , xirs.factory_return_b               factory_return_b                --  工場返品振戻
        , xirs.factory_change                 factory_change                  --  工場倉替
        , xirs.factory_change_b               factory_change_b                --  工場倉替振戻
        , xirs.removed_goods                  removed_goods                   --  廃却
        , xirs.removed_goods_b                removed_goods_b                 --  廃却振戻
        , xirs.factory_stock                  factory_stock                   --  工場入庫
        , xirs.factory_stock_b                factory_stock_b                 --  工場入庫振戻
        , xirs.wear_decrease                  wear_decrease                   --  棚卸減耗増
        , xirs.wear_increase                  wear_increase                   --  棚卸減耗減
        , xirs.selfbase_ship                  selfbase_ship                   --  保管場所移動＿自拠点出庫
        , xirs.selfbase_stock                 selfbase_stock                  --  保管場所移動＿自拠点入庫
        , NVL(xirmt.inv_result, 0)            inv_result                      --  棚卸結果
        , NVL(xirmt.inv_result_bad, 0)        inv_result_bad                  --  棚卸結果（不良品）
        , xirs.sales_shipped                    * -1  + xirs.sales_shipped_b          *  1
          + xirs.return_goods                   *  1  + xirs.return_goods_b           * -1
          + xirs.warehouse_ship                 * -1  + xirs.truck_ship               * -1
          + xirs.others_ship                    * -1  + xirs.warehouse_stock          *  1
          + xirs.truck_stock                    *  1  + xirs.others_stock             *  1
          + xirs.change_stock                   *  1  + xirs.change_ship              * -1
          + xirs.goods_transfer_old             * -1  + xirs.goods_transfer_new       *  1
          + xirs.sample_quantity                * -1  + xirs.sample_quantity_b        *  1
          + xirs.customer_sample_ship           * -1  + xirs.customer_sample_ship_b   *  1
          + xirs.customer_support_ss            * -1  + xirs.customer_support_ss_b    *  1
          + xirs.ccm_sample_ship                * -1  + xirs.ccm_sample_ship_b        *  1
          + xirs.vd_supplement_stock            *  1  + xirs.vd_supplement_ship       * -1
          + xirs.inventory_change_in            *  1  + xirs.inventory_change_out     * -1
          + xirs.factory_return                 * -1  + xirs.factory_return_b         *  1
          + xirs.factory_change                 * -1  + xirs.factory_change_b         *  1
          + xirs.removed_goods                  * -1  + xirs.removed_goods_b          *  1
          + xirs.factory_stock                  *  1  + xirs.factory_stock_b          * -1
          + xirs.wear_decrease                  *  1  + xirs.wear_increase            * -1
          + xirs.selfbase_ship                  * -1  + xirs.selfbase_stock           *  1
          + NVL(xirmt.inv_result, 0)            * -1  + NVL(xirmt.inv_result_bad, 0)  * -1
          + NVL(xirmt.month_begin_quantity, 0)  *  1
                                              inv_wear                        --  棚卸減耗
        , NVL(xirmt.month_begin_quantity, 0)  month_begin_quantity            --  月首棚卸高
      FROM    xxcoi_inv_reception_sum     xirs
            , xxcoi_inv_rcp_monthly_tmp   xirmt
            , mtl_secondary_inventories   msi
      WHERE   xirs.base_code              =   msi.attribute7
      AND     xirs.subinventory_code      =   msi.secondary_inventory_name
      AND     xirs.organization_id        =   gn_f_organization_id
      AND     xirs.practice_date          =   gv_f_inv_acct_period
      AND     msi.organization_id         =   gn_f_organization_id
      AND     msi.attribute7              =   it_base_code
      AND     xirs.base_code              =   xirmt.base_code(+)
      AND     xirs.subinventory_code      =   xirmt.subinventory_code(+)
      AND     xirs.inventory_item_id      =   xirmt.inventory_item_id(+)
      UNION ALL
      SELECT
          xirmt.base_code                     base_code                       --  拠点コード
        , xirmt.subinventory_code             subinventory_code               --  保管場所
        , xirmt.inventory_item_id             inventory_item_id               --  品目ID
        , xirmt.subinventory_type             subinventory_type               --  保管場所区分
        , xirmt.operation_cost                operation_cost                  --  営業原価
        , xirmt.standard_cost                 standard_cost                   --  標準原価
        , 0                                   sales_shipped                   --  売上出庫
        , 0                                   sales_shipped_b                 --  売上出庫振戻
        , 0                                   return_goods                    --  返品
        , 0                                   return_goods_b                  --  返品振戻
        , 0                                   warehouse_ship                  --  倉庫へ返庫
        , 0                                   truck_ship                      --  営業車へ出庫
        , 0                                   others_ship                     --  入出庫＿その他出庫
        , 0                                   warehouse_stock                 --  倉庫より入庫
        , 0                                   truck_stock                     --  営業車より入庫
        , 0                                   others_stock                    --  入出庫＿その他入庫
        , 0                                   change_stock                    --  倉替入庫
        , 0                                   change_ship                     --  倉替出庫
        , 0                                   goods_transfer_old              --  商品振替（旧商品）
        , 0                                   goods_transfer_new              --  商品振替（新商品）
        , 0                                   sample_quantity                 --  見本出庫
        , 0                                   sample_quantity_b               --  見本出庫振戻
        , 0                                   customer_sample_ship            --  顧客見本出庫
        , 0                                   customer_sample_ship_b          --  顧客見本出庫振戻
        , 0                                   customer_support_ss             --  顧客協賛見本出庫
        , 0                                   customer_support_ss_b           --  顧客協賛見本出庫振戻
        , 0                                   ccm_sample_ship                 --  顧客広告宣伝費A自社商品
        , 0                                   ccm_sample_ship_b               --  顧客広告宣伝費A自社商品振戻
        , 0                                   vd_supplement_stock             --  消化VD補充入庫
        , 0                                   vd_supplement_ship              --  消化VD補充出庫
        , 0                                   inventory_change_in             --  基準在庫変更入庫
        , 0                                   inventory_change_out            --  基準在庫変更出庫
        , 0                                   factory_return                  --  工場返品
        , 0                                   factory_return_b                --  工場返品振戻
        , 0                                   factory_change                  --  工場倉替
        , 0                                   factory_change_b                --  工場倉替振戻
        , 0                                   removed_goods                   --  廃却
        , 0                                   removed_goods_b                 --  廃却振戻
        , 0                                   factory_stock                   --  工場入庫
        , 0                                   factory_stock_b                 --  工場入庫振戻
        , 0                                   wear_decrease                   --  棚卸減耗増
        , 0                                   wear_increase                   --  棚卸減耗減
        , 0                                   selfbase_ship                   --  保管場所移動＿自拠点出庫
        , 0                                   selfbase_stock                  --  保管場所移動＿自拠点入庫
        , xirmt.inv_result                    inv_result                      --  棚卸結果
        , xirmt.inv_result_bad                inv_result_bad                  --  棚卸結果（不良品）
        , xirmt.inv_result  * -1  + xirmt.inv_result_bad  * -1
          + xirmt.month_begin_quantity  *  1
                                              inv_wear                        --  棚卸減耗
        , xirmt.month_begin_quantity          month_begin_quantity            --  月首棚卸高
      FROM    xxcoi_inv_rcp_monthly_tmp   xirmt
      WHERE   xirmt.base_code             =   it_base_code
      AND   NOT EXISTS( SELECT  /*+ LEADING(msi)  */
                                1
                        FROM    xxcoi_inv_reception_sum     xirs
                              , mtl_secondary_inventories   msi
                        WHERE   xirs.base_code              =   msi.attribute7
                        AND     xirs.subinventory_code      =   msi.secondary_inventory_name
                        AND     xirs.organization_id        =   gn_f_organization_id
                        AND     xirs.practice_date          =   gv_f_inv_acct_period
                        AND     msi.organization_id         =   gn_f_organization_id
                        AND     msi.attribute7              =   it_base_code
                        AND     xirs.base_code              =   xirmt.base_code
                        AND     xirs.subinventory_code      =   xirmt.subinventory_code
                        AND     xirs.inventory_item_id      =   xirmt.inventory_item_id
                )
      ;
    --
    --  月末強制確定（全拠点）
    CURSOR  invrcp2_qty_cur
    IS
      SELECT
          xirs.base_code                      base_code                       --  拠点コード
        , xirs.subinventory_code              subinventory_code               --  保管場所
        , xirs.inventory_item_id              inventory_item_id               --  品目ID
        , xirs.subinventory_type              subinventory_type               --  保管場所区分
        , xirs.operation_cost                 operation_cost                  --  営業原価
        , xirs.standard_cost                  standard_cost                   --  標準原価
        , xirs.sales_shipped                  sales_shipped                   --  売上出庫
        , xirs.sales_shipped_b                sales_shipped_b                 --  売上出庫振戻
        , xirs.return_goods                   return_goods                    --  返品
        , xirs.return_goods_b                 return_goods_b                  --  返品振戻
        , xirs.warehouse_ship                 warehouse_ship                  --  倉庫へ返庫
        , xirs.truck_ship                     truck_ship                      --  営業車へ出庫
        , xirs.others_ship                    others_ship                     --  入出庫＿その他出庫
        , xirs.warehouse_stock                warehouse_stock                 --  倉庫より入庫
        , xirs.truck_stock                    truck_stock                     --  営業車より入庫
        , xirs.others_stock                   others_stock                    --  入出庫＿その他入庫
        , xirs.change_stock                   change_stock                    --  倉替入庫
        , xirs.change_ship                    change_ship                     --  倉替出庫
        , xirs.goods_transfer_old             goods_transfer_old              --  商品振替（旧商品）
        , xirs.goods_transfer_new             goods_transfer_new              --  商品振替（新商品）
        , xirs.sample_quantity                sample_quantity                 --  見本出庫
        , xirs.sample_quantity_b              sample_quantity_b               --  見本出庫振戻
        , xirs.customer_sample_ship           customer_sample_ship            --  顧客見本出庫
        , xirs.customer_sample_ship_b         customer_sample_ship_b          --  顧客見本出庫振戻
        , xirs.customer_support_ss            customer_support_ss             --  顧客協賛見本出庫
        , xirs.customer_support_ss_b          customer_support_ss_b           --  顧客協賛見本出庫振戻
        , xirs.ccm_sample_ship                ccm_sample_ship                 --  顧客広告宣伝費A自社商品
        , xirs.ccm_sample_ship_b              ccm_sample_ship_b               --  顧客広告宣伝費A自社商品振戻
        , xirs.vd_supplement_stock            vd_supplement_stock             --  消化VD補充入庫
        , xirs.vd_supplement_ship             vd_supplement_ship              --  消化VD補充出庫
        , xirs.inventory_change_in            inventory_change_in             --  基準在庫変更入庫
        , xirs.inventory_change_out           inventory_change_out            --  基準在庫変更出庫
        , xirs.factory_return                 factory_return                  --  工場返品
        , xirs.factory_return_b               factory_return_b                --  工場返品振戻
        , xirs.factory_change                 factory_change                  --  工場倉替
        , xirs.factory_change_b               factory_change_b                --  工場倉替振戻
        , xirs.removed_goods                  removed_goods                   --  廃却
        , xirs.removed_goods_b                removed_goods_b                 --  廃却振戻
        , xirs.factory_stock                  factory_stock                   --  工場入庫
        , xirs.factory_stock_b                factory_stock_b                 --  工場入庫振戻
        , xirs.wear_decrease                  wear_decrease                   --  棚卸減耗増
        , xirs.wear_increase                  wear_increase                   --  棚卸減耗減
        , xirs.selfbase_ship                  selfbase_ship                   --  保管場所移動＿自拠点出庫
        , xirs.selfbase_stock                 selfbase_stock                  --  保管場所移動＿自拠点入庫
        , NVL(xirmt.inv_result, 0)            inv_result                      --  棚卸結果
        , NVL(xirmt.inv_result_bad, 0)        inv_result_bad                  --  棚卸結果（不良品）
        , xirs.sales_shipped              * -1  + xirs.sales_shipped_b          *  1
          + xirs.return_goods             *  1  + xirs.return_goods_b           * -1
          + xirs.warehouse_ship           * -1  + xirs.truck_ship               * -1
          + xirs.others_ship              * -1  + xirs.warehouse_stock          *  1
          + xirs.truck_stock              *  1  + xirs.others_stock             *  1
          + xirs.change_stock             *  1  + xirs.change_ship              * -1
          + xirs.goods_transfer_old       * -1  + xirs.goods_transfer_new       *  1
          + xirs.sample_quantity          * -1  + xirs.sample_quantity_b        *  1
          + xirs.customer_sample_ship     * -1  + xirs.customer_sample_ship_b   *  1
          + xirs.customer_support_ss      * -1  + xirs.customer_support_ss_b    *  1
          + xirs.ccm_sample_ship          * -1  + xirs.ccm_sample_ship_b        *  1
          + xirs.vd_supplement_stock      *  1  + xirs.vd_supplement_ship       * -1
          + xirs.inventory_change_in      *  1  + xirs.inventory_change_out     * -1
          + xirs.factory_return           * -1  + xirs.factory_return_b         *  1
          + xirs.factory_change           * -1  + xirs.factory_change_b         *  1
          + xirs.removed_goods            * -1  + xirs.removed_goods_b          *  1
          + xirs.factory_stock            *  1  + xirs.factory_stock_b          * -1
          + xirs.wear_decrease            *  1  + xirs.wear_increase            * -1
          + xirs.selfbase_ship            * -1  + xirs.selfbase_stock           *  1
          + NVL(xirmt.inv_result, 0)      * -1  + NVL(xirmt.inv_result_bad, 0)  * -1
          + NVL(xirmt.month_begin_quantity, 0)  *  1
                                              inv_wear                        --  棚卸減耗
        , NVL(xirmt.month_begin_quantity, 0)  month_begin_quantity            --  月首棚卸高
      FROM    xxcoi_inv_reception_sum     xirs
            , xxcoi_inv_rcp_monthly_tmp   xirmt
      WHERE   xirs.organization_id        =   gn_f_organization_id
      AND     xirs.practice_date          =   gv_f_inv_acct_period
      AND     xirs.base_code              =   xirmt.base_code(+)
      AND     xirs.subinventory_code      =   xirmt.subinventory_code(+)
      AND     xirs.inventory_item_id      =   xirmt.inventory_item_id(+)
      UNION ALL
      SELECT
          xirmt.base_code                     base_code                       --  拠点コード
        , xirmt.subinventory_code             subinventory_code               --  保管場所
        , xirmt.inventory_item_id             inventory_item_id               --  品目ID
        , xirmt.subinventory_type             subinventory_type               --  保管場所区分
        , xirmt.operation_cost                operation_cost                  --  営業原価
        , xirmt.standard_cost                 standard_cost                   --  標準原価
        , 0                                   sales_shipped                   --  売上出庫
        , 0                                   sales_shipped_b                 --  売上出庫振戻
        , 0                                   return_goods                    --  返品
        , 0                                   return_goods_b                  --  返品振戻
        , 0                                   warehouse_ship                  --  倉庫へ返庫
        , 0                                   truck_ship                      --  営業車へ出庫
        , 0                                   others_ship                     --  入出庫＿その他出庫
        , 0                                   warehouse_stock                 --  倉庫より入庫
        , 0                                   truck_stock                     --  営業車より入庫
        , 0                                   others_stock                    --  入出庫＿その他入庫
        , 0                                   change_stock                    --  倉替入庫
        , 0                                   change_ship                     --  倉替出庫
        , 0                                   goods_transfer_old              --  商品振替（旧商品）
        , 0                                   goods_transfer_new              --  商品振替（新商品）
        , 0                                   sample_quantity                 --  見本出庫
        , 0                                   sample_quantity_b               --  見本出庫振戻
        , 0                                   customer_sample_ship            --  顧客見本出庫
        , 0                                   customer_sample_ship_b          --  顧客見本出庫振戻
        , 0                                   customer_support_ss             --  顧客協賛見本出庫
        , 0                                   customer_support_ss_b           --  顧客協賛見本出庫振戻
        , 0                                   ccm_sample_ship                 --  顧客広告宣伝費A自社商品
        , 0                                   ccm_sample_ship_b               --  顧客広告宣伝費A自社商品振戻
        , 0                                   vd_supplement_stock             --  消化VD補充入庫
        , 0                                   vd_supplement_ship              --  消化VD補充出庫
        , 0                                   inventory_change_in             --  基準在庫変更入庫
        , 0                                   inventory_change_out            --  基準在庫変更出庫
        , 0                                   factory_return                  --  工場返品
        , 0                                   factory_return_b                --  工場返品振戻
        , 0                                   factory_change                  --  工場倉替
        , 0                                   factory_change_b                --  工場倉替振戻
        , 0                                   removed_goods                   --  廃却
        , 0                                   removed_goods_b                 --  廃却振戻
        , 0                                   factory_stock                   --  工場入庫
        , 0                                   factory_stock_b                 --  工場入庫振戻
        , 0                                   wear_decrease                   --  棚卸減耗増
        , 0                                   wear_increase                   --  棚卸減耗減
        , 0                                   selfbase_ship                   --  保管場所移動＿自拠点出庫
        , 0                                   selfbase_stock                  --  保管場所移動＿自拠点入庫
        , xirmt.inv_result                    inv_result                      --  棚卸結果
        , xirmt.inv_result_bad                inv_result_bad                  --  棚卸結果（不良品）
        , xirmt.inv_result  * -1  + xirmt.inv_result_bad  * -1
          + xirmt.month_begin_quantity  *  1
                                              inv_wear                        --  棚卸減耗
        , xirmt.month_begin_quantity          month_begin_quantity            --  月首棚卸高
      FROM    xxcoi_inv_rcp_monthly_tmp   xirmt
      WHERE NOT EXISTS( SELECT  1
                        FROM    xxcoi_inv_reception_sum   xirs
                        WHERE   xirs.organization_id        =   gn_f_organization_id
                        AND     xirs.practice_date          =   gv_f_inv_acct_period
                        AND     xirs.base_code              =   xirmt.base_code
                        AND     xirs.subinventory_code      =   xirmt.subinventory_code
                        AND     xirs.inventory_item_id      =   xirmt.inventory_item_id
                )
      ;
    -- <カーソル名>レコード型
    TYPE t_month_ttype IS TABLE OF invrcp1_qty_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    t_month_tab     t_month_ttype;
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
    --  初期化
    ln_set_cnt  :=  1;
    --
    lt_chk_inv.DELETE;
    lt_add_inv.DELETE;
    t_month_tab.DELETE;
    --
    --  データ取得（月末）
    IF (gv_param_exec_flag = cv_exec_1) THEN
      --  コンカレント起動時
      OPEN  invrcp1_qty_cur;
    ELSE
      -- 強制確定時
      OPEN  invrcp2_qty_cur;
    END IF;
    --
    <<set_invrcp_loop>>
    LOOP
      IF (gv_param_exec_flag = cv_exec_1) THEN
        FETCH invrcp1_qty_cur BULK COLLECT INTO t_month_tab LIMIT 50000;
      ELSE
        FETCH invrcp2_qty_cur BULK COLLECT INTO t_month_tab LIMIT 50000;
      END IF;
      --
      EXIT WHEN t_month_tab.COUNT = 0;
      -- カウント
      gn_target_cnt := gn_target_cnt + t_month_tab.COUNT;
      --
      <<chk_inv_ctl_loop>>
      FOR ln_cnt IN 1 .. t_month_tab.COUNT LOOP
        IF    t_month_tab(ln_cnt).sales_shipped             = 0
          AND t_month_tab(ln_cnt).sales_shipped_b           = 0
          AND t_month_tab(ln_cnt).return_goods              = 0
          AND t_month_tab(ln_cnt).return_goods_b            = 0
          AND t_month_tab(ln_cnt).warehouse_ship            = 0
          AND t_month_tab(ln_cnt).truck_ship                = 0
          AND t_month_tab(ln_cnt).others_ship               = 0
          AND t_month_tab(ln_cnt).warehouse_stock           = 0
          AND t_month_tab(ln_cnt).truck_stock               = 0
          AND t_month_tab(ln_cnt).others_stock              = 0
          AND t_month_tab(ln_cnt).change_stock              = 0
          AND t_month_tab(ln_cnt).change_ship               = 0
          AND t_month_tab(ln_cnt).goods_transfer_old        = 0
          AND t_month_tab(ln_cnt).goods_transfer_new        = 0
          AND t_month_tab(ln_cnt).sample_quantity           = 0
          AND t_month_tab(ln_cnt).sample_quantity_b         = 0
          AND t_month_tab(ln_cnt).customer_sample_ship      = 0
          AND t_month_tab(ln_cnt).customer_sample_ship_b    = 0
          AND t_month_tab(ln_cnt).customer_support_ss       = 0
          AND t_month_tab(ln_cnt).customer_support_ss_b     = 0
          AND t_month_tab(ln_cnt).ccm_sample_ship           = 0
          AND t_month_tab(ln_cnt).ccm_sample_ship_b         = 0
          AND t_month_tab(ln_cnt).vd_supplement_stock       = 0
          AND t_month_tab(ln_cnt).vd_supplement_ship        = 0
          AND t_month_tab(ln_cnt).inventory_change_in       = 0
          AND t_month_tab(ln_cnt).inventory_change_out      = 0
          AND t_month_tab(ln_cnt).factory_return            = 0
          AND t_month_tab(ln_cnt).factory_return_b          = 0
          AND t_month_tab(ln_cnt).factory_change            = 0
          AND t_month_tab(ln_cnt).factory_change_b          = 0
          AND t_month_tab(ln_cnt).removed_goods             = 0
          AND t_month_tab(ln_cnt).removed_goods_b           = 0
          AND t_month_tab(ln_cnt).factory_stock             = 0
          AND t_month_tab(ln_cnt).factory_stock_b           = 0
          AND t_month_tab(ln_cnt).wear_decrease             = 0
          AND t_month_tab(ln_cnt).wear_increase             = 0
          AND t_month_tab(ln_cnt).selfbase_ship             = 0
          AND t_month_tab(ln_cnt).selfbase_stock            = 0
          AND t_month_tab(ln_cnt).inv_result                = 0
          AND t_month_tab(ln_cnt).inv_result_bad            = 0
          AND t_month_tab(ln_cnt).month_begin_quantity      = 0
        THEN
          --  月首、受払、棚卸の全項目が０の場合データを作成しない
          gn_target_cnt :=  gn_target_cnt - 1;
        ELSE
          -- ===================================
          --  棚卸管理の存在チェック
          -- ===================================
          IF  (lt_chk_inv.EXISTS(t_month_tab(ln_cnt).subinventory_code) = FALSE) THEN
            --  未チェックの保管場所コードの場合
            BEGIN
              lt_chk_inv(t_month_tab(ln_cnt).subinventory_code).subinventory_code  :=  cv_yes;
              --
              SELECT  1
              INTO    ln_dummy
              FROM    xxcoi_inv_control     xic
              WHERE   xic.inventory_kbn       =   cv_inv_kbn_2
              AND     xic.inventory_date      >=  TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
              AND     xic.inventory_date      <   LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month)) + 1
              AND     xic.subinventory_code   =   t_month_tab(ln_cnt).subinventory_code
              AND     ROWNUM  = 1;
            EXCEPTION
              WHEN  NO_DATA_FOUND THEN
                lt_add_inv(ln_set_cnt).base_code          :=  t_month_tab(ln_cnt).base_code;
                lt_add_inv(ln_set_cnt).subinventory_code  :=  t_month_tab(ln_cnt).subinventory_code;
                lt_add_inv(ln_set_cnt).subinventory_type  :=  t_month_tab(ln_cnt).subinventory_type;
                ln_set_cnt  :=  ln_set_cnt  + 1;
            END;
          END IF;
          --
          -- ===================================
          --  月次棚卸作成
          -- ===================================
          INSERT INTO xxcoi_inv_reception_monthly(
              inv_seq                                                 --  01.棚卸SEQ
            , base_code                                               --  02.拠点コード
            , organization_id                                         --  03.組織ID
            , subinventory_code                                       --  04.保管場所
            , subinventory_type                                       --  05.保管場所区分
            , practice_month                                          --  06.年月
            , practice_date                                           --  07.年月日
            , inventory_kbn                                           --  08.棚卸区分
            , inventory_item_id                                       --  09.品目ID
            , operation_cost                                          --  10.営業原価
            , standard_cost                                           --  11.標準原価
            , sales_shipped                                           --  12.売上出庫
            , sales_shipped_b                                         --  13.売上出庫振戻
            , return_goods                                            --  14.返品
            , return_goods_b                                          --  15.返品振戻
            , warehouse_ship                                          --  16.倉庫へ返庫
            , truck_ship                                              --  17.営業車へ出庫
            , others_ship                                             --  18.入出庫＿その他出庫
            , warehouse_stock                                         --  19.倉庫より入庫
            , truck_stock                                             --  20.営業車より入庫
            , others_stock                                            --  21.入出庫＿その他入庫
            , change_stock                                            --  22.倉替入庫
            , change_ship                                             --  23.倉替出庫
            , goods_transfer_old                                      --  24.商品振替（旧商品）
            , goods_transfer_new                                      --  25.商品振替（新商品）
            , sample_quantity                                         --  26.見本出庫
            , sample_quantity_b                                       --  27.見本出庫振戻
            , customer_sample_ship                                    --  28.顧客見本出庫
            , customer_sample_ship_b                                  --  29.顧客見本出庫振戻
            , customer_support_ss                                     --  30.顧客協賛見本出庫
            , customer_support_ss_b                                   --  31.顧客協賛見本出庫振戻
            , ccm_sample_ship                                         --  32.顧客広告宣伝費A自社商品
            , ccm_sample_ship_b                                       --  33.顧客広告宣伝費A自社商品振戻
            , vd_supplement_stock                                     --  34.消化VD補充入庫
            , vd_supplement_ship                                      --  35.消化VD補充出庫
            , inventory_change_in                                     --  36.基準在庫変更入庫
            , inventory_change_out                                    --  37.基準在庫変更出庫
            , factory_return                                          --  38.工場返品
            , factory_return_b                                        --  39.工場返品振戻
            , factory_change                                          --  40.工場倉替
            , factory_change_b                                        --  41.工場倉替振戻
            , removed_goods                                           --  42.廃却
            , removed_goods_b                                         --  43.廃却振戻
            , factory_stock                                           --  44.工場入庫
            , factory_stock_b                                         --  45.工場入庫振戻
            , wear_decrease                                           --  46.棚卸減耗増
            , wear_increase                                           --  47.棚卸減耗減
            , selfbase_ship                                           --  48.保管場所移動＿自拠点出庫
            , selfbase_stock                                          --  49.保管場所移動＿自拠点入庫
            , inv_result                                              --  50.棚卸結果
            , inv_result_bad                                          --  51.棚卸結果（不良品）
            , inv_wear                                                --  52.棚卸減耗
            , month_begin_quantity                                    --  53.月首棚卸高
            , created_by                                              --  54.作成者
            , creation_date                                           --  55.作成日
            , last_updated_by                                         --  56.最終更新者
            , last_update_date                                        --  57.最終更新日
            , last_update_login                                       --  58.最終更新ログイン
            , request_id                                              --  59.要求ID
            , program_application_id                                  --  60.コンカレント・プログラム・アプリケーションID
            , program_id                                              --  61.コンカレント・プログラムID
            , program_update_date                                     --  62.プログラム更新日
          )VALUES(
              1                                                       --  01
            , t_month_tab(ln_cnt).base_code                           --  02
            , gn_f_organization_id                                    --  03
            , t_month_tab(ln_cnt).subinventory_code                   --  04
            , t_month_tab(ln_cnt).subinventory_type                   --  05
            , gv_f_inv_acct_period                                    --  06
            , gd_f_process_date                                       --  07
            , cv_inv_kbn_2                                            --  08
            , t_month_tab(ln_cnt).inventory_item_id                   --  09
            , t_month_tab(ln_cnt).operation_cost                      --  10
            , t_month_tab(ln_cnt).standard_cost                       --  11
            , t_month_tab(ln_cnt).sales_shipped                       --  12
            , t_month_tab(ln_cnt).sales_shipped_b                     --  13
            , t_month_tab(ln_cnt).return_goods                        --  14
            , t_month_tab(ln_cnt).return_goods_b                      --  15
            , t_month_tab(ln_cnt).warehouse_ship                      --  16
            , t_month_tab(ln_cnt).truck_ship                          --  17
            , t_month_tab(ln_cnt).others_ship                         --  18
            , t_month_tab(ln_cnt).warehouse_stock                     --  19
            , t_month_tab(ln_cnt).truck_stock                         --  20
            , t_month_tab(ln_cnt).others_stock                        --  21
            , t_month_tab(ln_cnt).change_stock                        --  22
            , t_month_tab(ln_cnt).change_ship                         --  23
            , t_month_tab(ln_cnt).goods_transfer_old                  --  24
            , t_month_tab(ln_cnt).goods_transfer_new                  --  25
            , t_month_tab(ln_cnt).sample_quantity                     --  26
            , t_month_tab(ln_cnt).sample_quantity_b                   --  27
            , t_month_tab(ln_cnt).customer_sample_ship                --  28
            , t_month_tab(ln_cnt).customer_sample_ship_b              --  29
            , t_month_tab(ln_cnt).customer_support_ss                 --  30
            , t_month_tab(ln_cnt).customer_support_ss_b               --  31
            , t_month_tab(ln_cnt).ccm_sample_ship                     --  32
            , t_month_tab(ln_cnt).ccm_sample_ship_b                   --  33
            , t_month_tab(ln_cnt).vd_supplement_stock                 --  34
            , t_month_tab(ln_cnt).vd_supplement_ship                  --  35
            , t_month_tab(ln_cnt).inventory_change_in                 --  36
            , t_month_tab(ln_cnt).inventory_change_out                --  37
            , t_month_tab(ln_cnt).factory_return                      --  38
            , t_month_tab(ln_cnt).factory_return_b                    --  39
            , t_month_tab(ln_cnt).factory_change                      --  40
            , t_month_tab(ln_cnt).factory_change_b                    --  41
            , t_month_tab(ln_cnt).removed_goods                       --  42
            , t_month_tab(ln_cnt).removed_goods_b                     --  43
            , t_month_tab(ln_cnt).factory_stock                       --  44
            , t_month_tab(ln_cnt).factory_stock_b                     --  45
            , t_month_tab(ln_cnt).wear_decrease                       --  46
            , t_month_tab(ln_cnt).wear_increase                       --  47
            , t_month_tab(ln_cnt).selfbase_ship                       --  48
            , t_month_tab(ln_cnt).selfbase_stock                      --  49
            , t_month_tab(ln_cnt).inv_result                          --  50
            , t_month_tab(ln_cnt).inv_result_bad                      --  51
            , t_month_tab(ln_cnt).inv_wear                            --  52
            , t_month_tab(ln_cnt).month_begin_quantity                --  53
            , cn_created_by                                           --  54
            , SYSDATE                                                 --  55
            , cn_last_updated_by                                      --  56
            , SYSDATE                                                 --  57
            , cn_last_update_login                                    --  58
            , cn_request_id                                           --  59
            , cn_program_application_id                               --  60
            , cn_program_id                                           --  61
            , SYSDATE                                                 --  62
          );
        END IF;
      END LOOP  chk_inv_ctl_loop;
      --
    END LOOP  set_invrcp_loop;
    --
    IF (gv_param_exec_flag = cv_exec_1) THEN
      --  コンカレント起動時
      CLOSE invrcp1_qty_cur;
    ELSE
      -- 強制確定時
      CLOSE invrcp2_qty_cur;
    END IF;
    -- ===================================
    --  棚卸データ作成
    -- ===================================
    IF (lt_add_inv.COUNT <> 0) AND (gv_param_exec_flag = cv_exec_3) THEN
      --  月次夜間強制確定時に、棚卸管理未登録データありの場合
      <<ins_inv_loop>>
      FOR ln_cnt IN 1 .. lt_add_inv.COUNT LOOP
        --  A-5をコール
        ins_inv_control(
            it_base_code            =>  lt_add_inv(ln_cnt).base_code              --  拠点
          , it_subinv_code          =>  lt_add_inv(ln_cnt).subinventory_code      --  保管場所
          , it_subinv_type          =>  lt_add_inv(ln_cnt).subinventory_type      --  保管場所区分
          , ov_errbuf               =>  lv_errbuf                                 --  エラーメッセージ
          , ov_retcode              =>  lv_retcode                                --  リターン・コード
          , ov_errmsg               =>  lv_errmsg                                 --  ユーザー・エラーメッセージ
        );
        -- 終了パラメータ判定
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP  ins_inv_loop;
    END IF;
    --  成功件数
    gn_normal_cnt :=  gn_target_cnt;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END ins_month_tran_data;
  --
-- == 2010/12/14 V1.17 Added END   ===============================================================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
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
    ln_cnt      NUMBER;         -- LOOPカウンタ
--
    -- *** ローカル・カーソル ***
    -- --------------------------
    --  対象拠点取得
    -- --------------------------
    CURSOR  acct_num_cur
    IS
      SELECT  hca.account_number            -- 拠点コード
      FROM    hz_cust_accounts      hca     -- 顧客マスタ
             ,xxcmm_cust_accounts   xca     -- 顧客追加情報
      WHERE   hca.cust_account_id       =   xca.customer_id
      AND     hca.customer_class_code   =   cv_cust_cls_1
      AND     hca.status                =   cv_status_a
      AND     xca.management_base_code  =   gv_param_base_code;
    --
    acct_num_rec    acct_num_cur%ROWTYPE;
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- ===================================
    --  1.起動パラメータログ出力
    -- ===================================
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name
                    ,iv_name         => cv_msg_xxcoi1_10233
                    ,iv_token_name1  => cv_token_10233_1
                    ,iv_token_value1 => gv_param_inventory_kbn
                    ,iv_token_name2  => cv_token_10233_2
                    ,iv_token_value2 => gv_param_base_code
                    ,iv_token_name3  => cv_token_10233_3
                    ,iv_token_value3 => gv_param_exec_flag
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- 空行を出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
    );
    --
    -- ===================================
    --  2.在庫組織コード取得
    -- ===================================
    gv_f_organization_code  :=  fnd_profile.value(cv_prf_name_orgcd);
    --
    IF (gv_f_organization_code IS NULL) THEN
      -- 在庫組織コード取得エラーメッセージ
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00005
                      ,iv_token_name1  => cv_token_00005_1
                      ,iv_token_value1 => cv_prf_name_orgcd
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  3.在庫組織ID取得
    -- ===================================
    gn_f_organization_id  :=  xxcoi_common_pkg.get_organization_id(gv_f_organization_code);
    --
    IF (gn_f_organization_id IS NULL) THEN
      -- 在庫組織ID取得エラーメッセージ
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00006
                      ,iv_token_name1  => cv_token_00006_1
                      ,iv_token_value1 => gv_f_organization_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  4.WHOカラム取得
    -- ===================================
    -- グローバル固定値の設定部で取得しています。
    --
    -- ===================================
    --  5.オープン在庫会計期間情報取得
    -- ===================================
    SELECT  MIN(TO_CHAR(oap.period_start_date, cv_month)) -- 最も古い会計年月
    INTO    gv_f_inv_acct_period
    FROM    org_acct_periods      oap                     -- 在庫会計期間テーブル
    WHERE   oap.organization_id   =   gn_f_organization_id
    AND     oap.open_flag         =   cv_yes;
    --
    -- ===================================
    --  6.業務処理日付取得
    -- ===================================
    gd_f_process_date   :=  xxccp_common_pkg2.get_process_date;
    --
    IF (gd_f_process_date IS NULL) THEN
      -- 業務日付の取得に失敗しました。
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_00011
                      );
      lv_errbuf   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    IF (TO_CHAR(gd_f_process_date, cv_month) <> gv_f_inv_acct_period) THEN
      -- 在庫会計年月と不一致の場合、会計年月の月末日を業務処理日付として設定
      gd_f_process_date :=  LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month));
    END IF;
    --
-- == 2009/08/20 V1.14 Modified START ===============================================================
--    IF (gv_param_inventory_kbn  = cv_inv_kbn_2) THEN     -- 2:月末
    IF ((gv_param_inventory_kbn  = cv_inv_kbn_2)
        AND
        (gv_param_exec_flag = cv_exec_1)
       )
    THEN
      -- 月末、かつ、コンカレント起動時
-- == 2009/08/20 V1.14 Modified END   ===============================================================
      -- ===================================
      --  7.取引ID取得（前回連携時）
      -- ===================================
      SELECT  xcc.transaction_id                      -- 取引ID
             ,xcc.last_cooperation_date               -- 最終連携日時
      INTO    gn_f_last_transaction_id                -- 処理済取引ID
             ,gd_f_last_cooperation_date              -- 処理日
      FROM    xxcoi_cooperation_control   xcc         -- データ連携制御テーブル
      WHERE   xcc.program_short_name  =   cv_pgsname_a09c;
      --
      -- ===================================
      --  8.最大取引ＩＤ取得（資材取引）
      -- ===================================
      BEGIN
        SELECT  MAX(mmt.transaction_id)
        INTO    gn_f_max_transaction_id
        FROM    mtl_material_transactions   mmt
        WHERE   mmt.organization_id   =   gn_f_organization_id
        AND     mmt.transaction_id   >=   gn_f_last_transaction_id;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 最大取引ID取得エラーメッセージ
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10127
                         );
          lv_errbuf   := lv_errmsg;
          --
          RAISE global_process_expt;
      END;
      --
    END IF;
    --
    -- ===================================
    --  9.処理対象拠点取得
    -- ===================================
    ln_cnt  :=  0;
    <<set_base_loop>>
    FOR acct_num_rec  IN  acct_num_cur LOOP
      -- パラメータ拠点が管理元拠点の場合、管理下の拠点全てを対象とする
      ln_cnt  :=  ln_cnt + 1;
      gt_f_account_number(ln_cnt)  :=  acct_num_rec.account_number;
    END LOOP set_base_loop;
    --
    IF (ln_cnt = 0) THEN
      -- 拠点が取得できない場合、管理元拠点ではないため入力拠点のみが対象
      gt_f_account_number(1)  :=  gv_param_base_code;
    END IF;
    --
  EXCEPTION
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
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_inventory_kbn  IN  VARCHAR2,     --  1.棚卸区分
    iv_base_code      IN  VARCHAR2,     --  2.拠点
    iv_exec_flag      IN  VARCHAR2,     --  3.起動フラグ
    ov_errbuf         OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
-- == 2009/08/20 V1.14 Deleted START ===============================================================
--    ln_main_end         NUMBER;
--    lv_base_code        VARCHAR2(4);
-- == 2009/08/20 V1.14 Deleted END   ===============================================================
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
-- == 2009/08/20 V1.14 Deleted START ===============================================================
--    invrcp_daily_rec    invrcp_daily_1_cur%ROWTYPE;
--    inv_result_rec      inv_result_1_cur%ROWTYPE;
--    daily_trans_rec     daily_trans_cur%ROWTYPE;
--    last_month_rec      last_month_cur%ROWTYPE;
-- == 2009/08/20 V1.14 Deleted END   ===============================================================
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
    --  0.グローバル値の設定
    -- ===============================
    -- グローバル変数の初期化
    gv_param_inventory_kbn  :=  iv_inventory_kbn;         -- 【起動パラメータ】棚卸区分
    gv_param_base_code      :=  iv_base_code;             -- 【起動パラメータ】拠点
    gv_param_exec_flag      :=  iv_exec_flag;             -- 【起動パラメータ】起動フラグ
    --
    FOR i IN 1 .. 38 LOOP
      gt_quantity(i)  :=  0;    -- 取引タイプ別数量
    END LOOP;
--
    -- ===============================
    --  A-1.初期処理
    -- ===============================
    init(
      ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
     ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    --
-- == 2009/08/20 V1.14 Modified START ===============================================================
--    <<main_loop>>   -- メインLOOP
--    FOR ln_main_cnt IN  1 .. gt_f_account_number.LAST LOOP
--      -- グローバル変数の初期化
--      gt_save_1_base_code     :=  NULL;
--      gt_save_1_subinv_code   :=  NULL;
--      --
--      gt_save_2_base_code     :=  NULL;
--      gt_save_2_subinv_code   :=  NULL;
--      --
--      gt_save_3_inv_seq       :=  NULL;
--      gt_save_3_base_code     :=  NULL;
--      gt_save_3_inv_code      :=  NULL;
--      gt_save_3_item_id       :=  NULL;
--      gt_save_3_inv_type      :=  NULL;
--      gt_save_3_inv_seq_sub   :=  NULL;
--      --
--      gn_data_cnt             :=  0;
--      gt_daily_data.DELETE;
--      gv_create_flag          :=  cv_off;
--      --
--      --
--      -- ===================================
--      --  A-3.作成済み月次在庫受払データ削除
--      -- ===================================
--      IF (gv_param_inventory_kbn  = cv_inv_kbn_2) THEN
--        -- 棚卸区分：２（月末）の場合、削除を実行
--        del_invrcp_monthly(
--          it_base_code      =>  gt_f_account_number(ln_main_cnt)    -- 対象拠点コード
--         ,ov_errbuf         =>  lv_errbuf                           -- エラー・メッセージ           --# 固定 #
--         ,ov_retcode        =>  lv_retcode                          -- リターン・コード             --# 固定 #
--         ,ov_errmsg         =>  lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
--        );
--        -- 終了パラメータ判定
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_process_expt;
--        END IF;
--      END IF;
--      --
--      -- ===========================================
--      --  A-2.月次在庫受払（日次）情報取得（CURSOR）
--      -- ===========================================
--      --
--      IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
--        -- 棚卸区分：１（月中）の場合
--        OPEN  invrcp_daily_1_cur(
--                iv_base_code        =>  gt_f_account_number(ln_main_cnt)                  -- 拠点コード
--              );
--      ELSE
--        -- 棚卸区分：２（月末）の場合
--        OPEN  invrcp_daily_2_cur(
--                iv_base_code        =>  gt_f_account_number(ln_main_cnt)                  -- 拠点コード
--             );
--      END IF;
--      --
--      <<daily_data_loop>>    -- 日次データ出力LOOP
--      LOOP
--        -- 日次データ出力終了判定
--        IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
--          FETCH invrcp_daily_1_cur  INTO  invrcp_daily_rec;
--          EXIT  daily_data_loop   WHEN  invrcp_daily_1_cur%NOTFOUND;
--          --
--        ELSE
--          FETCH invrcp_daily_2_cur  INTO  invrcp_daily_rec;
--          EXIT  daily_data_loop   WHEN  invrcp_daily_2_cur%NOTFOUND;
--          --
---- == 2009/07/21 V1.12 Added START ===============================================================
--          BEGIN
--            -- 棚卸管理情報を取得
--            SELECT   MAX(xic.inventory_seq)        inventory_seq
--                    ,MAX(xic.inventory_date)       inventory_date
--            INTO     invrcp_daily_rec.inventory_seq
--                    ,invrcp_daily_rec.inventory_date
--            FROM     xxcoi_inv_control           xic
--                    ,mtl_secondary_inventories   msi
--            WHERE    xic.inventory_kbn      =   gv_param_inventory_kbn
--            AND      xic.subinventory_code  =   invrcp_daily_rec.subinventory_code
--            AND      xic.inventory_date    >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
--            AND      xic.inventory_date    <=   LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month))
--            AND      xic.subinventory_code  =   msi.secondary_inventory_name
--            AND      msi.attribute7         =   invrcp_daily_rec.base_code
--            AND      msi.organization_id    =   gn_f_organization_id
--            GROUP BY  msi.attribute7
--                     ,xic.subinventory_code;
--          EXCEPTION
--            WHEN  NO_DATA_FOUND THEN
--              invrcp_daily_rec.inventory_seq  :=  NULL;
--              invrcp_daily_rec.inventory_date :=  NULL;
--          END;
---- == 2009/07/21 V1.12 Added END   ===============================================================
--        END IF;
--        --
--        -- ===================================
--        --  A-4.月次在庫受払出力（日次データ）
--        -- ===================================
--        ins_invrcp_daily(
--          ir_invrcp_daily   =>  invrcp_daily_rec  --  月次在庫受払データ
--         ,ov_errbuf         =>  lv_errbuf         --  エラー・メッセージ           --# 固定 #
--         ,ov_retcode        =>  lv_retcode        --  リターン・コード             --# 固定 #
--         ,ov_errmsg         =>  lv_errmsg         --  ユーザー・エラー・メッセージ --# 固定 #
--        );
--        -- 終了パラメータ判定
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_process_expt;
--        END IF;
--        --
--        -- ===================================
--        --  A-5.棚卸管理出力（日次データ）
--        -- ===================================
--        ins_inv_control(
--          ir_invrcp_daily   =>  invrcp_daily_rec  --  月次在庫受払データ
--         ,ov_errbuf         =>  lv_errbuf         --  エラー・メッセージ           --# 固定 #
--         ,ov_retcode        =>  lv_retcode        --  リターン・コード             --# 固定 #
--         ,ov_errmsg         =>  lv_errmsg         --  ユーザー・エラー・メッセージ --# 固定 #
--        );
--        --
--        -- 終了パラメータ判定
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_process_expt;
--        END IF;
--        --
--        -- キー項目を保持
--        gt_save_1_base_code   :=  invrcp_daily_rec.base_code;          -- 拠点
--        gt_save_1_subinv_code :=  invrcp_daily_rec.subinventory_code;  -- 保管場所
--        --
--      END LOOP daily_data_loop;
--      --
--      -- ----------------
--      --  CURSORクローズ
--      -- ----------------
--      IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
--        CLOSE invrcp_daily_1_cur;
--      ELSE
--        CLOSE invrcp_daily_2_cur;
--      END IF;
--      --
--      -- ===================================
--      --  A-6.棚卸結果情報抽出
--      -- ===================================
--      IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
--        -- 棚卸区分：１（月中）の場合
--        OPEN  inv_result_1_cur(
--                iv_base_code        =>  gt_f_account_number(ln_main_cnt)              -- 拠点コード
--              );
--      ELSE
--        -- 棚卸区分：２（月末）の場合
--        OPEN  inv_result_2_cur(
--                iv_base_code        =>  gt_f_account_number(ln_main_cnt)              -- 拠点コード
--             );
--      END IF;
--      --
--      <<inv_conseq_loop>>   -- 棚卸結果出力LOOP
--      LOOP
--        -- 棚卸結果出力終了判定
--        IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
--          FETCH inv_result_1_cur  INTO  inv_result_rec;
--          EXIT  inv_conseq_loop WHEN  inv_result_1_cur%NOTFOUND;
--        ELSE
--          FETCH inv_result_2_cur  INTO  inv_result_rec;
--          EXIT  inv_conseq_loop WHEN  inv_result_2_cur%NOTFOUND;
--        END IF;
--        --
--        -- =======================================
--        --  A-7.月次在庫受払出力（棚卸結果データ）
--        -- =======================================
--        ins_inv_result(
--          ir_inv_result     =>  inv_result_rec    --  棚卸結果情報
--         ,ov_errbuf         =>  lv_errbuf         --  エラー・メッセージ           --# 固定 #
--         ,ov_retcode        =>  lv_retcode        --  リターン・コード             --# 固定 #
--         ,ov_errmsg         =>  lv_errmsg         --  ユーザー・エラー・メッセージ --# 固定 #
--        );
--        -- 終了パラメータ判定
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_process_expt;
--        END IF;
--        --
--        -- =======================================
--        --  A-8.棚卸管理出力（棚卸結果データ）
--        -- =======================================
--        upd_inv_control(
--          ir_inv_result     =>  inv_result_rec    --  棚卸結果情報
--         ,ov_errbuf         =>  lv_errbuf         --  エラー・メッセージ           --# 固定 #
--         ,ov_retcode        =>  lv_retcode        --  リターン・コード             --# 固定 #
--         ,ov_errmsg         =>  lv_errmsg         --  ユーザー・エラー・メッセージ --# 固定 #
--        );
--        -- 終了パラメータ判定
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_process_expt;
--        END IF;
--        --
--        -- キー項目を保持
--        gt_save_2_base_code   :=  inv_result_rec.base_code;            -- 拠点
--        gt_save_2_subinv_code :=  inv_result_rec.subinventory_code;    -- 保管場所
--        --
--      END LOOP inv_conseq_loop;
--      --
--      -- ----------------
--      --  CURSORクローズ
--      -- ----------------
--      IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
--        CLOSE inv_result_1_cur;
--      ELSE
--        CLOSE inv_result_2_cur;
--      END IF;
--      --
--      -- A-9からA-11は、月末の場合のみ実行
--      IF (gv_param_inventory_kbn = cv_inv_kbn_2) THEN
--        --
--        -- 最大取引IDと処理済取引IDが不一致の場合、A-9, A-10, A-11 を実行
--        IF (gn_f_last_transaction_id <> gn_f_max_transaction_id) THEN
--          -- ================================================
--          --  A-9.当日取引データ取得（CURSOR:daily_trans_cur)
--          -- ================================================
--          OPEN  daily_trans_cur(
--                  iv_base_code        =>  gt_f_account_number(ln_main_cnt)              -- 拠点コード
--                );
--          <<the_day_output_loop>>   -- 当日取引出力LOOP
--          LOOP
--            FETCH daily_trans_cur INTO  daily_trans_rec;
--            --
--            -- ========================================
--            --  A-10.月次在庫受払出力（当日取引データ）
--            -- ========================================
--            ins_daily_data(
--              ir_daily_trans    =>  daily_trans_rec   --  当日取引データ
--             ,ov_errbuf         =>  lv_errbuf         --  エラー・メッセージ           --# 固定 #
--             ,ov_retcode        =>  lv_retcode        --  リターン・コード             --# 固定 #
--             ,ov_errmsg         =>  lv_errmsg         --  ユーザー・エラー・メッセージ --# 固定 #
--            );
--            -- 終了パラメータ判定
--            IF (lv_retcode = cv_status_error) THEN
--              RAISE global_process_expt;
--            END IF;
--            --
--            -- ========================================
--            --  A-11.棚卸管理出力（当日取引データ）
--            -- ========================================
--            ins_daily_invcntl(
--              ir_daily_trans    =>  daily_trans_rec   --  当日取引データ
--             ,ov_errbuf         =>  lv_errbuf         --  エラー・メッセージ           --# 固定 #
--             ,ov_retcode        =>  lv_retcode        --  リターン・コード             --# 固定 #
--             ,ov_errmsg         =>  lv_errmsg         --  ユーザー・エラー・メッセージ --# 固定 #
--            );
--            -- 終了パラメータ判定
--            IF (lv_retcode = cv_status_error) THEN
--              RAISE global_process_expt;
--            END IF;
--            -- 
--            EXIT  the_day_output_loop WHEN  daily_trans_cur%NOTFOUND;
--            --
--            -- キー項目を保持
--            gt_save_3_base_code   :=  daily_trans_rec.base_code;            -- 拠点コード
--            gt_save_3_inv_code    :=  daily_trans_rec.subinventory_code;    -- 保管場所コード
--            gt_save_3_item_id     :=  daily_trans_rec.inventory_item_id;    -- 品目ID
--            gt_save_3_inv_type    :=  daily_trans_rec.inventory_type;       -- 保管場所タイプ
--            gt_save_3_inv_seq_sub :=  daily_trans_rec.inventory_seq;        -- キー項目単位の前データの棚卸SEQ
--            --
--          END LOOP the_day_output_loop;
--          --
--          -- ----------------
--          --  CURSORクローズ
--          -- ----------------
--          CLOSE daily_trans_cur;
--        END IF;
--      END IF;
--      --
--      -- ===================================
--      --  A-12.前月棚卸結果抽出
--      -- ===================================
--      OPEN  last_month_cur(
--              iv_base_code        =>  gt_f_account_number(ln_main_cnt)              -- 拠点コード
--            );
--      --
--      <<month_balance_loop>>    -- 月首残高LOOP
--      LOOP
--        FETCH last_month_cur  INTO  last_month_rec;
--        EXIT  month_balance_loop  WHEN  last_month_cur%NOTFOUND;
--        --
---- == 2009/07/21 V1.12 Modified START ===============================================================
----        IF (last_month_rec.last_month_inv_seq IS NOT NULL) THEN
----          -- ========================================
----          --  A-13.月首残高出力
----          -- ========================================
----          ins_month_balance(
----            ir_month_balance  =>  last_month_rec    --  月首残高
----           ,ov_errbuf         =>  lv_errbuf         --  エラー・メッセージ           --# 固定 #
----           ,ov_retcode        =>  lv_retcode        --  リターン・コード             --# 固定 #
----           ,ov_errmsg         =>  lv_errmsg         --  ユーザー・エラー・メッセージ --# 固定 #
----          );
----          -- 終了パラメータ判定
----          IF (lv_retcode = cv_status_error) THEN
----            RAISE global_process_expt;
----          END IF;
----          --
----        END IF;
----
--        -- ========================================
--        --  A-13.月首残高出力
--        -- ========================================
--        ins_month_balance(
--          ir_month_balance  =>  last_month_rec    --  月首残高
--         ,ov_errbuf         =>  lv_errbuf         --  エラー・メッセージ           --# 固定 #
--         ,ov_retcode        =>  lv_retcode        --  リターン・コード             --# 固定 #
--         ,ov_errmsg         =>  lv_errmsg         --  ユーザー・エラー・メッセージ --# 固定 #
--        );
--        -- 終了パラメータ判定
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_process_expt;
--        END IF;
---- == 2009/07/21 V1.12 Modified END   ===============================================================
--      END LOOP month_balance_loop;
--      -- ----------------
--      --  CURSORクローズ
--      -- ----------------
--      CLOSE last_month_cur;
--      --
--    END LOOP main_loop;
--    --
--    -- ===============================
--    --  A-15.後処理
--    -- ===============================
--    close_process(
--      ov_errbuf         =>  lv_errbuf         --  エラー・メッセージ           --# 固定 #
--     ,ov_retcode        =>  lv_retcode        --  リターン・コード             --# 固定 #
--     ,ov_errmsg         =>  lv_errmsg         --  ユーザー・エラー・メッセージ --# 固定 #
--    );
--    -- 終了パラメータ判定
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
--
    <<main_loop>>   -- メインLOOP
    FOR ln_main_cnt IN  1 .. gt_f_account_number.LAST LOOP
      --
      -- ===================================
      --  A-3.作成済み月次在庫受払データ削除
      -- ===================================
      IF ((gv_param_inventory_kbn  = cv_inv_kbn_2)
          AND
          (gv_param_exec_flag <> cv_exec_3)
         )
      THEN
        -- 棚卸区分：２（月末）で、起動フラグ：３（夜間強制確定（日次情報取込））以外の場合、削除を実行
        del_invrcp_monthly(
          it_base_code      =>  gt_f_account_number(ln_main_cnt)    -- 対象拠点コード
         ,ov_errbuf         =>  lv_errbuf                           -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        =>  lv_retcode                          -- リターン・コード             --# 固定 #
         ,ov_errmsg         =>  lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 終了パラメータ判定
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
      --
      --
-- == 2010/12/14 V1.17 Modified START ===============================================================
--      IF (gv_param_exec_flag = cv_exec_1) THEN
      IF (gv_param_inventory_kbn = cv_inv_kbn_1) THEN
        -- 棚卸区分：1（月中）
-- == 2010/12/14 V1.17 Modified END   ===============================================================
        --
        -- ===================================
        --  A-4.日次から月次作成
        -- ===================================
        ins_invrcp_daily(
          it_base_code      =>  gt_f_account_number(ln_main_cnt)    -- 対象拠点コード
         ,ov_errbuf         =>  lv_errbuf                           -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        =>  lv_retcode                          -- リターン・コード             --# 固定 #
         ,ov_errmsg         =>  lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 終了パラメータ判定
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================
        --  A-7.棚卸情報の反映
        -- ===================================
        ins_inv_result(
          it_base_code      =>  gt_f_account_number(ln_main_cnt)    -- 対象拠点コード
         ,ov_errbuf         =>  lv_errbuf                           -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        =>  lv_retcode                          -- リターン・コード             --# 固定 #
         ,ov_errmsg         =>  lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 終了パラメータ判定
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        IF ((gv_param_inventory_kbn = cv_inv_kbn_2)
            AND
            (gn_f_last_transaction_id <> gn_f_max_transaction_id)
           )
        THEN
          -- 棚卸区分：２（月末）かつ、日次データ未作成の資材取引が存在する場合
          --
          -- ===================================
          --  A-10.資材の取込
          -- ===================================
          ins_daily_data(
            it_base_code      =>  gt_f_account_number(ln_main_cnt)    -- 対象拠点コード
           ,ov_errbuf         =>  lv_errbuf                           -- エラー・メッセージ           --# 固定 #
           ,ov_retcode        =>  lv_retcode                          -- リターン・コード             --# 固定 #
           ,ov_errmsg         =>  lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 終了パラメータ判定
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
        --
        -- ===================================
        --  A-13.月首棚卸数の反映
        -- ===================================
        ins_month_balance(
          it_base_code      =>  gt_f_account_number(ln_main_cnt)    -- 対象拠点コード
         ,ov_errbuf         =>  lv_errbuf                           -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        =>  lv_retcode                          -- リターン・コード             --# 固定 #
         ,ov_errmsg         =>  lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 終了パラメータ判定
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
-- == 2010/12/14 V1.17 Modified START ===============================================================
--      ELSIF (gv_param_exec_flag = cv_exec_2) THEN
--        -- 起動フラグ：２（夜間強制確定（棚卸情報取込））
--        --
--        -- ===================================
--        --  A-7.棚卸情報の反映
--        -- ===================================
--        ins_inv_result(
--          it_base_code      =>  gt_f_account_number(ln_main_cnt)    -- 対象拠点コード
--         ,ov_errbuf         =>  lv_errbuf                           -- エラー・メッセージ           --# 固定 #
--         ,ov_retcode        =>  lv_retcode                          -- リターン・コード             --# 固定 #
--         ,ov_errmsg         =>  lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
--        );
--        -- 終了パラメータ判定
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_process_expt;
--        END IF;
--        --
--        -- ===================================
--        --  A-13.月首棚卸数の反映
--        -- ===================================
--        ins_month_balance(
--          it_base_code      =>  gt_f_account_number(ln_main_cnt)    -- 対象拠点コード
--         ,ov_errbuf         =>  lv_errbuf                           -- エラー・メッセージ           --# 固定 #
--         ,ov_retcode        =>  lv_retcode                          -- リターン・コード             --# 固定 #
--         ,ov_errmsg         =>  lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
--        );
--        -- 終了パラメータ判定
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_process_expt;
--        END IF;
--        --
--      ELSE
--        -- 起動フラグ：３（夜間強制確定（日次情報取込））
--        -- ===================================
--        --  A-4.日次から月次作成
--        -- ===================================
--        ins_invrcp_daily(
--          it_base_code      =>  gt_f_account_number(ln_main_cnt)    -- 対象拠点コード
--         ,ov_errbuf         =>  lv_errbuf                           -- エラー・メッセージ           --# 固定 #
--         ,ov_retcode        =>  lv_retcode                          -- リターン・コード             --# 固定 #
--         ,ov_errmsg         =>  lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
--        );
--        -- 終了パラメータ判定
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_process_expt;
--        END IF;
--        --
--      END IF;
      ELSE
        -- 棚卸区分：2（月末）
        --
        -- ===================================
        --  A-15, A-16.月首在庫、棚卸確定処理
        -- ===================================
        IF ((gv_param_exec_flag = cv_exec_2) OR (gv_param_exec_flag = cv_exec_1)) THEN
          --  （夜間）棚卸情報取込、または、コンカレント起動
          ins_inv_data(
            it_base_code      =>  gt_f_account_number(ln_main_cnt)    -- 対象拠点コード
           ,ov_errbuf         =>  lv_errbuf                           -- エラー・メッセージ           --# 固定 #
           ,ov_retcode        =>  lv_retcode                          -- リターン・コード             --# 固定 #
           ,ov_errmsg         =>  lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 終了パラメータ判定
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        -- ===================================
        --  A-17, A-18.受払情報確定処理
        -- ===================================
        IF ((gv_param_exec_flag = cv_exec_3) OR (gv_param_exec_flag = cv_exec_1)) THEN
          --  （夜間）強制確定、または、コンカレント起動時
          ins_month_tran_data(
            it_base_code      =>  gt_f_account_number(ln_main_cnt)    -- 対象拠点コード
           ,ov_errbuf         =>  lv_errbuf                           -- エラー・メッセージ           --# 固定 #
           ,ov_retcode        =>  lv_retcode                          -- リターン・コード             --# 固定 #
           ,ov_errmsg         =>  lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 終了パラメータ判定
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        -- ===================================
        --  A-10.資材の取込
        -- ===================================
        IF ((gv_param_exec_flag = cv_exec_1)
            AND
            (gn_f_last_transaction_id <> gn_f_max_transaction_id)
           )
        THEN
          -- コンカレント起動かつ、日次データ未作成の資材取引が存在する場合
          --
          ins_daily_data(
            it_base_code      =>  gt_f_account_number(ln_main_cnt)    -- 対象拠点コード
           ,ov_errbuf         =>  lv_errbuf                           -- エラー・メッセージ           --# 固定 #
           ,ov_retcode        =>  lv_retcode                          -- リターン・コード             --# 固定 #
           ,ov_errmsg         =>  lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 終了パラメータ判定
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
      END IF;
-- == 2010/12/14 V1.17 Modified END   ===============================================================
    END LOOP main_loop;
-- == 2009/08/20 V1.14 Deleted END   ===============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --
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
    errbuf              OUT VARCHAR2,       -- エラー・メッセージ  --# 固定 #
    retcode             OUT VARCHAR2,       -- リターン・コード    --# 固定 #
    iv_inventory_kbn    IN  VARCHAR2,       -- 【必須】棚卸区分（1:月中、2:月末）
    iv_base_code        IN  VARCHAR2,       -- 【任意】拠点
    iv_exec_flag        IN  VARCHAR2        -- 【必須】起動フラグ（1:コンカレント起動、2:夜間強制確定（棚卸情報取込）、3:夜間強制確定（日次情報取込））
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
        iv_inventory_kbn    =>  iv_inventory_kbn    -- 棚卸区分
       ,iv_base_code        =>  iv_base_code        -- 拠点
       ,iv_exec_flag        =>  iv_exec_flag        -- 起動フラグ
       ,ov_errbuf           =>  lv_errbuf           -- エラー・メッセージ             --# 固定 #
       ,ov_retcode          =>  lv_retcode          -- リターン・コード               --# 固定 #
       ,ov_errmsg           =>  lv_errmsg           -- ユーザー・エラー・メッセージ   --# 固定 #
    );
--
    IF (lv_errbuf <> cv_status_normal) THEN
      --エラー出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 空行を出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
      gn_error_cnt := gn_error_cnt + 1;
    END IF;
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
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
    -- 空行を出力
    fnd_file.put_line(
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
    fnd_file.put_line(
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
END XXCOI006A03C;
/
