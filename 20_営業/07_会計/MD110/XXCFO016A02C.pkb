CREATE OR REPLACE PACKAGE BODY XXCFO016A02C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO016A02C(body)
 * Description     : 発注書データ出力処理
 * MD.050          : MD050_CFO_016_A02_発注書データ出力処理
 * MD.070          : MD050_CFO_016_A02_発注書データ出力処理
 * Version         : 1.7
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init            P          入力パラメータ値ログ出力処理                 (A-1)
 *  get_profile_lookup_val P   初期処理                                     (A-2)
 *  get_attache_info P         添付情報取得処理                             (A-4)
 *  edit_attache_info P        添付情報編集処理                             (A-5)
 *  get_customer_info P        顧客情報取得処理                             (A-6)
 *  get_un_info     P          機種情報取得処理                             (A-7)
 *  insert_po_status_mng P     ステータス管理テーブルデータ登録             (A-8)
 *  insert_tmp_standard_data_po P 発注書データ出力ワークテーブルデータ登録  (A-9)
 *  insert_csv_outs_temp P     CSVワークテーブルデータ登録                  (A-10)
 *  out_put_file    P          OUTファイル出力処理                          (A-11)
 *  submain         P          メイン処理プロシージャ
 *  main            P          コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-11-12    1.0  SCS 山口 優   初回作成
 *  2009-02-06    1.1  SCS 嵐田勇人  [障害CFO_001]事業所アドオンマスタの有効日付チェックを追加
 *  2009-02-09    1.2  SCS 嵐田勇人  [障害CFO_002]出力桁数対応
 *  2009-03-16    1.3  SCS 嵐田勇人  [障害T1_0050]エラーログ対応
 *  2009-03-17    1.4  SCS 嵐田勇人  [障害T1_0051]共通関数エラー時対応
 *  2009-03-23    1.5  SCS 開原拓也  [障害T1_0059]機種コードの変更対応
 *  2009-11-25    1.6  SCS 寺内真紀  [障害E_本稼動_00063]顧客情報取得エラー対応
 *  2009-12-24    1.7  SCS 寺内真紀  [障害E_本稼動_00592]納品場所変更対応
  ************************************************************************/
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
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
  --===============================================================
  -- グローバル定数
  --===============================================================
  gv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCFO016A02C';   -- パッケージ名
  gv_msg_kbn_cfo           CONSTANT VARCHAR2(5)   := 'XXCFO';
  gv_flag_y                CONSTANT VARCHAR2(1)   := 'Y';              -- フラグ（Y）
  gv_flag_n                CONSTANT VARCHAR2(1)   := 'N';              -- フラグ（N）
  gv_approved              CONSTANT VARCHAR2(10)  := 'APPROVED';       -- 承認済
  gv_standard              CONSTANT VARCHAR2(10)  := 'STANDARD';       -- 標準発注
  gv_reissue_flag_0        CONSTANT VARCHAR2(1)   := '0';              -- 新規
  gv_reissue_flag_1        CONSTANT VARCHAR2(1)   := '1';              -- 再発行：再発行
  gv_reissue_flag_2        CONSTANT VARCHAR2(1)   := '2';              -- 再発行：照会
  gv_lookup_code_100       CONSTANT VARCHAR2(3)   := '100';            -- 設置先_顧客コード=
  gn_view_appli_id_201     CONSTANT NUMBER        := 201;              -- ビューアプリケーションID
  gv_judge_code_10         CONSTANT VARCHAR2(2)   := '10';             -- 自販機
  gv_judge_code_20         CONSTANT VARCHAR2(2)   := '20';             -- 固定資産
  gv_judge_code_30         CONSTANT VARCHAR2(2)   := '30';             -- 名刺
  gv_entity_name           CONSTANT VARCHAR2(10)  := 'REQ_LINES';      -- 購買依頼明細
  gv_equal                 CONSTANT VARCHAR2(1)   := '=';              -- イコール
  gv_file_type_log         CONSTANT VARCHAR2(10)  := 'LOG';            -- ログ出力
  gv_format_date_ymdhms    CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
                                                                       -- 日付フォーマット（年月日時分秒）
                                                                                -- エラーメッセージ出力用参照タイプコード
  gt_lookup_code_000A00002 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00002';
                                                                                -- 「発注作成日From」
  gt_lookup_code_000A00003 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00003';
                                                                                -- 「発注作成日To」
  gt_lookup_code_000A00004 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00004';
                                                                                -- 「発注承認日From」
  gt_lookup_code_000A00005 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00005';
                                                                                -- 「発注承認日To」
  gt_lookup_code_016A02001 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO016A02001';
                                                                                -- 「OUTファイル出力処理」
  gt_lookup_code_000A00006 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00006';
                                                                                -- 「発注情報」
--
  -- メッセージ番号
  gv_msg_cfo_00001   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001'; -- プロファイル取得エラーメッセージ
  gv_msg_cfo_00004   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004'; -- 警告エラーメッセージ
  gv_msg_cfo_00009   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00009'; -- 共通関数エラーメッセージ
  gv_msg_cfo_00010   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00010'; -- 添付情報取得エラーメッセージ
  gv_msg_cfo_00011   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00011'; -- 顧客情報取得エラーメッセージ
  gv_msg_cfo_00012   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00012'; -- 機種情報取得エラーメッセージ
  gv_msg_cfo_00013   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00013'; -- 添付情報文字列検索エラーメッセージ
  gv_msg_cfo_00014   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00014'; -- 添付情報文字列取得限界エラーメッセージ
  gv_msg_cfo_00019   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019'; -- テーブルロックエラーメッセージ
  gv_msg_cfo_00025   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00025'; -- データ削除エラーメッセージ
  gv_msg_cfo_00033   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00033'; -- コンカレントパラメータ値大小チェックエラーメッセージ
  gv_msg_cfo_00035   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00035'; -- データ作成エラーメッセージエラーメッセージ
  gv_msg_cfo_00036   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00036'; -- システムエラーメッセージ
--
  -- トークン
  gv_tkn_prof            CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- プロファイル名
  gv_tkn_param_name_from CONSTANT VARCHAR2(15) := 'PARAM_NAME_FROM';  -- 大小チェックFrom 文字用
  gv_tkn_param_name_to   CONSTANT VARCHAR2(15) := 'PARAM_NAME_TO';    -- 大小チェックTo 文字用
  gv_tkn_param_val_from  CONSTANT VARCHAR2(15) := 'PARAM_VAL_FROM';   -- 大小チェックFrom 値用
  gv_tkn_param_val_to    CONSTANT VARCHAR2(15) := 'PARAM_VAL_TO';     -- 大小チェックTo 値用
  gv_tkn_lookup_type     CONSTANT VARCHAR2(15) := 'LOOKUP_TYPE';      -- ルックアップタイプ
  gv_tkn_lookup_code     CONSTANT VARCHAR2(15) := 'LOOKUP_CODE';      -- ルックアップコード
  gv_tkn_table           CONSTANT VARCHAR2(15) := 'TABLE';            -- テーブル名
  gv_tkn_pk1_value       CONSTANT VARCHAR2(15) := 'PK1_VALUE';        -- 購買依頼明細ID
  gv_tkn_requisition_no  CONSTANT VARCHAR2(15) := 'REQUISITION_NO';   -- 購買依頼番号
  gv_tkn_po_num          CONSTANT VARCHAR2(15) := 'PO_NUM';           -- 発注番号
  gv_tkn_search_string   CONSTANT VARCHAR2(15) := 'SEARCH_STRING';    -- 検索対象文字列
  gv_tkn_account_number  CONSTANT VARCHAR2(15) := 'ACCOUNT_NUMBER';   -- 顧客番号
  gv_tkn_un_number_id    CONSTANT VARCHAR2(15) := 'UN_NUMBER_ID';     -- 機種番号ID
  gv_tkn_errmsg          CONSTANT VARCHAR2(15) := 'ERRMSG';           -- SQLERRM対応
  gv_tkn_func_name       CONSTANT VARCHAR2(15) := 'FUNC_NAME';        -- 処理名
--
  --プロファイル
  gv_set_of_bks_id   CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID'; -- 会計帳簿ID
  gv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- 組織ID
  gv_user_id         CONSTANT VARCHAR2(30) := 'USER_ID';          -- ユーザーID
  gv_conc_request_id CONSTANT VARCHAR2(30) := 'CONC_REQUEST_ID';  -- 要求ID
--
  gv_lookup_type1    CONSTANT VARCHAR2(100) := 'XXCFO1_PO_REPORT_OUT_FLAG';          -- 標準発注書出力済フラグ
  gv_lookup_type2    CONSTANT VARCHAR2(100) := 'AUTHORIZATION STATUS';               -- 承認ステータス
  gv_lookup_type3    CONSTANT VARCHAR2(100) := 'XXCFO1_SEARCH_LONG_TEXT';            -- 長い文書検索文字列
  gv_lookup_type4    CONSTANT VARCHAR2(100) := 'XXCFO1_PO_DATA_OUT_HEAD_ITEM';       -- 発注書データ出力ヘッダ項目
--
  --===============================================================
  -- グローバル変数
  --===============================================================
  gn_set_of_bks_id             NUMBER;                                     -- 会計帳簿ID
  gn_org_id                    NUMBER;                                     -- 組織ID
  gn_conc_request_id           NUMBER;                                     -- 要求ID
  gt_search_long_text          fnd_lookup_values.meaning%TYPE;             -- 長い文書検索文字
  gt_account_number            hz_cust_accounts.account_number%TYPE;       -- 顧客コード
  gt_standard_po_output        fnd_lookup_values.description%TYPE;         -- 標準発注書出力済フラグ名
  gt_long_text                 fnd_documents_long_text.long_text%TYPE;     -- 長い文書
  gt_authorization_status_name fnd_lookup_values.meaning%TYPE;             -- 承認ステータスの取得
  gt_party_name                hz_parties.party_name%TYPE;                 -- 顧客名
  gt_state                     hz_locations.state%TYPE;                    -- 都道府県
  gt_city                      hz_locations.city%TYPE;                     -- 市区町村
  gt_address1                  hz_locations.address1%TYPE;                 -- 住所１
  gt_address2                  hz_locations.address2%TYPE;                 -- 住所２
  gt_un_number                 po_un_numbers_tl.un_number%TYPE;            -- 機種番号
  gn_po_num_in_count           NUMBER;                                     -- ステータス管理テーブルへの発注番号登録件数
  gn_special_info_cnt          NUMBER;                                     -- 特別情報項目数
--
  --===============================================================
  -- グローバルテーブルタイプ
  --===============================================================
  TYPE g_special_info_ttype     IS TABLE OF fnd_documents_long_text.long_text%TYPE INDEX BY PLS_INTEGER;
  TYPE g_po_num_ttype           IS TABLE OF xxcfo_po_status_mng.po_num%TYPE        INDEX BY PLS_INTEGER;
  TYPE g_org_id_ttype           IS TABLE OF xxcfo_po_status_mng.org_id%TYPE        INDEX BY PLS_INTEGER;
--
  --===============================================================
  -- グローバルテーブル
  --===============================================================
  gt_special_info_item      g_special_info_ttype;
  gt_po_num                 g_po_num_ttype;
  gt_org_id                 g_org_id_ttype;
--
  --===============================================================
  -- グローバルテーブル
  --===============================================================
--
  --===============================================================
  -- グローバルカーソル
  --===============================================================
--
  CURSOR po_data_cur(
    iv_po_dept_code            IN VARCHAR2       -- 発注作成部署
   ,in_po_agent_code           IN NUMBER         -- 発注作成者
   ,iv_vender_code             IN VARCHAR2       -- 仕入先
   ,iv_po_num                  IN VARCHAR2       -- 発注番号
   ,id_po_creation_date_from   IN DATE           -- 発注作成日From
   ,id_po_creation_date_to     IN DATE           -- 発注作成日To
   ,id_po_approved_date_from   IN DATE           -- 発注承認日From
   ,id_po_approved_date_to     IN DATE           -- 発注承認日To
   ,iv_reissue_flag            IN VARCHAR2       -- 再発行フラグ
  )
  IS
    SELECT pha.segment1                           po_num                     -- 発注番号
          ,pla.vendor_product_num                 vendor_product_num         -- 仕入先品目
          ,pla.unit_meas_lookup_code              unit_meas_lookup_code      -- 単位
          ,pla.unit_price                         unit_price                 -- 単価
          ,pda.quantity_ordered                   quantity_ordered           -- 発注数量
          ,pla.unit_price * pda.quantity_ordered  amount                     -- 金額
          ,plla.promised_date                     promised_date              -- 納期
          ,mcb.attribute1                         attache_judge_code         -- 添付情報判定コード
          ,d_xla.location_name                    po_location_name           -- 発注担当者_所属部署名
          ,d_xla.zip                              po_zip                     -- 発注担当者_郵便番号
          ,d_xla.address_line1                    po_address_line1           -- 発注担当者_住所
          ,d_xla.phone                            po_phone                   -- 発注担当者_電話番号
          ,d_xla.fax                              po_fax                     -- 発注担当者_FAX
--MOD_Ver.1.7_2009/12/24_START----------------------------------------------------------------------------
--          ,l_xla.location_short_name              location_short_name        -- 納入先事業所
          ,l_xla.location_name                    location_name              -- 納入先事業所
--MOD_Ver.1.7_2009/12/24_END------------------------------------------------------------------------------
          ,l_hl.location_code                     location_code              -- 納入先事業所コード
          ,pvsa.phone                             vendor_phone               -- 仕入先電話番号
          ,pvsa.fax                               vendor_fax                 -- 仕入先FAX番号
          ,pvsa.pay_on_code                       pay_on_code                -- 自己請求-支払日
          ,pvsa.attribute1                        vendor_name                -- 仕入先名
          ,pr.requisition_num                     requisition_num            -- 購買依頼番号
          ,pr.requisition_line_id                 requisition_line_id        -- 購買依頼明細ID
--MOD_Ver.1.5_2009/03/23_START------------------------------------------------------------------------------
--          ,pr.un_number_id                        un_number_id               -- 機種ID
          ,pla.un_number_id                       un_number_id               -- 機種ID
--MOD_Ver.1.5_2009/03/23_END--------------------------------------------------------------------------------
          ,pr.location_short_name                 apply_location_short_name  -- 申請拠点
          ,pr.location_code                       apply_location_code        -- 申請拠点コード
          ,pha.revision_num                       revision_num               -- 改訂番号
          ,pla.line_num                           line_num                   -- 発注明細番号
          ,plla.need_by_date                      need_by_date               -- 希望入手日
          ,pvsa.vendor_site_code                  vendor_site_code           -- 仕入先サイトコード
          ,pha.currency_code                      currency_code              -- 通貨コード
          ,papf1.full_name                        full_name                  -- 購買担当者
          ,mcb.segment1                           category_name              -- カテゴリ名
          ,pla.item_description                   item_description           -- 摘要
          ,plla.shipment_num                      shipment_num               -- 納入明細番号
          ,pla.quantity                           quantity                   -- 発注数量
          ,l_xla.address_line1                    address_line1              -- 納品場所住所
          ,pha.org_id                             org_id                     -- 組織ID
          ,pha.creation_date                      creation_date              -- 発注作成日
      FROM po_headers_all          pha,                  -- 発注ヘッダテーブル
           po_lines_all            pla,                  -- 発注明細テーブル
           po_line_locations_all   plla,                 -- 発注納入明細テーブル
           po_distributions_all    pda,                  -- 発注搬送明細テーブル
           po_agents               pa,                   -- 購買担当マスタ
           per_all_people_f        papf1,                -- 従業員マスタ
           mtl_categories_b        mcb,                  -- 品目カテゴリテーブル
           hr_locations            d_hl,                 -- 事業所マスタ（所属部門用）
           xxcmn_locations_all     d_xla,                -- 事業所アドオンマスタ（所属部門用）
           hr_locations            l_hl,                 -- 事業所マスタ（納入先事業所用）
           xxcmn_locations_all     l_xla,                -- 事業所アドオンマスタ（納入先事業所用）
           po_vendors              pv,                   -- 仕入先マスタ
           po_vendor_sites_all     pvsa,                 -- 仕入先サイトマスタ
           (SELECT prha.segment1                requisition_num                     -- 購買依頼番号
                  ,prha.org_id                  org_id                              -- 組織ID
                  ,prla.requisition_line_id     requisition_line_id                 -- 購買依頼明細ID
                  ,prla.line_location_id        line_location_id                    -- 納入明細ID
--DEL_Ver.1.5_2009/03/23_START------------------------------------------------------------------------------
--                  ,prla.un_number_id            un_number_id                        -- 機種ID
--DEL_Ver.1.5_2009/03/23_END--------------------------------------------------------------------------------
                  ,prda.distribution_id         distribution_id                     -- 購買依頼搬送明細ID
                  ,xla.location_short_name      location_short_name                 -- 申請拠点
                  ,hl.location_code             location_code                       -- 申請拠点コード
              FROM po_requisition_headers_all   prha,          -- 購買依頼ヘッダテーブル
                   po_requisition_lines_all     prla,          -- 購買依頼明細テーブル
                   po_req_distributions_all     prda,          -- 購買依頼搬送明細テーブル
                   per_all_people_f             papf2,         -- 従業員マスタ
                   hr_locations                 hl,            -- 事業所マスタ
                   xxcmn_locations_all          xla            -- 事業所アドオンマスタ
             WHERE prha.org_id                  = gn_org_id
               AND prha.requisition_header_id   = prla.requisition_header_id
               AND prha.org_id                  = prla.org_id
               AND prla.requisition_line_id     = prda.requisition_line_id
               AND prla.org_id                  = prda.org_id
               AND prda.set_of_books_id         = gn_set_of_bks_id
               AND papf2.current_employee_flag  = gv_flag_y
               AND papf2.person_id              = prla.to_person_id
               AND papf2.attribute28            = hl.location_code
               AND hl.location_id               = xla.location_id
               AND TRUNC( SYSDATE ) BETWEEN TRUNC( xla.start_date_active )
                                        AND TRUNC( NVL( xla.end_date_active, SYSDATE ) )
               AND (   prla.cancel_flag = gv_flag_n
                    OR prla.cancel_flag IS NULL
                   )
           ) pr   -- 発注依頼取得
     WHERE pha.org_id               = gn_org_id
       AND pha.authorization_status = gv_approved
       AND pha.type_lookup_code     = gv_standard
       AND (   pha.cancel_flag = gv_flag_n
            OR pha.cancel_flag IS NULL
           )
       AND pha.po_header_id         = pla.po_header_id
       AND pha.org_id               = pla.org_id
       AND pla.po_header_id         = plla.po_header_id
       AND pla.po_line_id           = plla.po_line_id
       AND pla.org_id               = plla.org_id
       AND (   plla.cancel_flag = gv_flag_n
            OR plla.cancel_flag IS NULL
           )
       AND plla.ship_to_location_id    =  l_hl.location_id
       AND plla.po_header_id           =  pda.po_header_id
       AND plla.po_line_id             =  pda.po_line_id
       AND plla.line_location_id       =  pda.line_location_id
       AND plla.org_id                 =  pda.org_id
       AND pda.org_id                  =  gn_org_id
       AND pda.line_location_id        =  pr.line_location_id(+)
       AND pda.req_distribution_id     =  pr.distribution_id(+)
       AND pda.org_id                  =  pr.org_id(+)
       AND l_hl.location_id            =  l_xla.location_id
       AND TRUNC( SYSDATE ) BETWEEN TRUNC( l_xla.start_date_active )
                                AND TRUNC( NVL( l_xla.end_date_active, SYSDATE ) )
       AND pha.agent_id                =  pa.agent_id
       AND pa.agent_id                 =  papf1.person_id
       AND papf1.current_employee_flag =  gv_flag_y
       AND pla.category_id             =  mcb.category_id
       AND papf1.attribute28           =  d_hl.location_code
       AND d_hl.location_id            =  d_xla.location_id
       AND TRUNC( SYSDATE ) BETWEEN TRUNC( d_xla.start_date_active )
                                AND TRUNC( NVL( d_xla.end_date_active, SYSDATE ) )
       AND pv.set_of_books_id          =  gn_set_of_bks_id
       AND pv.vendor_id                =  pvsa.vendor_id
       AND pvsa.org_id                 =  pha.org_id
       AND pvsa.vendor_site_id         =  pha.vendor_site_id
       AND pvsa.vendor_id              =  pha.vendor_id
       AND pvsa.purchasing_site_flag   =  gv_flag_y
       AND papf1.attribute28           =  iv_po_dept_code
       AND papf1.person_id             =  NVL(in_po_agent_code, papf1.person_id)
       AND pv.segment1                 =  NVL(iv_vender_code, pv.segment1)
       AND pha.segment1                =  NVL(iv_po_num, pha.segment1)
       AND pha.creation_date           >= NVL(TRUNC(id_po_creation_date_from), pha.creation_date)
       AND pha.creation_date           <  NVL(TRUNC(id_po_creation_date_to),   pha.creation_date) + 1
       AND pha.approved_date           >= NVL(TRUNC(id_po_approved_date_from), pha.approved_date)
       AND pha.approved_date           <  NVL(TRUNC(id_po_approved_date_to),   pha.approved_date) + 1
       AND (
            (    iv_reissue_flag = gv_reissue_flag_0
             AND NOT EXISTS ( SELECT 'X'
                                FROM xxcfo_po_status_mng    xpsm      -- 発注書出力ステータス管理テーブル
                               WHERE pha.segment1 = xpsm.po_num
                                 AND pha.org_id   = xpsm.org_id
                            )
            )
           OR
            (    iv_reissue_flag IN (gv_reissue_flag_1, gv_reissue_flag_2)
             AND EXISTS ( SELECT 'X'
                            FROM xxcfo_po_status_mng xpsm
                           WHERE pha.segment1 = xpsm.po_num
                             AND pha.org_id   = xpsm.org_id
                        )
            )
           )
     ORDER BY pha.segment1 ASC
             ,pha.org_id   ASC
     FOR UPDATE OF pha.segment1
                  ,pla.line_num
                  ,plla.shipment_num
                  ,pda.quantity_ordered
                  ,pa.agent_id
                  ,papf1.full_name
                  ,mcb.attribute1
                  ,d_hl.location_id
                  ,d_xla.location_name
                  ,l_hl.location_code
                  ,l_xla.address_line1
                  ,pv.vendor_id
                  ,pvsa.phone
                  NOWAIT;
--
  --===============================================================
  -- グローバルレコード型変数
  --===============================================================
  g_xxcfo_po_data_rec    po_data_cur%ROWTYPE;
--
  --===============================================================
  -- グローバル例外
  --===============================================================
  lock_expt             EXCEPTION;      -- ロック(ビジー)エラー
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 入力パラメータ値ログ出力処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_po_dept_code            IN         VARCHAR2,     --   発注作成部署
    iv_po_agent_code           IN         VARCHAR2,     --   発注作成者
    iv_vender_code             IN         VARCHAR2,     --   仕入先
    iv_po_num                  IN         VARCHAR2,     --   発注番号
    iv_po_creation_date_from   IN         VARCHAR2,     --   発注作成日From
    iv_po_creation_date_to     IN         VARCHAR2,     --   発注作成日To
    iv_po_approved_date_from   IN         VARCHAR2,     --   発注承認日From
    iv_po_approved_date_to     IN         VARCHAR2,     --   発注承認日To
    iv_reissue_flag            IN         VARCHAR2,     --   再発行フラグ
    ov_errbuf                  OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                  OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    xxcfr_common_pkg.put_log_param(
       iv_which        => gv_file_type_log             -- ログ出力
      ,iv_conc_param1  => iv_po_dept_code              -- 発注作成部署
      ,iv_conc_param2  => iv_po_agent_code             -- 発注作成者
      ,iv_conc_param3  => iv_vender_code               -- 仕入先
      ,iv_conc_param4  => iv_po_num                    -- 発注番号
      ,iv_conc_param5  => iv_po_creation_date_from     -- 発注作成日From
      ,iv_conc_param6  => iv_po_creation_date_to       -- 発注作成日To
      ,iv_conc_param7  => iv_po_approved_date_from     -- 発注承認日From
      ,iv_conc_param8  => iv_po_approved_date_to       -- 発注承認日To
      ,iv_conc_param9  => iv_reissue_flag              -- 再発行フラグ
      ,ov_errbuf       => lv_errbuf                    -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode                   -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);                  -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** 共通関数エラー発生時 ***
    WHEN global_api_expt THEN
      ov_errbuf := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_lookup_val
   * Description      : 初期処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_lookup_val(
    iv_po_creation_date_from IN         VARCHAR2,   -- 発注作成日From
    iv_po_creation_date_to   IN         VARCHAR2,   -- 発注作成日To
    iv_po_approved_date_from IN         VARCHAR2,   -- 発注承認日From
    iv_po_approved_date_to   IN         VARCHAR2,   -- 発注承認日To
    iv_reissue_flag          IN         VARCHAR2,   -- 再発行フラグ
    ov_errbuf                OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_lookup_val'; -- プログラム名
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
    -- プロファイルから会計帳簿ID取得
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE(gv_set_of_bks_id));
--
    -- プロファイルから組織ID取得
    gn_org_id := TO_NUMBER(FND_PROFILE.VALUE(gv_org_id));
--
    -- プロファイルから要求ID取得
    gn_conc_request_id := TO_NUMBER(FND_PROFILE.VALUE(gv_conc_request_id));
--
    -- 発注作成日チェック
    IF (  iv_po_creation_date_from IS NOT NULL
      AND iv_po_creation_date_to IS NOT NULL
      AND iv_po_creation_date_from > iv_po_creation_date_to )
    THEN
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo               -- アプリケーション短縮名：XXCFO
                                                     ,gv_msg_cfo_00033             -- 大小チェックエラー
                                                     ,gv_tkn_param_name_from       -- トークン'PARAM_NAME_FROM'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        gv_msg_kbn_cfo
                                                       ,gt_lookup_code_000A00002
                                                      )                            -- 「発注作成日From」
                                                     ,gv_tkn_param_name_to         -- トークン'PARAM_NAME_TO'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        gv_msg_kbn_cfo
                                                       ,gt_lookup_code_000A00003
                                                      )                            -- 「発注作成日To」
                                                     ,gv_tkn_param_val_from        -- トークン'PARAM_VAL_FROM'
                                                     ,iv_po_creation_date_from     -- 発注作成日From
                                                     ,gv_tkn_param_val_to          -- トークン'PARAM_VAL_TO'
                                                     ,iv_po_creation_date_to       -- 発注作成日To
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
--
    -- 発注承認日チェック
    IF (  iv_po_approved_date_from IS NOT NULL
      AND iv_po_approved_date_to IS NOT NULL
      AND iv_po_approved_date_from > iv_po_approved_date_to )
    THEN
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo               -- アプリケーション短縮名：XXCFO
                                                     ,gv_msg_cfo_00033             -- 大小チェックエラー
                                                     ,gv_tkn_param_name_from       -- トークン'PARAM_NAME_FROM'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        gv_msg_kbn_cfo
                                                       ,gt_lookup_code_000A00004
                                                      )                            -- 「発注承認日From」
                                                     ,gv_tkn_param_name_to         -- トークン'PARAM_NAME_TO'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        gv_msg_kbn_cfo
                                                       ,gt_lookup_code_000A00005
                                                      )                            -- 「発注承認日To」
                                                     ,gv_tkn_param_val_from        -- トークン'PARAM_VAL_FROM'
                                                     ,iv_po_approved_date_from     -- 発注承認日From
                                                     ,gv_tkn_param_val_to          -- トークン'PARAM_VAL_TO'
                                                     ,iv_po_approved_date_to       -- 発注承認日To
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
--
    -- 標準発注書出力済フラグ名の取得
    SELECT flv.description            description
      INTO gt_standard_po_output
      FROM fnd_lookup_values      flv
     WHERE flv.lookup_type            = gv_lookup_type1
       AND flv.language               = USERENV('LANG')
       AND flv.enabled_flag           = gv_flag_y
       AND (   flv.start_date_active IS NULL
            OR flv.start_date_active <= TRUNC( SYSDATE ))
       AND (   flv.end_date_active   IS NULL
            OR flv.end_date_active   >= TRUNC( SYSDATE ))
       AND flv.lookup_code            = iv_reissue_flag;
--
    -- 承認ステータスの取得
    SELECT flv.meaning            meaning
      INTO gt_authorization_status_name
      FROM fnd_lookup_values      flv
     WHERE flv.view_application_id   = gn_view_appli_id_201
       AND flv.lookup_type           = gv_lookup_type2
       AND flv.language              = USERENV('LANG')
       AND flv.enabled_flag          = gv_flag_y
       AND (   flv.start_date_active IS NULL
            OR flv.start_date_active <= TRUNC( SYSDATE ))
       AND (   flv.end_date_active   IS NULL
            OR flv.end_date_active   >= TRUNC( SYSDATE ))
       AND flv.lookup_code           = gv_approved;
--
    -- 長い文書検索文字の取得
    SELECT flv.meaning            meaning
      INTO gt_search_long_text
      FROM fnd_lookup_values      flv
     WHERE flv.lookup_type            = gv_lookup_type3
       AND flv.language               = USERENV('LANG')
       AND flv.enabled_flag           = gv_flag_y
       AND (   flv.start_date_active IS NULL
            OR flv.start_date_active <= TRUNC( SYSDATE ))
       AND (   flv.end_date_active   IS NULL
           OR flv.end_date_active    >= TRUNC( SYSDATE ))
       AND flv.lookup_code            = gv_lookup_code_100;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_profile_lookup_val;
--
  /**********************************************************************************
   * Procedure Name   : get_attache_info
   * Description      : 添付情報取得処理 (A-4)
   ***********************************************************************************/
  PROCEDURE get_attache_info(
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_attache_info'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    SELECT fdlt.long_text          long_text   -- 長い文書
      INTO gt_long_text
      FROM fnd_document_entities        fde,   -- 添付実体テーブル
           fnd_attached_documents       fad,   -- 添付文書関連テーブル
           fnd_documents_tl             fdt,   -- 言語別添付テーブル
           fnd_documents_long_text      fdlt   -- 添付長い文書テーブル
     WHERE fde.entity_name  = gv_entity_name
       AND fde.entity_name  = fad.entity_name
       AND fad.document_id  = fdt.document_id
       AND fdt.language     = USERENV('LANG')
       AND fdt.media_id     = fdlt.media_id
       AND fad.pk1_value    = TO_CHAR(g_xxcfo_po_data_rec.requisition_line_id);
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg  := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo                          -- 'XXCFO'
                                                      ,gv_msg_cfo_00010                        -- 添付情報取得エラー
                                                      ,gv_tkn_pk1_value                        -- トークン'PK1_VALUE'
                                                      ,g_xxcfo_po_data_rec.requisition_line_id -- 購買依頼明細ID
                                                      ,gv_tkn_requisition_no                   -- トークン'REQUISITION_NO'
                                                      ,g_xxcfo_po_data_rec.requisition_num     -- 購買依頼番号
                                                      ,gv_tkn_po_num                           -- トークン'PO_NUM'
                                                      ,g_xxcfo_po_data_rec.po_num              -- 発注番号
                                                     )
                            ,1
                            ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_attache_info;
--
  /**********************************************************************************
   * Procedure Name   : edit_attache_info
   * Description      : 添付情報編集処理 (A-5)
   ***********************************************************************************/
  PROCEDURE edit_attache_info(
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_attache_info'; -- プログラム名
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
    lv_long_text       fnd_documents_long_text.long_text%TYPE;   -- 長い文書の一時変数
    ln_cnt             NUMBER;
    ln_len             NUMBER;
    ln_chr10           NUMBER;
    lv_char            fnd_documents_long_text.long_text%TYPE;
    ln_char_len        NUMBER;
    ln_compartmental   NUMBER;
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 添付情報項目値検索取得
    -- 自販機の場合
    IF (g_xxcfo_po_data_rec.attache_judge_code = gv_judge_code_10) THEN
      gt_account_number := xxcfo_common_pkg.get_special_info_item(
                                              gt_long_text                   -- 長い文書
                                             ,gt_search_long_text);          -- 検索対象文字列（設置先_顧客コード=）
--
      IF (gt_account_number IS NULL) THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo                      -- アプリケーション短縮名：XXCFO
                                                       ,gv_msg_cfo_00013                    -- 添付情報文字列検索エラー
                                                       ,gv_tkn_search_string                -- トークン'SEARCH_STRING'
                                                       ,gt_search_long_text                 -- 検索対象文字列
                                                       ,gv_tkn_requisition_no               -- トークン'REQUISITION_NO'
                                                       ,g_xxcfo_po_data_rec.requisition_num -- 購買依頼明細番号
                                                       ,gv_tkn_po_num                       -- トークン'PO_NUM'
                                                       ,g_xxcfo_po_data_rec.po_num          -- 発注番号
                                                      )
                             ,1
                             ,5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      END IF;
--
    END IF;
--
    -- 特別情報項目取得処理
    lv_long_text := gt_long_text;
    FOR ln_cnt IN 1..100 LOOP
      -- 長い文書の長さ
      ln_len   := LENGTHB(lv_long_text);
      -- 長い文書の改行コード位置
      ln_chr10 := INSTRB(lv_long_text,CHR(10));
--
      IF (ln_chr10 != 0) THEN
        -- 文字列
        lv_char := SUBSTRB(lv_long_text, 1, ln_chr10 - 1);
--
      ELSE
        -- 文字列
        lv_char := lv_long_text;
--
      END IF;
--
      -- 文字列の長さ
      ln_char_len := LENGTHB(lv_char);
      -- 区切り位置
      ln_compartmental := INSTRB(lv_char, gv_equal);
      -- 特別情報項目取得
      gt_special_info_item(ln_cnt) := SUBSTRB(lv_char, ln_compartmental + 1, ln_char_len - ln_compartmental);
--
      -- 特別情報項目数
      gn_special_info_cnt := gn_special_info_cnt + 1;
--
      -- 残文字列
      lv_long_text := SUBSTRB(lv_long_text, ln_chr10 + 1, ln_len - ln_chr10);
--
      IF (ln_chr10 = 0) THEN
        EXIT;
      END IF;
--
    END LOOP;
--
    -- 特別情報項目が100件以上取得できる場合 = 改行コードが長い文書に残っている
    IF ( ln_chr10 != 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo     -- アプリケーション短縮名：XXCFO
                                                     ,gv_msg_cfo_00014   -- 添付情報文字列取得限界エラー
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END edit_attache_info;
--
  /**********************************************************************************
   * Procedure Name   : get_customer_info
   * Description      : 顧客情報取得処理 (A-6)
   ***********************************************************************************/
  PROCEDURE get_customer_info(
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_customer_info'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    SELECT hp.party_name      party_name        -- 顧客名
          ,hl.state           state             -- 都道府県
          ,hl.city            city              -- 市区町村
          ,hl.address1        address1          -- 住所１
          ,hl.address2        address2          -- 住所２
      INTO gt_party_name
          ,gt_state
          ,gt_city
          ,gt_address1
          ,gt_address2
      FROM hz_parties           hp,     -- パーティマスタ
           hz_party_sites       hps,    -- パーティサイトマスタ
           hz_cust_accounts     hca,    -- 顧客マスタ
           hz_locations         hl      -- 顧客事業所マスタ
---- == 2009/11/25 V1.6 Added START =================================
          ,hz_cust_acct_sites_all hcasa -- 顧客サイトマスタ
---- == 2009/11/25 V1.6 Added END ===================================
     WHERE hp.party_id        = hca.party_id
       AND hca.account_number = gt_account_number
       AND hp.party_id        = hps.party_id
---- == 2009/11/25 V1.6 Added START =================================
       AND hca.cust_account_id  = hcasa.cust_account_id
       AND hcasa.org_id       = gn_org_id
       AND hps.party_site_id  = hcasa.party_site_id
---- == 2009/11/25 V1.6 Added END ===================================
       AND hl.location_id     = hps.location_id;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo                      -- 'XXCFO'
                                                     ,gv_msg_cfo_00011                    -- 顧客情報取得エラー
                                                     ,gv_tkn_account_number               -- トークン'ACCOUNT_NUMBER'
                                                     ,gt_account_number                   -- 顧客番号
                                                     ,gv_tkn_requisition_no               -- トークン'REQUISITION_NO'
                                                     ,g_xxcfo_po_data_rec.requisition_num -- 購買依頼番号
                                                     ,gv_tkn_po_num                       -- トークン'PO_NUM'
                                                     ,g_xxcfo_po_data_rec.po_num          -- 発注番号
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_customer_info;
--
  /**********************************************************************************
   * Procedure Name   : get_un_info
   * Description      : 機種情報取得処理 (A-7)
   ***********************************************************************************/
  PROCEDURE get_un_info(
    ov_errbuf      OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_un_info'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    SELECT punt.un_number    un_number   -- 機種番号
      INTO gt_un_number
      FROM po_un_numbers_tl     punt     -- 機種マスタ
     WHERE punt.language     = USERENV('LANG')
       AND punt.un_number_id = g_xxcfo_po_data_rec.un_number_id;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo                      -- 'XXCFO'
                                                     ,gv_msg_cfo_00012                    -- 機種情報取得エラー
                                                     ,gv_tkn_un_number_id                 -- トークン'UN_NUMBER_ID'
                                                     ,g_xxcfo_po_data_rec.un_number_id    -- 機種番号ID
                                                     ,gv_tkn_requisition_no               -- トークン'REQUISITION_NO'
                                                     ,g_xxcfo_po_data_rec.requisition_num -- 購買依頼番号
                                                     ,gv_tkn_po_num                       -- トークン'PO_NUM'
                                                     ,g_xxcfo_po_data_rec.po_num          -- 発注番号
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_un_info;
--
  /**********************************************************************************
   * Procedure Name   : insert_po_status_mng
   * Description      : ステータス管理テーブルデータ登録 (A-8)
   ***********************************************************************************/
  PROCEDURE insert_po_status_mng(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_po_status_mng'; -- プログラム名
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
    cv_table CONSTANT VARCHAR2(100) := 'XXCFO_PO_STATUS_MNG'; -- ステータス管理テーブル
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
    -- =====================================================
    --  ステータス管理テーブルデータ登録 (A-8)
    -- =====================================================
    INSERT INTO xxcfo_po_status_mng ( 
       po_num
      ,org_id
      ,created_by
      ,created_date
      ,last_updated_by
      ,last_updated_date
      ,last_update_login 
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    )
    VALUES ( 
       g_xxcfo_po_data_rec.po_num
      ,gn_org_id
      ,cn_created_by
      ,cd_creation_date
      ,cn_last_updated_by
      ,cd_last_update_date
      ,cn_last_update_login
      ,gn_conc_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,cd_program_update_date
    );
--
    IF (SQL%ROWCOUNT = 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo       -- 'XXCFO'
                                                     ,gv_msg_cfo_00035     -- データ作成エラー
                                                     ,gv_tkn_table         -- トークン'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                           -- ステータス管理テーブル
                                                     ,gv_tkn_errmsg        -- トークン'ERRMSG'
                                                     ,SQLERRM              -- SQLエラーメッセージ
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_po_status_mng;
--
  /**********************************************************************************
   * Procedure Name   : insert_tmp_standard_data_po
   * Description      : 発注書データ出力ワークテーブルデータ登録 (A-9)
   ***********************************************************************************/
  PROCEDURE insert_tmp_standard_data_po(
    ov_errbuf     OUT NOCOPY VARCHAR2,        --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,        --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)        --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_tmp_standard_data_po'; -- プログラム名
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
    cv_table   CONSTANT VARCHAR2(100) := 'XXCFO_TMP_STANDARD_DATA_PO'; -- 発注書データ出力ワークテーブル
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
    -- =====================================================
    --  発注書データ出力ワークテーブルデータ登録 (A-9)
    -- =====================================================
    INSERT INTO xxcfo_tmp_standard_data_po ( 
       po_num                               -- 発注番号
      ,revision_num                         -- 改訂番号
      ,authorization_status_name            -- 承認ステータス
      ,po_creation_date                     -- 発注作成日時
      ,vendor_name                          -- 仕入先
      ,vendor_site_code                     -- 仕入先サイトコード
      ,currency_code                        -- 通貨コード
      ,full_name                            -- 購買担当
      ,line_num                             -- 発注明細番号
      ,item_category_name                   -- 品目カテゴリ
      ,item_description                     -- 摘要
      ,quantity_ordered                     -- 発注数量
      ,unit_meas_lookup_code                -- 単位
      ,unit_price                           -- 価格
      ,amount                               -- 金額
      ,vendor_product_num                   -- 仕入先品目
      ,requisition_num                      -- 購買依頼番号
      ,apply_location_code                  -- 申請拠点コード
      ,apply_location_name                  -- 申請拠点名
      ,shipment_num                         -- 納入明細番号
      ,deliver_location_code                -- 納品場所コード
      ,deliver_location_name                -- 納品場所名
      ,promised_date                        -- 納期
      ,need_by_date                         -- 希望入手日
      ,deliver_address                      -- 納品場所住所
      ,standard_po_output                   -- 標準発注出力済
      ,special_info_item1
      ,special_info_item2
      ,special_info_item3
      ,special_info_item4
      ,special_info_item5
      ,special_info_item6
      ,special_info_item7
      ,special_info_item8
      ,special_info_item9
      ,special_info_item10
      ,special_info_item11
      ,special_info_item12
      ,special_info_item13
      ,special_info_item14
      ,special_info_item15
      ,special_info_item16
      ,special_info_item17
      ,special_info_item18
      ,special_info_item19
      ,special_info_item20
      ,special_info_item21
      ,special_info_item22
      ,special_info_item23
      ,special_info_item24
      ,special_info_item25
      ,special_info_item26
      ,special_info_item27
      ,special_info_item28
      ,special_info_item29
      ,special_info_item30
      ,special_info_item31
      ,special_info_item32
      ,special_info_item33
      ,special_info_item34
      ,special_info_item35
      ,special_info_item36
      ,special_info_item37
      ,special_info_item38
      ,special_info_item39
      ,special_info_item40
      ,special_info_item41
      ,special_info_item42
      ,special_info_item43
      ,special_info_item44
      ,special_info_item45
      ,special_info_item46
      ,special_info_item47
      ,special_info_item48
      ,special_info_item49
      ,special_info_item50
      ,special_info_item51
      ,special_info_item52
      ,special_info_item53
      ,special_info_item54
      ,special_info_item55
      ,special_info_item56
      ,special_info_item57
      ,special_info_item58
      ,special_info_item59
      ,special_info_item60
      ,special_info_item61
      ,special_info_item62
      ,special_info_item63
      ,special_info_item64
      ,special_info_item65
      ,special_info_item66
      ,special_info_item67
      ,special_info_item68
      ,special_info_item69
      ,special_info_item70
      ,special_info_item71
      ,special_info_item72
      ,special_info_item73
      ,special_info_item74
      ,special_info_item75
      ,special_info_item76
      ,special_info_item77
      ,special_info_item78
      ,special_info_item79
      ,special_info_item80
      ,special_info_item81
      ,special_info_item82
      ,special_info_item83
      ,special_info_item84
      ,special_info_item85
      ,special_info_item86
      ,special_info_item87
      ,special_info_item88
      ,special_info_item89
      ,special_info_item90
      ,special_info_item91
      ,special_info_item92
      ,special_info_item93
      ,special_info_item94
      ,special_info_item95
      ,special_info_item96
      ,special_info_item97
      ,special_info_item98
      ,special_info_item99
      ,special_info_item100
      ,org_id
      ,created_by
      ,created_date
      ,last_updated_by
      ,last_updated_date
      ,last_update_login 
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    )
    VALUES ( 
       g_xxcfo_po_data_rec.po_num                                                  -- 発注番号
      ,g_xxcfo_po_data_rec.revision_num                                            -- 改訂番号
      ,gt_authorization_status_name                                                -- 承認ステータス
      ,g_xxcfo_po_data_rec.creation_date                                           -- 発注作成日時
      ,g_xxcfo_po_data_rec.vendor_name                                             -- 仕入先
      ,g_xxcfo_po_data_rec.vendor_site_code                                        -- 仕入先サイトコード
      ,g_xxcfo_po_data_rec.currency_code                                           -- 通貨コード
      ,g_xxcfo_po_data_rec.full_name                                               -- 購買担当
      ,g_xxcfo_po_data_rec.line_num                                                -- 発注明細番号
      ,SUBSTRB( g_xxcfo_po_data_rec.category_name ,1 ,240 )                        -- 品目カテゴリ
      ,g_xxcfo_po_data_rec.item_description                                        -- 摘要
      ,g_xxcfo_po_data_rec.quantity_ordered                                        -- 発注数量
      ,g_xxcfo_po_data_rec.unit_meas_lookup_code                                   -- 単位
      ,g_xxcfo_po_data_rec.unit_price                                              -- 価格
      ,g_xxcfo_po_data_rec.amount                                                  -- 金額
      ,DECODE(g_xxcfo_po_data_rec.attache_judge_code, gv_judge_code_10, gt_un_number
                                                  , g_xxcfo_po_data_rec.vendor_product_num)    -- 仕入先品目
      ,g_xxcfo_po_data_rec.requisition_num                                         -- 購買依頼番号
      ,g_xxcfo_po_data_rec.apply_location_code                                     -- 申請拠点コード
      ,g_xxcfo_po_data_rec.apply_location_short_name                               -- 申請拠点名
      ,g_xxcfo_po_data_rec.shipment_num                                            -- 納入明細番号
      ,DECODE(g_xxcfo_po_data_rec.attache_judge_code, gv_judge_code_10, gt_account_number      -- 納品場所コード
                                                  , g_xxcfo_po_data_rec.location_code)
      ,DECODE(g_xxcfo_po_data_rec.attache_judge_code, gv_judge_code_10
                                                  , SUBSTRB( gt_party_name ,1 , 240 )          -- 納品場所名
--MOD_Ver.1.7_2009/12/24_START----------------------------------------------------------------------------
--                                                  , g_xxcfo_po_data_rec.location_short_name)
                                                  , g_xxcfo_po_data_rec.location_name)
--MOD_Ver.1.7_2009/12/24_END------------------------------------------------------------------------------
      ,g_xxcfo_po_data_rec.promised_date                                           -- 納期
      ,g_xxcfo_po_data_rec.need_by_date                                            -- 希望入手日
      ,DECODE(g_xxcfo_po_data_rec.attache_judge_code, gv_judge_code_10, 
                                                SUBSTRB(  gt_state                 -- 納品場所住所
                                                       || gt_city
                                                       || gt_address1
                                                       || gt_address2
                                                        ,1
                                                        ,240
                                                       )
                                                        , g_xxcfo_po_data_rec.address_line1)
      ,gt_standard_po_output                                               -- 標準発注出力済
      ,CASE WHEN 1   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(1) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 2   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(2) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 3   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(3) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 4   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(4) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 5   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(5) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 6   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(6) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 7   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(7) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 8   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(8) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 9   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(9) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 10  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(10) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 11  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(11) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 12  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(12) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 13  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(13) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 14  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(14) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 15  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(15) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 16  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(16) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 17  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(17) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 18  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(18) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 19  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(19) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 20  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(20) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 21  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(21) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 22  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(22) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 23  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(23) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 24  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(24) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 25  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(25) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 26  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(26) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 27  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(27) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 28  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(28) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 29  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(29) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 30  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(30) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 31  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(31) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 32  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(32) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 33  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(33) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 34  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(34) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 35  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(35) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 36  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(36) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 37  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(37) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 38  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(38) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 39  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(39) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 40  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(40) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 41  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(41) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 42  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(42) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 43  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(43) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 44  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(44) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 45  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(45) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 46  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(46) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 47  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(47) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 48  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(48) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 49  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(49) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 50  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(50) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 51  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(51) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 52  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(52) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 53  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(53) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 54  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(54) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 55  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(55) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 56  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(56) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 57  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(57) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 58  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(58) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 59  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(59) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 60  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(60) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 61  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(61) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 62  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(62) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 63  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(63) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 64  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(64) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 65  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(65) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 66  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(66) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 67  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(67) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 68  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(68) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 69  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(69) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 70  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(70) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 71  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(71) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 72  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(72) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 73  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(73) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 74  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(74) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 75  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(75) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 76  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(76) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 77  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(77) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 78  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(78) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 79  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(79) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 80  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(80) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 81  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(81) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 82  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(82) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 83  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(83) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 84  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(84) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 85  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(85) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 86  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(86) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 87  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(87) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 88  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(88) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 89  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(89) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 90  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(90) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 91  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(91) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 92  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(92) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 93  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(93) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 94  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(94) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 95  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(95) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 96  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(96) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 97  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(97) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 98  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(98) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 99  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(99) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 100 <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(100) ,1 ,240 ) ELSE NULL END
      ,gn_org_id
      ,cn_created_by
      ,cd_creation_date
      ,cn_last_updated_by
      ,cd_last_update_date
      ,cn_last_update_login
      ,gn_conc_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,cd_program_update_date
    );
--
    IF (SQL%ROWCOUNT = 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo       -- 'XXCFO'
                                                     ,gv_msg_cfo_00035     -- データ挿入エラー
                                                     ,gv_tkn_table         -- トークン'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                           -- ステータス管理テーブル
                                                     ,gv_tkn_errmsg        -- トークン'ERRMSG'
                                                     ,SQLERRM              -- SQLエラーメッセージ
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_tmp_standard_data_po;
--
  /**********************************************************************************
   * Procedure Name   : insert_csv_outs_temp
   * Description      : CSVワークテーブルデータ登録 (A-10)
   ***********************************************************************************/
  PROCEDURE insert_csv_outs_temp(
    ov_errbuf     OUT NOCOPY VARCHAR2,        --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,        --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)        --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_csv_outs_temp'; -- プログラム名
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
    cv_table   CONSTANT VARCHAR2(100) := 'XXCFR_CSV_OUTS_TEMP'; -- CSV出力ワークテーブル
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
    -- =====================================================
    --  CSVワークテーブルデータ登録 (A-10)
    -- =====================================================
--
    INSERT INTO xxcfr_csv_outs_temp ( 
       REQUEST_ID
      ,SEQ
      ,COL1                     -- 発注番号
      ,COL2                     -- 改訂番号
      ,COL3                     -- 承認ステータス
      ,COL4                     -- 発注作成日時
      ,COL5                     -- 仕入先
      ,COL6                     -- 仕入先サイトコード
      ,COL7                     -- 通貨コード
      ,COL8                     -- 合計金額
      ,COL9                     -- 購買担当
      ,COL10                    -- 発注明細番号
      ,COL11                    -- 品目カテゴリ
      ,COL12                    -- 摘要
      ,COL13                    -- 発注数量
      ,COL14                    -- 単位
      ,COL15                    -- 価格
      ,COL16                    -- 金額
      ,COL17                    -- 仕入先品目
      ,COL18                    -- 購買依頼番号
      ,COL19                    -- 申請拠点コード
      ,COL20                    -- 申請拠点名
      ,COL21                    -- 納入明細番号
      ,COL22                    -- 納品場所コード
      ,COL23                    -- 納品場所名
      ,COL24                    -- 納期
      ,COL25                    -- 希望入手日
      ,COL26                    -- 納品場所住所
      ,COL27                    -- 標準発注出力済
      ,COL28                    -- 特別情報項目1
      ,COL29                    -- 特別情報項目2
      ,COL30                    -- 特別情報項目3
      ,COL31                    -- 特別情報項目4
      ,COL32                    -- 特別情報項目5
      ,COL33                    -- 特別情報項目6
      ,COL34                    -- 特別情報項目7
      ,COL35                    -- 特別情報項目8
      ,COL36                    -- 特別情報項目9
      ,COL37                    -- 特別情報項目10
      ,COL38                    -- 特別情報項目11
      ,COL39                    -- 特別情報項目12
      ,COL40                    -- 特別情報項目13
      ,COL41                    -- 特別情報項目14
      ,COL42                    -- 特別情報項目15
      ,COL43                    -- 特別情報項目16
      ,COL44                    -- 特別情報項目17
      ,COL45                    -- 特別情報項目18
      ,COL46                    -- 特別情報項目19
      ,COL47                    -- 特別情報項目20
      ,COL48                    -- 特別情報項目21
      ,COL49                    -- 特別情報項目22
      ,COL50                    -- 特別情報項目23
      ,COL51                    -- 特別情報項目24
      ,COL52                    -- 特別情報項目25
      ,COL53                    -- 特別情報項目26
      ,COL54                    -- 特別情報項目27
      ,COL55                    -- 特別情報項目28
      ,COL56                    -- 特別情報項目29
      ,COL57                    -- 特別情報項目30
      ,COL58                    -- 特別情報項目31
      ,COL59                    -- 特別情報項目32
      ,COL60                    -- 特別情報項目33
      ,COL61                    -- 特別情報項目34
      ,COL62                    -- 特別情報項目35
      ,COL63                    -- 特別情報項目36
      ,COL64                    -- 特別情報項目37
      ,COL65                    -- 特別情報項目38
      ,COL66                    -- 特別情報項目39
      ,COL67                    -- 特別情報項目40
      ,COL68                    -- 特別情報項目41
      ,COL69                    -- 特別情報項目42
      ,COL70                    -- 特別情報項目43
      ,COL71                    -- 特別情報項目44
      ,COL72                    -- 特別情報項目45
      ,COL73                    -- 特別情報項目46
      ,COL74                    -- 特別情報項目47
      ,COL75                    -- 特別情報項目48
      ,COL76                    -- 特別情報項目49
      ,COL77                    -- 特別情報項目50
      ,COL78                    -- 特別情報項目51
      ,COL79                    -- 特別情報項目52
      ,COL80                    -- 特別情報項目53
      ,COL81                    -- 特別情報項目54
      ,COL82                    -- 特別情報項目55
      ,COL83                    -- 特別情報項目56
      ,COL84                    -- 特別情報項目57
      ,COL85                    -- 特別情報項目58
      ,COL86                    -- 特別情報項目59
      ,COL87                    -- 特別情報項目60
      ,COL88                    -- 特別情報項目61
      ,COL89                    -- 特別情報項目62
      ,COL90                    -- 特別情報項目63
      ,COL91                    -- 特別情報項目64
      ,COL92                    -- 特別情報項目65
      ,COL93                    -- 特別情報項目66
      ,COL94                    -- 特別情報項目67
      ,COL95                    -- 特別情報項目68
      ,COL96                    -- 特別情報項目69
      ,COL97                    -- 特別情報項目70
      ,COL98                    -- 特別情報項目71
      ,COL99                    -- 特別情報項目72
      ,COL100                   -- 特別情報項目73
      ,COL101                   -- 特別情報項目74
      ,COL102                   -- 特別情報項目75
      ,COL103                   -- 特別情報項目76
      ,COL104                   -- 特別情報項目77
      ,COL105                   -- 特別情報項目78
      ,COL106                   -- 特別情報項目79
      ,COL107                   -- 特別情報項目80
      ,COL108                   -- 特別情報項目81
      ,COL109                   -- 特別情報項目82
      ,COL110                   -- 特別情報項目83
      ,COL111                   -- 特別情報項目84
      ,COL112                   -- 特別情報項目85
      ,COL113                   -- 特別情報項目86
      ,COL114                   -- 特別情報項目87
      ,COL115                   -- 特別情報項目88
      ,COL116                   -- 特別情報項目89
      ,COL117                   -- 特別情報項目90
      ,COL118                   -- 特別情報項目91
      ,COL119                   -- 特別情報項目92
      ,COL120                   -- 特別情報項目93
      ,COL121                   -- 特別情報項目94
      ,COL122                   -- 特別情報項目95
      ,COL123                   -- 特別情報項目96
      ,COL124                   -- 特別情報項目97
      ,COL125                   -- 特別情報項目98
      ,COL126                   -- 特別情報項目99
      ,COL127                   -- 特別情報項目100
      ,COL128
      ,COL129
      ,COL130
      ,COL131
      ,COL132
      ,COL133
      ,COL134
      ,COL135
      ,COL136
      ,COL137
      ,COL138
      ,COL139
      ,COL140
      ,COL141
      ,COL142
      ,COL143
      ,COL144
      ,COL145
      ,COL146
      ,COL147
      ,COL148
      ,COL149
      ,COL150
    )
    (SELECT gn_conc_request_id                                 -- 要求ID
           ,ROWNUM                                             -- 出力順
           ,TO_CHAR(po_num)                                    -- 発注番号
           ,TO_CHAR(revision_num)                              -- 改訂番号
           ,authorization_status_name                          -- 承認ステータス
           ,TO_CHAR(po_creation_date, gv_format_date_ymdhms)   -- 発注作成日時
           ,vendor_name                                        -- 仕入先
           ,vendor_site_code                                   -- 仕入先サイトコード
           ,currency_code                                      -- 通貨コード
           ,TO_CHAR(sum_amount)                                -- 合計金額
           ,full_name                                          -- 購買担当
           ,TO_CHAR(line_num)                                  -- 発注明細番号
           ,item_category_name                                 -- 品目カテゴリ
           ,item_description                                   -- 摘要
           ,TO_CHAR(quantity_ordered)                          -- 発注数量
           ,unit_meas_lookup_code                              -- 単位
           ,TO_CHAR(unit_price)                                -- 価格
           ,TO_CHAR(amount)                                    -- 金額
           ,vendor_product_num                                 -- 仕入先品目
           ,TO_CHAR(requisition_num)                           -- 購買依頼番号
           ,apply_location_code                                -- 申請拠点コード
           ,apply_location_name                                -- 申請拠点名
           ,shipment_num                                       -- 納入明細番号
           ,deliver_location_code                              -- 納品場所コード
           ,deliver_location_name                              -- 納品場所名
           ,TO_CHAR(promised_date, gv_format_date_ymdhms)      -- 納期
           ,TO_CHAR(need_by_date, gv_format_date_ymdhms)       -- 希望入手日
           ,deliver_address                                    -- 納品場所住所
           ,standard_po_output                                 -- 標準発注出力済
           ,special_info_item1                                 -- 特別情報項目1
           ,special_info_item2                                 -- 特別情報項目2
           ,special_info_item3                                 -- 特別情報項目3
           ,special_info_item4                                 -- 特別情報項目4
           ,special_info_item5                                 -- 特別情報項目5
           ,special_info_item6                                 -- 特別情報項目6
           ,special_info_item7                                 -- 特別情報項目7
           ,special_info_item8                                 -- 特別情報項目8
           ,special_info_item9                                 -- 特別情報項目9
           ,special_info_item10                                -- 特別情報項目10
           ,special_info_item11                                -- 特別情報項目11
           ,special_info_item12                                -- 特別情報項目12
           ,special_info_item13                                -- 特別情報項目13
           ,special_info_item14                                -- 特別情報項目14
           ,special_info_item15                                -- 特別情報項目15
           ,special_info_item16                                -- 特別情報項目16
           ,special_info_item17                                -- 特別情報項目17
           ,special_info_item18                                -- 特別情報項目18
           ,special_info_item19                                -- 特別情報項目19
           ,special_info_item20                                -- 特別情報項目20
           ,special_info_item21                                -- 特別情報項目21
           ,special_info_item22                                -- 特別情報項目22
           ,special_info_item23                                -- 特別情報項目23
           ,special_info_item24                                -- 特別情報項目24
           ,special_info_item25                                -- 特別情報項目25
           ,special_info_item26                                -- 特別情報項目26
           ,special_info_item27                                -- 特別情報項目27
           ,special_info_item28                                -- 特別情報項目28
           ,special_info_item29                                -- 特別情報項目29
           ,special_info_item30                                -- 特別情報項目30
           ,special_info_item31                                -- 特別情報項目31
           ,special_info_item32                                -- 特別情報項目32
           ,special_info_item33                                -- 特別情報項目33
           ,special_info_item34                                -- 特別情報項目34
           ,special_info_item35                                -- 特別情報項目35
           ,special_info_item36                                -- 特別情報項目36
           ,special_info_item37                                -- 特別情報項目37
           ,special_info_item38                                -- 特別情報項目38
           ,special_info_item39                                -- 特別情報項目39
           ,special_info_item40                                -- 特別情報項目40
           ,special_info_item41                                -- 特別情報項目41
           ,special_info_item42                                -- 特別情報項目42
           ,special_info_item43                                -- 特別情報項目43
           ,special_info_item44                                -- 特別情報項目44
           ,special_info_item45                                -- 特別情報項目45
           ,special_info_item46                                -- 特別情報項目46
           ,special_info_item47                                -- 特別情報項目47
           ,special_info_item48                                -- 特別情報項目48
           ,special_info_item49                                -- 特別情報項目49
           ,special_info_item50                                -- 特別情報項目50
           ,special_info_item51                                -- 特別情報項目51
           ,special_info_item52                                -- 特別情報項目52
           ,special_info_item53                                -- 特別情報項目53
           ,special_info_item54                                -- 特別情報項目54
           ,special_info_item55                                -- 特別情報項目55
           ,special_info_item56                                -- 特別情報項目56
           ,special_info_item57                                -- 特別情報項目57
           ,special_info_item58                                -- 特別情報項目58
           ,special_info_item59                                -- 特別情報項目59
           ,special_info_item60                                -- 特別情報項目60
           ,special_info_item61                                -- 特別情報項目61
           ,special_info_item62                                -- 特別情報項目62
           ,special_info_item63                                -- 特別情報項目63
           ,special_info_item64                                -- 特別情報項目64
           ,special_info_item65                                -- 特別情報項目65
           ,special_info_item66                                -- 特別情報項目66
           ,special_info_item67                                -- 特別情報項目67
           ,special_info_item68                                -- 特別情報項目68
           ,special_info_item69                                -- 特別情報項目69
           ,special_info_item70                                -- 特別情報項目70
           ,special_info_item71                                -- 特別情報項目71
           ,special_info_item72                                -- 特別情報項目72
           ,special_info_item73                                -- 特別情報項目73
           ,special_info_item74                                -- 特別情報項目74
           ,special_info_item75                                -- 特別情報項目75
           ,special_info_item76                                -- 特別情報項目76
           ,special_info_item77                                -- 特別情報項目77
           ,special_info_item78                                -- 特別情報項目78
           ,special_info_item79                                -- 特別情報項目79
           ,special_info_item80                                -- 特別情報項目80
           ,special_info_item81                                -- 特別情報項目81
           ,special_info_item82                                -- 特別情報項目82
           ,special_info_item83                                -- 特別情報項目83
           ,special_info_item84                                -- 特別情報項目84
           ,special_info_item85                                -- 特別情報項目85
           ,special_info_item86                                -- 特別情報項目86
           ,special_info_item87                                -- 特別情報項目87
           ,special_info_item88                                -- 特別情報項目88
           ,special_info_item89                                -- 特別情報項目89
           ,special_info_item90                                -- 特別情報項目90
           ,special_info_item91                                -- 特別情報項目91
           ,special_info_item92                                -- 特別情報項目92
           ,special_info_item93                                -- 特別情報項目93
           ,special_info_item94                                -- 特別情報項目94
           ,special_info_item95                                -- 特別情報項目95
           ,special_info_item96                                -- 特別情報項目96
           ,special_info_item97                                -- 特別情報項目97
           ,special_info_item98                                -- 特別情報項目98
           ,special_info_item99                                -- 特別情報項目99
           ,special_info_item100                               -- 特別情報項目100
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
       FROM (SELECT gn_conc_request_id                     gn_conc_request_id              -- 要求ID
                   ,''                                     sort_num                        -- 出力順
                   ,xtsdp1.po_num                          po_num                          -- 発注番号
                   ,xtsdp1.revision_num                    revision_num                    -- 改訂番号
                   ,xtsdp1.authorization_status_name       authorization_status_name       -- 承認ステータス
                   ,xtsdp1.po_creation_date                po_creation_date                -- 発注作成日時
                   ,xtsdp1.vendor_name                     vendor_name                     -- 仕入先
                   ,xtsdp1.vendor_site_code                vendor_site_code                -- 仕入先サイトコード
                   ,xtsdp1.currency_code                   currency_code                   -- 通貨コード
                   ,sum_xtsdp2.sum_amount                  sum_amount                      -- 合計金額
                   ,xtsdp1.full_name                       full_name                       -- 購買担当
                   ,xtsdp1.line_num                        line_num                        -- 発注明細番号
                   ,xtsdp1.item_category_name              item_category_name              -- 品目カテゴリ
                   ,xtsdp1.item_description                item_description                -- 摘要
                   ,SUM(xtsdp1.quantity_ordered)           quantity_ordered                -- 発注数量
                   ,xtsdp1.unit_meas_lookup_code           unit_meas_lookup_code           -- 単位
                   ,xtsdp1.unit_price                      unit_price                      -- 価格
                   ,SUM(xtsdp1.amount)                     amount                          -- 金額
                   ,xtsdp1.vendor_product_num              vendor_product_num              -- 仕入先品目
                   ,xtsdp1.requisition_num                 requisition_num                 -- 購買依頼番号
                   ,xtsdp1.apply_location_code             apply_location_code             -- 申請拠点コード
                   ,xtsdp1.apply_location_name             apply_location_name             -- 申請拠点名
                   ,xtsdp1.shipment_num                    shipment_num                    -- 納入明細番号
                   ,xtsdp1.deliver_location_code           deliver_location_code           -- 納品場所コード
                   ,xtsdp1.deliver_location_name           deliver_location_name           -- 納品場所名
                   ,xtsdp1.promised_date                   promised_date                   -- 納期
                   ,xtsdp1.need_by_date                    need_by_date                    -- 希望入手日
                   ,xtsdp1.deliver_address                 deliver_address                 -- 納品場所住所
                   ,xtsdp1.standard_po_output              standard_po_output              -- 標準発注出力済
                   ,xtsdp1.special_info_item1              special_info_item1              -- 特別情報項目1
                   ,xtsdp1.special_info_item2              special_info_item2              -- 特別情報項目2
                   ,xtsdp1.special_info_item3              special_info_item3              -- 特別情報項目3
                   ,xtsdp1.special_info_item4              special_info_item4              -- 特別情報項目4
                   ,xtsdp1.special_info_item5              special_info_item5              -- 特別情報項目5
                   ,xtsdp1.special_info_item6              special_info_item6              -- 特別情報項目6
                   ,xtsdp1.special_info_item7              special_info_item7              -- 特別情報項目7
                   ,xtsdp1.special_info_item8              special_info_item8              -- 特別情報項目8
                   ,xtsdp1.special_info_item9              special_info_item9              -- 特別情報項目9
                   ,xtsdp1.special_info_item10             special_info_item10             -- 特別情報項目10
                   ,xtsdp1.special_info_item11             special_info_item11             -- 特別情報項目11
                   ,xtsdp1.special_info_item12             special_info_item12             -- 特別情報項目12
                   ,xtsdp1.special_info_item13             special_info_item13             -- 特別情報項目13
                   ,xtsdp1.special_info_item14             special_info_item14             -- 特別情報項目14
                   ,xtsdp1.special_info_item15             special_info_item15             -- 特別情報項目15
                   ,xtsdp1.special_info_item16             special_info_item16             -- 特別情報項目16
                   ,xtsdp1.special_info_item17             special_info_item17             -- 特別情報項目17
                   ,xtsdp1.special_info_item18             special_info_item18             -- 特別情報項目18
                   ,xtsdp1.special_info_item19             special_info_item19             -- 特別情報項目19
                   ,xtsdp1.special_info_item20             special_info_item20             -- 特別情報項目20
                   ,xtsdp1.special_info_item21             special_info_item21             -- 特別情報項目21
                   ,xtsdp1.special_info_item22             special_info_item22             -- 特別情報項目22
                   ,xtsdp1.special_info_item23             special_info_item23             -- 特別情報項目23
                   ,xtsdp1.special_info_item24             special_info_item24             -- 特別情報項目24
                   ,xtsdp1.special_info_item25             special_info_item25             -- 特別情報項目25
                   ,xtsdp1.special_info_item26             special_info_item26             -- 特別情報項目26
                   ,xtsdp1.special_info_item27             special_info_item27             -- 特別情報項目27
                   ,xtsdp1.special_info_item28             special_info_item28             -- 特別情報項目28
                   ,xtsdp1.special_info_item29             special_info_item29             -- 特別情報項目29
                   ,xtsdp1.special_info_item30             special_info_item30             -- 特別情報項目30
                   ,xtsdp1.special_info_item31             special_info_item31             -- 特別情報項目31
                   ,xtsdp1.special_info_item32             special_info_item32             -- 特別情報項目32
                   ,xtsdp1.special_info_item33             special_info_item33             -- 特別情報項目33
                   ,xtsdp1.special_info_item34             special_info_item34             -- 特別情報項目34
                   ,xtsdp1.special_info_item35             special_info_item35             -- 特別情報項目35
                   ,xtsdp1.special_info_item36             special_info_item36             -- 特別情報項目36
                   ,xtsdp1.special_info_item37             special_info_item37             -- 特別情報項目37
                   ,xtsdp1.special_info_item38             special_info_item38             -- 特別情報項目38
                   ,xtsdp1.special_info_item39             special_info_item39             -- 特別情報項目39
                   ,xtsdp1.special_info_item40             special_info_item40             -- 特別情報項目40
                   ,xtsdp1.special_info_item41             special_info_item41             -- 特別情報項目41
                   ,xtsdp1.special_info_item42             special_info_item42             -- 特別情報項目42
                   ,xtsdp1.special_info_item43             special_info_item43             -- 特別情報項目43
                   ,xtsdp1.special_info_item44             special_info_item44             -- 特別情報項目44
                   ,xtsdp1.special_info_item45             special_info_item45             -- 特別情報項目45
                   ,xtsdp1.special_info_item46             special_info_item46             -- 特別情報項目46
                   ,xtsdp1.special_info_item47             special_info_item47             -- 特別情報項目47
                   ,xtsdp1.special_info_item48             special_info_item48             -- 特別情報項目48
                   ,xtsdp1.special_info_item49             special_info_item49             -- 特別情報項目49
                   ,xtsdp1.special_info_item50             special_info_item50             -- 特別情報項目50
                   ,xtsdp1.special_info_item51             special_info_item51             -- 特別情報項目51
                   ,xtsdp1.special_info_item52             special_info_item52             -- 特別情報項目52
                   ,xtsdp1.special_info_item53             special_info_item53             -- 特別情報項目53
                   ,xtsdp1.special_info_item54             special_info_item54             -- 特別情報項目54
                   ,xtsdp1.special_info_item55             special_info_item55             -- 特別情報項目55
                   ,xtsdp1.special_info_item56             special_info_item56             -- 特別情報項目56
                   ,xtsdp1.special_info_item57             special_info_item57             -- 特別情報項目57
                   ,xtsdp1.special_info_item58             special_info_item58             -- 特別情報項目58
                   ,xtsdp1.special_info_item59             special_info_item59             -- 特別情報項目59
                   ,xtsdp1.special_info_item60             special_info_item60             -- 特別情報項目60
                   ,xtsdp1.special_info_item61             special_info_item61             -- 特別情報項目61
                   ,xtsdp1.special_info_item62             special_info_item62             -- 特別情報項目62
                   ,xtsdp1.special_info_item63             special_info_item63             -- 特別情報項目63
                   ,xtsdp1.special_info_item64             special_info_item64             -- 特別情報項目64
                   ,xtsdp1.special_info_item65             special_info_item65             -- 特別情報項目65
                   ,xtsdp1.special_info_item66             special_info_item66             -- 特別情報項目66
                   ,xtsdp1.special_info_item67             special_info_item67             -- 特別情報項目67
                   ,xtsdp1.special_info_item68             special_info_item68             -- 特別情報項目68
                   ,xtsdp1.special_info_item69             special_info_item69             -- 特別情報項目69
                   ,xtsdp1.special_info_item70             special_info_item70             -- 特別情報項目70
                   ,xtsdp1.special_info_item71             special_info_item71             -- 特別情報項目71
                   ,xtsdp1.special_info_item72             special_info_item72             -- 特別情報項目72
                   ,xtsdp1.special_info_item73             special_info_item73             -- 特別情報項目73
                   ,xtsdp1.special_info_item74             special_info_item74             -- 特別情報項目74
                   ,xtsdp1.special_info_item75             special_info_item75             -- 特別情報項目75
                   ,xtsdp1.special_info_item76             special_info_item76             -- 特別情報項目76
                   ,xtsdp1.special_info_item77             special_info_item77             -- 特別情報項目77
                   ,xtsdp1.special_info_item78             special_info_item78             -- 特別情報項目78
                   ,xtsdp1.special_info_item79             special_info_item79             -- 特別情報項目79
                   ,xtsdp1.special_info_item80             special_info_item80             -- 特別情報項目80
                   ,xtsdp1.special_info_item81             special_info_item81             -- 特別情報項目81
                   ,xtsdp1.special_info_item82             special_info_item82             -- 特別情報項目82
                   ,xtsdp1.special_info_item83             special_info_item83             -- 特別情報項目83
                   ,xtsdp1.special_info_item84             special_info_item84             -- 特別情報項目84
                   ,xtsdp1.special_info_item85             special_info_item85             -- 特別情報項目85
                   ,xtsdp1.special_info_item86             special_info_item86             -- 特別情報項目86
                   ,xtsdp1.special_info_item87             special_info_item87             -- 特別情報項目87
                   ,xtsdp1.special_info_item88             special_info_item88             -- 特別情報項目88
                   ,xtsdp1.special_info_item89             special_info_item89             -- 特別情報項目89
                   ,xtsdp1.special_info_item90             special_info_item90             -- 特別情報項目90
                   ,xtsdp1.special_info_item91             special_info_item91             -- 特別情報項目91
                   ,xtsdp1.special_info_item92             special_info_item92             -- 特別情報項目92
                   ,xtsdp1.special_info_item93             special_info_item93             -- 特別情報項目93
                   ,xtsdp1.special_info_item94             special_info_item94             -- 特別情報項目94
                   ,xtsdp1.special_info_item95             special_info_item95             -- 特別情報項目95
                   ,xtsdp1.special_info_item96             special_info_item96             -- 特別情報項目96
                   ,xtsdp1.special_info_item97             special_info_item97             -- 特別情報項目97
                   ,xtsdp1.special_info_item98             special_info_item98             -- 特別情報項目98
                   ,xtsdp1.special_info_item99             special_info_item99             -- 特別情報項目99
                   ,xtsdp1.special_info_item100            special_info_item100            -- 特別情報項目100
               FROM xxcfo_tmp_standard_data_po        xtsdp1        -- 発注書データ出力ワークテーブル
                   ,(SELECT xtsdp2.po_num                    po_num
                           ,xtsdp2.org_id                    org_id
                           ,SUM(xtsdp2.amount)               sum_amount
                       FROM xxcfo_tmp_standard_data_po    xtsdp2    -- 発注書データ出力ワークテーブル
                      GROUP BY xtsdp2.po_num
                              ,xtsdp2.org_id
                    ) sum_xtsdp2
              WHERE xtsdp1.po_num = sum_xtsdp2.po_num
                AND xtsdp1.org_id = sum_xtsdp2.org_id
              GROUP BY xtsdp1.po_num
                      ,xtsdp1.revision_num
                      ,xtsdp1.authorization_status_name
                      ,xtsdp1.po_creation_date
                      ,xtsdp1.vendor_name
                      ,xtsdp1.vendor_site_code
                      ,xtsdp1.currency_code
                      ,sum_xtsdp2.sum_amount
                      ,xtsdp1.full_name
                      ,xtsdp1.line_num
                      ,xtsdp1.item_category_name
                      ,xtsdp1.item_description
                      ,xtsdp1.unit_meas_lookup_code
                      ,xtsdp1.unit_price
                      ,xtsdp1.vendor_product_num
                      ,xtsdp1.requisition_num
                      ,xtsdp1.apply_location_code
                      ,xtsdp1.apply_location_name
                      ,xtsdp1.shipment_num
                      ,xtsdp1.deliver_location_code
                      ,xtsdp1.deliver_location_name
                      ,xtsdp1.promised_date
                      ,xtsdp1.need_by_date
                      ,xtsdp1.deliver_address
                      ,xtsdp1.standard_po_output
                      ,xtsdp1.special_info_item1
                      ,xtsdp1.special_info_item2
                      ,xtsdp1.special_info_item3
                      ,xtsdp1.special_info_item4
                      ,xtsdp1.special_info_item5
                      ,xtsdp1.special_info_item6
                      ,xtsdp1.special_info_item7
                      ,xtsdp1.special_info_item8
                      ,xtsdp1.special_info_item9
                      ,xtsdp1.special_info_item10
                      ,xtsdp1.special_info_item11
                      ,xtsdp1.special_info_item12
                      ,xtsdp1.special_info_item13
                      ,xtsdp1.special_info_item14
                      ,xtsdp1.special_info_item15
                      ,xtsdp1.special_info_item16
                      ,xtsdp1.special_info_item17
                      ,xtsdp1.special_info_item18
                      ,xtsdp1.special_info_item19
                      ,xtsdp1.special_info_item20
                      ,xtsdp1.special_info_item21
                      ,xtsdp1.special_info_item22
                      ,xtsdp1.special_info_item23
                      ,xtsdp1.special_info_item24
                      ,xtsdp1.special_info_item25
                      ,xtsdp1.special_info_item26
                      ,xtsdp1.special_info_item27
                      ,xtsdp1.special_info_item28
                      ,xtsdp1.special_info_item29
                      ,xtsdp1.special_info_item30
                      ,xtsdp1.special_info_item31
                      ,xtsdp1.special_info_item32
                      ,xtsdp1.special_info_item33
                      ,xtsdp1.special_info_item34
                      ,xtsdp1.special_info_item35
                      ,xtsdp1.special_info_item36
                      ,xtsdp1.special_info_item37
                      ,xtsdp1.special_info_item38
                      ,xtsdp1.special_info_item39
                      ,xtsdp1.special_info_item40
                      ,xtsdp1.special_info_item41
                      ,xtsdp1.special_info_item42
                      ,xtsdp1.special_info_item43
                      ,xtsdp1.special_info_item44
                      ,xtsdp1.special_info_item45
                      ,xtsdp1.special_info_item46
                      ,xtsdp1.special_info_item47
                      ,xtsdp1.special_info_item48
                      ,xtsdp1.special_info_item49
                      ,xtsdp1.special_info_item50
                      ,xtsdp1.special_info_item51
                      ,xtsdp1.special_info_item52
                      ,xtsdp1.special_info_item53
                      ,xtsdp1.special_info_item54
                      ,xtsdp1.special_info_item55
                      ,xtsdp1.special_info_item56
                      ,xtsdp1.special_info_item57
                      ,xtsdp1.special_info_item58
                      ,xtsdp1.special_info_item59
                      ,xtsdp1.special_info_item60
                      ,xtsdp1.special_info_item61
                      ,xtsdp1.special_info_item62
                      ,xtsdp1.special_info_item63
                      ,xtsdp1.special_info_item64
                      ,xtsdp1.special_info_item65
                      ,xtsdp1.special_info_item66
                      ,xtsdp1.special_info_item67
                      ,xtsdp1.special_info_item68
                      ,xtsdp1.special_info_item69
                      ,xtsdp1.special_info_item70
                      ,xtsdp1.special_info_item71
                      ,xtsdp1.special_info_item72
                      ,xtsdp1.special_info_item73
                      ,xtsdp1.special_info_item74
                      ,xtsdp1.special_info_item75
                      ,xtsdp1.special_info_item76
                      ,xtsdp1.special_info_item77
                      ,xtsdp1.special_info_item78
                      ,xtsdp1.special_info_item79
                      ,xtsdp1.special_info_item80
                      ,xtsdp1.special_info_item81
                      ,xtsdp1.special_info_item82
                      ,xtsdp1.special_info_item83
                      ,xtsdp1.special_info_item84
                      ,xtsdp1.special_info_item85
                      ,xtsdp1.special_info_item86
                      ,xtsdp1.special_info_item87
                      ,xtsdp1.special_info_item88
                      ,xtsdp1.special_info_item89
                      ,xtsdp1.special_info_item90
                      ,xtsdp1.special_info_item91
                      ,xtsdp1.special_info_item92
                      ,xtsdp1.special_info_item93
                      ,xtsdp1.special_info_item94
                      ,xtsdp1.special_info_item95
                      ,xtsdp1.special_info_item96
                      ,xtsdp1.special_info_item97
                      ,xtsdp1.special_info_item98
                      ,xtsdp1.special_info_item99
                      ,xtsdp1.special_info_item100
            )
    );
--
    IF (SQL%ROWCOUNT = 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo       -- 'XXCFO'
                                                     ,gv_msg_cfo_00035     -- データ挿入エラー
                                                     ,gv_tkn_table         -- トークン'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                           -- 発注書データ出力ワークテーブル
                                                     ,gv_tkn_errmsg        -- トークン'ERRMSG'
                                                     ,SQLERRM              -- SQLエラーメッセージ
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_csv_outs_temp;
--
  /**********************************************************************************
   * Procedure Name   : out_put_file
   * Description      : OUTファイル出力処理 (A-11)
   ***********************************************************************************/
  PROCEDURE out_put_file(
    ov_errbuf      OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_put_file'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    xxcfr_common_pkg.csv_out( gn_conc_request_id     -- 要求ID
                             ,gv_lookup_type4        -- 参照タイプ
                             ,gn_target_cnt          -- 処理件数
                             ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
                             ,lv_retcode             -- リターン・コード             --# 固定 #
                             ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_normal) THEN
--
      gn_normal_cnt := gn_target_cnt;
--
    ELSE
      RAISE global_api_expt;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END out_put_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_po_dept_code            IN         VARCHAR2,     --   発注作成部署
    iv_po_agent_code           IN         VARCHAR2,     --   発注作成者
    iv_vender_code             IN         VARCHAR2,     --   仕入先
    iv_po_num                  IN         VARCHAR2,     --   発注番号
    iv_po_creation_date_from   IN         VARCHAR2,     --   発注作成日From
    iv_po_creation_date_to     IN         VARCHAR2,     --   発注作成日To
    iv_po_approved_date_from   IN         VARCHAR2,     --   発注承認日From
    iv_po_approved_date_to     IN         VARCHAR2,     --   発注承認日To
    iv_reissue_flag            IN         VARCHAR2,     --   再発行フラグ
    ov_errbuf                  OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                  OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_errbuf2                VARCHAR2(5000);                   -- エラー・メッセージ
    lv_errmsg2                VARCHAR2(5000);                   -- ユーザー・エラー・メッセージ
    lt_po_num                 g_xxcfo_po_data_rec.po_num%TYPE;  -- 発注番号一時保存
    lt_org_id                 g_xxcfo_po_data_rec.org_id%TYPE;  -- 組織ID一時保存
    ln_po_agent_code          NUMBER;                           -- 発注作成者
    ld_po_creation_date_from  DATE;                             -- 発注作成日From
    ld_po_creation_date_to    DATE;                             -- 発注作成日To
    ld_po_approved_date_from  DATE;                             -- 発注承認日From
    ld_po_approved_date_to    DATE;                             -- 発注承認日To
    ln_i                      NUMBER;                           -- インクリメント変数
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
    -- グローバル変数の初期化
    gn_target_cnt          := 0;     -- 対象件数
    gn_normal_cnt          := 0;     -- 正常件数
    gn_error_cnt           := 0;     -- エラー件数
    gn_warn_cnt            := 0;     -- 警告件数
    gn_po_num_in_count     := 0;     -- ステータス管理テーブルへの発注番号登録件数
--
    -- =====================================================
    --  入力パラメータ値ログ出力処理(A-1)
    -- =====================================================
    init(
       iv_po_dept_code                    -- 発注作成部署
      ,iv_po_agent_code                   -- 発注作成者
      ,iv_vender_code                     -- 仕入先
      ,iv_po_num                          -- 発注番号
      ,iv_po_creation_date_from           -- 発注作成日From
      ,iv_po_creation_date_to             -- 発注作成日To
      ,iv_po_approved_date_from           -- 発注承認日From
      ,iv_po_approved_date_to             -- 発注承認日To
      ,iv_reissue_flag                    -- 再発行フラグ
      ,lv_errbuf                          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                         -- リターン・コード             --# 固定 #
      ,lv_errmsg);                        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  初期処理(A-2)
    -- =====================================================
    get_profile_lookup_val(
       iv_po_creation_date_from           -- 発注作成日From
      ,iv_po_creation_date_to             -- 発注作成日To
      ,iv_po_approved_date_from           -- 発注承認日From
      ,iv_po_approved_date_to             -- 発注承認日To
      ,iv_reissue_flag                    -- 再発行フラグ
      ,lv_errbuf                          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                         -- リターン・コード             --# 固定 #
      ,lv_errmsg);                        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  発注データ取得(A-3)
    -- =====================================================
    -- 初期化処理
    gn_target_cnt := 0;
--
    ln_po_agent_code         := TO_NUMBER(iv_po_agent_code);                               -- 発注作成者
    ld_po_creation_date_from := TO_DATE(iv_po_creation_date_from, gv_format_date_ymdhms);  -- 発注作成日From
    ld_po_creation_date_to   := TO_DATE(iv_po_creation_date_to,   gv_format_date_ymdhms);  -- 発注作成日To
    ld_po_approved_date_from := TO_DATE(iv_po_approved_date_from, gv_format_date_ymdhms);  -- 発注承認日From
    ld_po_approved_date_to   := TO_DATE(iv_po_approved_date_to,   gv_format_date_ymdhms);  -- 発注承認日To
--
    -- カーソルオープン
    OPEN po_data_cur(
            iv_po_dept_code                 -- 発注作成部署
           ,ln_po_agent_code                -- 発注作成者
           ,iv_vender_code                  -- 仕入先
           ,iv_po_num                       -- 発注番号
           ,ld_po_creation_date_from        -- 発注作成日From
           ,ld_po_creation_date_to          -- 発注作成日To
           ,ld_po_approved_date_from        -- 発注承認日From
           ,ld_po_approved_date_to          -- 発注承認日To
           ,iv_reissue_flag);               -- 再発行フラグ
--
    LOOP
      FETCH po_data_cur INTO g_xxcfo_po_data_rec;
      EXIT WHEN po_data_cur%NOTFOUND;
--
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 初期化処理
      -- 配列のNULLをINSERTしようとするとエラーで落ちる為、初期化処理として値を代入する。
      -- 尚、INSERT時はCASEを用いてNULLをINSERT出来るようにコーディングする。
      FOR ln_i IN 1..100 LOOP
        gt_special_info_item(ln_i) := ' ';
      END LOOP;
      gn_special_info_cnt := 0;
--
      IF   (g_xxcfo_po_data_rec.attache_judge_code = gv_judge_code_10    -- 自販機
        OR  g_xxcfo_po_data_rec.attache_judge_code = gv_judge_code_20    -- 固定資産
        OR  g_xxcfo_po_data_rec.attache_judge_code = gv_judge_code_30)   -- 名刺
      THEN
--
        -- =====================================================
        --  添付情報取得処理(A-4)
        -- =====================================================
        get_attache_info(
           lv_errbuf                               -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                              -- リターン・コード             --# 固定 #
          ,lv_errmsg);                             -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
        -- =====================================================
        --  添付情報編集処理(A-5)
        -- =====================================================
        edit_attache_info(
           lv_errbuf                               -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                              -- リターン・コード             --# 固定 #
          ,lv_errmsg);                             -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
        -- 自販機の場合
        IF (g_xxcfo_po_data_rec.attache_judge_code = gv_judge_code_10) THEN
          -- =====================================================
          --  顧客情報取得処理(A-6)
          -- =====================================================
          get_customer_info(
             lv_errbuf                               -- エラー・メッセージ           --# 固定 #
            ,lv_retcode                              -- リターン・コード             --# 固定 #
            ,lv_errmsg);                             -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            RAISE global_process_expt;
          END IF;
--
          -- =====================================================
          --  機種情報取得処理(A-7)
          -- =====================================================
          get_un_info(
             lv_errbuf                             -- エラー・メッセージ           --# 固定 #
            ,lv_retcode                            -- リターン・コード             --# 固定 #
            ,lv_errmsg);                           -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            RAISE global_process_expt;
          END IF;
--
        END IF;
      END IF;
--
      -- =====================================================
      --  ステータス管理テーブルデータ登録(A-8)
      -- =====================================================
      IF (iv_reissue_flag = gv_reissue_flag_0) THEN
--
        -- 発注番号でキーブレイクにて処理開始
        IF ( lt_po_num != g_xxcfo_po_data_rec.po_num
          OR lt_po_num IS NULL
          OR lt_org_id != g_xxcfo_po_data_rec.org_id
          OR lt_org_id IS NULL)
        THEN
          lt_po_num := g_xxcfo_po_data_rec.po_num;
          lt_org_id := g_xxcfo_po_data_rec.org_id;
--
          insert_po_status_mng(
             lv_errbuf                           -- エラー・メッセージ           --# 固定 #
            ,lv_retcode                          -- リターン・コード             --# 固定 #
            ,lv_errmsg);                         -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            RAISE global_process_expt;
--
          ELSE
            -- 登録できた場合、発注番号・組織IDを保持する。
            gn_po_num_in_count            := gn_po_num_in_count + 1;
            gt_po_num(gn_po_num_in_count) := lt_po_num;
            gt_org_id(gn_po_num_in_count) := lt_org_id;
--
          END IF;
--
        END IF;
      END IF;
--
      -- =====================================================
      --  発注書データ出力ワークテーブルデータ登録(A-9)
      -- =====================================================
      insert_tmp_standard_data_po(
         lv_errbuf                           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                          -- リターン・コード             --# 固定 #
        ,lv_errmsg);                         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
    END LOOP;
--
    IF po_data_cur%ISOPEN THEN
      CLOSE po_data_cur;
    END IF;
--
    -- 警告終了
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo     -- アプリケーション短縮名：XXCFO
                                                     ,gv_msg_cfo_00004   -- 対象データ無しエラー
                                                    )
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
    ELSE
      -- =====================================================
      --  CSVワークテーブルデータ登録(A-10)
      -- =====================================================
      insert_csv_outs_temp(
         lv_errbuf                           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                          -- リターン・コード             --# 固定 #
        ,lv_errmsg);                         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  OUTファイル出力処理(A-11)
      -- =====================================================
      out_put_file(
         lv_errbuf                           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                          -- リターン・コード             --# 固定 #
        ,lv_errmsg);                         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- テーブルロックエラー
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo        -- 'XXCFO'
                                                     ,gv_msg_cfo_00019      -- テーブルロックエラー
                                                     ,gv_tkn_table          -- トークン'TABLE'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        gv_msg_kbn_cfo
                                                       ,gt_lookup_code_000A00006
                                                      )                            -- 「発注情報」
                                                    )                       -- 発注情報
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
      IF po_data_cur%ISOPEN THEN
        CLOSE po_data_cur;
      END IF;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      IF po_data_cur%ISOPEN THEN
        CLOSE po_data_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF po_data_cur%ISOPEN THEN
        CLOSE po_data_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF po_data_cur%ISOPEN THEN
        CLOSE po_data_cur;
      END IF;
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
    errbuf                     OUT NOCOPY VARCHAR2,         --    エラー・メッセージ  --# 固定 #
    retcode                    OUT NOCOPY VARCHAR2,         --    エラーコード        --# 固定 #
    iv_po_dept_code            IN         VARCHAR2,         --    発注作成部署
    iv_po_agent_code           IN         VARCHAR2,         --    発注作成者
    iv_vender_code             IN         VARCHAR2,         --    仕入先
    iv_po_num                  IN         VARCHAR2,         --    発注番号
    iv_po_creation_date_from   IN         VARCHAR2,         --    発注作成日From
    iv_po_creation_date_to     IN         VARCHAR2,         --    発注作成日To
    iv_po_approved_date_from   IN         VARCHAR2,         --    発注承認日From
    iv_po_approved_date_to     IN         VARCHAR2,         --    発注承認日To
    iv_reissue_flag            IN         VARCHAR2          --    再発行フラグ
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
    lv_errbuf2         VARCHAR2(5000);  -- エラー・メッセージ
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => gv_file_type_log
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
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_po_dept_code                    -- 発注作成部署
      ,iv_po_agent_code                   -- 発注作成者
      ,iv_vender_code                     -- 仕入先
      ,iv_po_num                          -- 発注番号
      ,iv_po_creation_date_from           -- 発注作成日From
      ,iv_po_creation_date_to             -- 発注作成日To
      ,iv_po_approved_date_from           -- 発注承認日From
      ,iv_po_approved_date_to             -- 発注承認日To
      ,iv_reissue_flag                    -- 再発行フラグ
      ,lv_errbuf                          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                         -- リターン・コード             --# 固定 #
      ,lv_errmsg                          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラーの場合、エラー発生時処理件数を設定する
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;          -- 対象件数
      gn_normal_cnt := 0;          -- 成功件数
      gn_error_cnt  := 1;          -- エラー件数
    END IF;
--
--###########################  固定部 START   #####################################################
--
    -- =====================================================
    --  終了処理(A-13)
    -- =====================================================
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
    END IF;
--
    --エラーの場合、システムエラーメッセージ出力
    IF (lv_retcode = cv_status_error) THEN
      -- システムエラーメッセージ出力
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                       iv_application  => gv_msg_kbn_cfo
                      ,iv_name         => gv_msg_cfo_00036
                     );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf2 --エラーメッセージ
      );
      -- エラーバッファのメッセージ連結
      lv_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --ユーザー・エラーメッセージ
      );
    END IF;
--
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
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCFO016A02C;
/
