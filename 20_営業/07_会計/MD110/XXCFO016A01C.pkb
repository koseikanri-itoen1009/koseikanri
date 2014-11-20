CREATE OR REPLACE PACKAGE BODY XXCFO016A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO016A01C(body)
 * Description     : 標準発注書出力処理
 * MD.050          : MD050_CFO_016_A01_標準発注書出力処理
 * MD.070          : MD050_CFO_016_A01_標準発注書出力処理
 * Version         : 1.9
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
 *  insert_rep_standard_po P   ワークテーブルデータ登録                     (A-8)
 *  insert_po_status_mng P     ステータス管理テーブルデータ登録             (A-9)
 *  insert_csv_outs_temp P     0件出力メッセージ                            (A-10)
 *  out_put_file    P          ワークテーブルデータ登録（明細0件用）        (A-11)
 *  act_svf         P          SVF起動処理                                  (A-12)
 *  delete_rep_standard_po P   ワークテーブルデータ削除                     (A-13)
 *  delete_po_status_mng P     ステータス管理テーブルデータ削除             (A-14)
 *  submain         P          メイン処理プロシージャ
 *  main            P          コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-11-20    1.0  SCS 山口 優   初回作成
 *  2009-02-06    1.1  SCS 嵐田勇人  [障害CFO_001]事業所アドオンマスタの有効日付チェックを追加
 *  2009-02-09    1.2  SCS 嵐田勇人  [障害CFO_002]出力桁数対応
 *  2009-03-06    1.3  SCS 嵐田勇人  SVF起動処理変更対応
 *  2009-03-16    1.4  SCS 嵐田勇人  [障害T1_0050]エラーログ対応
 *  2009-03-23    1.5  SCS 開原拓也  [障害T1_0059]機種コードの変更対応
 *  2009-04-14    1.6  SCS 嵐田勇人  [障害T1_0533]SVF出力ファイル名格納変数桁数対応
 *  2009-07-03    1.7  SCS 嵐田勇人  [障害0000131]発注担当者郵便番号ハイフン対応
 *  2009-12-24    1.8  SCS 寺内真紀  [障害E_本稼動_00592]仕入先敬称追加・納品場所変更対応
 *  2010-01-19    1.9  SCS 寺内真紀  [障害E_本稼動_01183]従業員マスタ抽出条件変更対応
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
  gv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCFO016A01C';      -- パッケージ名
  gv_msg_kbn_cfo           CONSTANT VARCHAR2(5)   := 'XXCFO';
  gv_flag_y                CONSTANT VARCHAR2(1)   := 'Y';                 -- フラグ（Y）
  gv_flag_n                CONSTANT VARCHAR2(1)   := 'N';                 -- フラグ（N）
  gv_approved              CONSTANT VARCHAR2(10)  := 'APPROVED';          -- 承認済
  gv_standard              CONSTANT VARCHAR2(10)  := 'STANDARD';          -- 標準発注
  gv_reissue_flag_0        CONSTANT VARCHAR2(1)   := '0';                 -- 新規
  gv_reissue_flag_1        CONSTANT VARCHAR2(1)   := '1';                 -- 再発行
  gv_lookup_code_100       CONSTANT VARCHAR2(3)   := '100';               -- 設置先_顧客コード=
  gv_lookup_code_110       CONSTANT VARCHAR2(3)   := '110';               -- 紹介会社=
  gv_judge_code_10         CONSTANT VARCHAR2(2)   := '10';                -- 自販機
  gv_entity_name           CONSTANT VARCHAR2(10)  := 'REQ_LINES';         -- 購買依頼明細
  gv_file_type_log         CONSTANT VARCHAR2(10)  := 'LOG';               -- ログ出力
  gv_format_date_ymd       CONSTANT VARCHAR2(8)   := 'YYYYMMDD';          -- 日付フォーマット（年月日）
  gv_format_date_ymdhms    CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
                                                                          -- 日付フォーマット（年月日時分秒）
  gt_lookup_code_000A00002 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00002';
                                                                                -- 「発注作成日From」
  gt_lookup_code_000A00003 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00003';
                                                                                -- 「発注作成日To」
  gt_lookup_code_000A00004 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00004';
                                                                                -- 「発注承認日From」
  gt_lookup_code_000A00005 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00005';
                                                                                -- 「発注承認日To」
  gt_lookup_code_016A01001 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO016A01001';
                                                                                -- 「SVF帳票共通関数(0件出力メッセージ)」
  gt_lookup_code_016A01002 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO016A01002';
                                                                                -- 「'SVF帳票共通関数(SVFコンカレントの起動)'」
  gt_lookup_code_000A00006 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00006';
                                                                                -- 「発注情報」
--
  -- メッセージ番号
  gv_msg_cfo_00004   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004'; -- 警告エラーメッセージ
  gv_msg_cfo_00008   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00008'; -- 明細0件用メッセージ
  gv_msg_cfo_00009   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00009'; -- 共通関数エラーメッセージ
  gv_msg_cfo_00010   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00010'; -- 添付情報取得エラーメッセージ
  gv_msg_cfo_00011   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00011'; -- 顧客情報取得エラーメッセージ
  gv_msg_cfo_00012   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00012'; -- 機種情報取得エラーメッセージ
  gv_msg_cfo_00013   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00013'; -- 添付情報文字列検索エラーメッセージ
  gv_msg_cfo_00019   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019'; -- テーブルロックエラーメッセージ
  gv_msg_cfo_00025   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00025'; -- データ削除エラーメッセージ
  gv_msg_cfo_00033   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00033'; -- コンカレントパラメータ値大小チェックエラーメッセージ
  gv_msg_cfo_00035   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00035'; -- データ作成エラーメッセージエラーメッセージ
  gv_msg_cfo_00036   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00036'; -- システムエラーメッセージ
--ADD_Ver.1.8_2009/12/24_START----------------------------------------------------------------------------
  gv_msg_cfo_00001   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001'; --プロファイル取得エラーメッセージ
--ADD_Ver.1.8_2009/12/24_END------------------------------------------------------------------------------
--
  -- トークン
  gv_tkn_param_name_from CONSTANT VARCHAR2(15) := 'PARAM_NAME_FROM';  -- 大小チェックFrom 文字用
  gv_tkn_param_name_to   CONSTANT VARCHAR2(15) := 'PARAM_NAME_TO';    -- 大小チェックTo 文字用
  gv_tkn_param_val_from  CONSTANT VARCHAR2(15) := 'PARAM_VAL_FROM';   -- 大小チェックFrom 値用
  gv_tkn_param_val_to    CONSTANT VARCHAR2(15) := 'PARAM_VAL_TO';     -- 大小チェックTo 値用
  gv_tkn_table           CONSTANT VARCHAR2(15) := 'TABLE';            -- テーブル名
  gv_tkn_pk1_value       CONSTANT VARCHAR2(15) := 'PK1_VALUE';        -- 購買依頼明細ID
  gv_tkn_requisition_no  CONSTANT VARCHAR2(15) := 'REQUISITION_NO';   -- 購買依頼番号
  gv_tkn_po_num          CONSTANT VARCHAR2(15) := 'PO_NUM';           -- 発注番号
  gv_tkn_search_string   CONSTANT VARCHAR2(15) := 'SEARCH_STRING';    -- 検索対象文字列
  gv_tkn_account_number  CONSTANT VARCHAR2(15) := 'ACCOUNT_NUMBER';   -- 顧客番号
  gv_tkn_un_number_id    CONSTANT VARCHAR2(15) := 'UN_NUMBER_ID';     -- 機種番号ID
  gv_tkn_errmsg          CONSTANT VARCHAR2(15) := 'ERRMSG';           -- SQLERRM対応
  gv_tkn_func_name       CONSTANT VARCHAR2(15) := 'FUNC_NAME';        -- 処理名
--ADD_Ver.1.8_2009/12/24_START----------------------------------------------------------------------------
  gv_tkn_prof            CONSTANT VARCHAR2(15) := 'PROF_NAME';       -- プロファイル名
--ADD_Ver.1.8_2009/12/24_END------------------------------------------------------------------------------
--
  --プロファイル
  gv_set_of_bks_id   CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID'; -- 会計帳簿ID
  gv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- 組織ID
  gv_conc_request_id CONSTANT VARCHAR2(30) := 'CONC_REQUEST_ID';  -- 要求ID
  gv_lookup_type     CONSTANT VARCHAR2(100) := 'XXCFO1_SEARCH_LONG_TEXT';  -- 長い文書検索文字列
--ADD_Ver.1.8_2009/12/24_START----------------------------------------------------------------------------
  cv_report_title    CONSTANT VARCHAR2(30) := 'XXCFO1_REPORT_TITLE'; --XXCFO:帳票用敬称
--ADD_Ver.1.8_2009/12/24_END------------------------------------------------------------------------------
--
--
  --===============================================================
  -- グローバル変数
  --===============================================================
  gn_set_of_bks_id             NUMBER;                                     -- 会計帳簿ID
  gn_org_id                    NUMBER;                                     -- 組織ID
  gn_conc_request_id           NUMBER;                                     -- 要求ID
  gt_account_number            hz_cust_accounts.account_number%TYPE;       -- 顧客コード
  gv_referral_comp             VARCHAR2(2000);                             -- 紹介会社
  gt_long_text                 fnd_documents_long_text.long_text%TYPE;     -- 長い文書
  gt_party_name                hz_parties.party_name%TYPE;                 -- 顧客名
  gt_un_number                 po_un_numbers_tl.un_number%TYPE;            -- 機種番号
  gn_po_num_in_count           NUMBER;                                     -- ステータス管理テーブルへの発注番号登録件数
  gn_rep_standard_po_cnt       NUMBER;                                     -- 標準発注書作成用帳票ワークテーブル登録件数
  gt_no_data_msg               xxcfo_rep_standard_po.data_empty_message%TYPE;
                                                                           -- 0件メッセージ
--ADD_Ver.1.8_2009/12/24_START----------------------------------------------------------------------------
  gv_report_title              VARCHAR2(10);                               -- XXCFO:帳票用敬称取得
--ADD_Ver.1.8_2009/12/24_END------------------------------------------------------------------------------
--
  --===============================================================
  -- グローバルテーブルタイプ
  --===============================================================
  TYPE g_po_num_ttype           IS TABLE OF xxcfo_po_status_mng.po_num%TYPE        INDEX BY PLS_INTEGER;
  TYPE g_org_id_ttype           IS TABLE OF xxcfo_po_status_mng.org_id%TYPE        INDEX BY PLS_INTEGER;
  TYPE g_search_long_text_ttype IS TABLE OF fnd_lookup_values.meaning%TYPE         INDEX BY PLS_INTEGER;
--
  --===============================================================
  -- グローバルテーブル
  --===============================================================
  gt_po_num                 g_po_num_ttype;
  gt_org_id                 g_org_id_ttype;
  gt_search_long_text       g_search_long_text_ttype;     -- 長い文書検索文字
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
          ,pha.revision_num                       revision_num               -- 改訂番号
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
--MOD_Ver.1.8_2009/12/24_START----------------------------------------------------------------------------
--          ,l_xla.location_short_name              location_short_name        -- 納入先事業所
          ,l_xla.location_name                    location_name              -- 納入先事業所
--MOD_Ver.1.8_2009/12/24_END------------------------------------------------------------------------------
          ,l_xla.division_code                    deliver_division_code      -- 納入先事本部コード
          ,pvsa.phone                             vendor_phone               -- 仕入先電話番号
          ,pvsa.fax                               vendor_fax                 -- 仕入先FAX番号
          ,pvsa.area_code                         area_code                  -- 仕入先電話エリアコード
          ,pvsa.fax_area_code                     fax_area_code              -- 仕入先FAXエリアコード
          ,pvsa.pay_on_code                       pay_on_code                -- 自己請求-支払日
          ,pvsa.attribute1                        vendor_name                -- 仕入先名
          ,pr.requisition_num                     requisition_num            -- 購買依頼番号
          ,pr.requisition_line_id                 requisition_line_id        -- 購買依頼明細ID
--MOD_Ver.1.5_2009/03/23_START------------------------------------------------------------------------------
--          ,pr.un_number_id                        un_number_id               -- 機種ID
          ,pla.un_number_id                       un_number_id               -- 機種ID
--MOD_Ver.1.5_2009/03/23_END--------------------------------------------------------------------------------
          ,pr.location_short_name                 apply_location_short_name  -- 申請拠点
          ,pr.division_code                       apply_division_code        -- 申請拠点本部コード
          ,pha.org_id                             org_id                     -- 組織ID
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
                  ,xla.division_code            division_code                       -- 申請拠点本部コード
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
--DEL_Ver.1.9_2010/01/19_START------------------------------------------------------------------------------
--               AND papf2.current_employee_flag  = gv_flag_y
--DEL_Ver.1.9_2010/01/19_END------------------------------------------------------------------------------
--ADD_Ver.1.9_2010/01/19_START------------------------------------------------------------------------------
               AND TRUNC( SYSDATE ) BETWEEN TRUNC( papf2.effective_start_date )
                                        AND TRUNC( papf2.effective_end_date ) 
--ADD_Ver.1.9_2010/01/19_END------------------------------------------------------------------------------
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
--DEL_Ver.1.9_2010/01/19_START------------------------------------------------------------------------------
--       AND papf1.current_employee_flag =  gv_flag_y
--DEL_Ver.1.9_2010/01/19_END------------------------------------------------------------------------------
--ADD_Ver.1.9_2010/01/19_START------------------------------------------------------------------------------
               AND TRUNC( SYSDATE ) BETWEEN TRUNC( papf1.effective_start_date )
                                        AND TRUNC( papf1.effective_end_date ) 
--ADD_Ver.1.9_2010/01/19_END------------------------------------------------------------------------------
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
            (    iv_reissue_flag = gv_reissue_flag_1
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
    ln_cnt  NUMBER :=0;     -- カーソル件数取得用
--
    -- *** ローカル・カーソル ***
--
    -- 長い文書検索文字列取得
    CURSOR long_text_cur IS
    SELECT flv.meaning            meaning
      FROM fnd_lookup_values      flv
     WHERE flv.lookup_type            = gv_lookup_type
       AND flv.language               = USERENV('LANG')
       AND flv.enabled_flag           = gv_flag_y
       AND (   flv.start_date_active IS NULL
            OR flv.start_date_active <= TRUNC( SYSDATE ))
       AND (   flv.end_date_active   IS NULL
            OR flv.end_date_active   >= TRUNC( SYSDATE ))
       AND flv.lookup_code           IN (gv_lookup_code_100, gv_lookup_code_110)
     ORDER BY flv.lookup_code ASC;
    -- *** ローカル・レコード ***
--
  l_xxcfo_long_text_rec    long_text_cur%ROWTYPE;
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
--ADD_Ver.1.8_2009/12/24_START----------------------------------------------------------------------------
    -- プロファイルからXXCFO:帳票用敬称取得
    gv_report_title := FND_PROFILE.VALUE( cv_report_title );
    -- 取得エラー時
    IF ( gv_report_title IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( gv_msg_kbn_cfo    -- アプリケーション短縮名：XXCFO
                                                    ,gv_msg_cfo_00001  -- プロファイル取得エラー
                                                    ,gv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_report_title ))
                                                                       -- XXCFO:帳票用敬称
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--ADD_Ver.1.8_2009/12/24_END------------------------------------------------------------------------------
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
    -- 長い文書検索文字の取得
    -- カーソルオープン
    OPEN long_text_cur;
    LOOP
      FETCH long_text_cur INTO l_xxcfo_long_text_rec;
      EXIT WHEN long_text_cur%NOTFOUND;
--
      ln_cnt := ln_cnt + 1;
      gt_search_long_text(ln_cnt) := l_xxcfo_long_text_rec.meaning;
--
    END LOOP;
    -- カーソルクローズ
    IF po_data_cur%ISOPEN THEN
      CLOSE long_text_cur;
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
      -- カーソルクローズ
      IF po_data_cur%ISOPEN THEN
        CLOSE long_text_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF po_data_cur%ISOPEN THEN
        CLOSE long_text_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF po_data_cur%ISOPEN THEN
        CLOSE long_text_cur;
      END IF;
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
    gt_account_number := xxcfo_common_pkg.get_special_info_item(
                                            gt_long_text                   -- 長い文書
                                           ,gt_search_long_text(1));       -- 検索対象文字列（設置先_顧客コード=）
--
    IF (gt_account_number IS NULL) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo                      -- アプリケーション短縮名：XXCFO
                                                     ,gv_msg_cfo_00013                    -- 添付情報文字列検索エラー
                                                     ,gv_tkn_search_string                -- トークン'SEARCH_STRING'
                                                     ,gt_search_long_text(1)              -- 検索対象文字列
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
    gv_referral_comp := xxcfo_common_pkg.get_special_info_item(
                                            gt_long_text                   -- 長い文書
                                           ,gt_search_long_text(2));       -- 検索対象文字列（紹介会社=）
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
      INTO gt_party_name
      FROM hz_parties           hp,     -- パーティマスタ
           hz_cust_accounts     hca     -- 顧客マスタ
     WHERE hp.party_id        = hca.party_id
       AND hca.account_number = gt_account_number;
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
   * Procedure Name   : insert_rep_standard_po
   * Description      : ワークテーブルデータ登録 (A-8)
   ***********************************************************************************/
  PROCEDURE insert_rep_standard_po(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_rep_standard_po'; -- プログラム名
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
    cv_table CONSTANT VARCHAR2(100) := 'XXCFO_REP_STANDARD_PO'; -- 標準発注書作成用帳票ワークテーブル
--
    -- *** ローカル変数 ***
--ADD_Ver.1.7_2009/07/03_START------------------------------------------------------------------------------
    lt_po_zip                g_xxcfo_po_data_rec.po_zip%TYPE;   -- 発注担当者_郵便番号編集用
--ADD_Ver.1.7_2009/07/03_END--------------------------------------------------------------------------------
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
--ADD_Ver.1.7_2009/07/03_START------------------------------------------------------------------------------
    -- 郵便番号が未設定か8桁設定されていた場合
    IF NVL( LENGTHB( g_xxcfo_po_data_rec.po_zip ) ,0 ) IN ( '0' ,'8' ) THEN
      lt_po_zip := g_xxcfo_po_data_rec.po_zip;
    ELSE
      lt_po_zip := SUBSTRB( g_xxcfo_po_data_rec.po_zip ,1 ,3 ) ||
                   '-' ||
                   SUBSTRB( g_xxcfo_po_data_rec.po_zip ,4 ,4 );
    END IF;
--ADD_Ver.1.7_2009/07/03_END--------------------------------------------------------------------------------
    -- =====================================================
    --  ワークテーブルデータ登録 (A-8)
    -- =====================================================
    INSERT INTO xxcfo_rep_standard_po (
       vendor_name                    -- 仕入先名
      ,vendor_phone                   -- 仕入先_電話番号
      ,vendor_fax                     -- 仕入先_FAX番号
      ,area_code                      -- 仕入先_電話エリアコード
      ,fax_area_code                  -- 仕入先_FAXエリアコード
      ,po_num                         -- 発注番号
      ,revision_num                   -- 改訂番号
      ,po_agent_dept_name             -- 発注担当者_所属部署名
      ,address_line1                  -- 発注担当者_住所
      ,zip                            -- 発注担当者_郵便番号
      ,phone                          -- 発注担当者_電話番号
      ,fax                            -- 発注担当者_FAX
      ,apply_location_name            -- 申請拠点名
      ,deliver_location_name          -- 納品場所名
      ,vendor_product_num             -- 発注商品
      ,unit_price                     -- 単価
      ,quantity                       -- 数量
      ,unit_meas_lookup_code          -- 単位
      ,promised_date                  -- 納期
      ,remarks                        -- 備考
      ,requisition_num                -- 購買依頼番号
      ,apply_division_code            -- 申請拠点本部コード
      ,deliver_division_code          -- 納入先本部コード
      ,pay_on_code                    -- 自己請求-支払日
      ,org_id                         -- 組織ID
      ,data_empty_message             -- 0件メッセージ
      ,created_by                     -- 作成者
      ,created_date                   -- 作成日
      ,last_updated_by                -- 最終更新者
      ,last_updated_date              -- 最終更新日
      ,last_update_login              -- 最終更新ログイン
      ,request_id                     -- 要求ID
      ,program_application_id         -- コンカレント・プログラム・アプリケーションID
      ,program_id                     -- コンカレント・プログラムID
      ,program_update_date            -- プログラム更新日
    )
    VALUES ( 
--MOD_Ver.1.8_2009/12/24_START----------------------------------------------------------------------------
--       g_xxcfo_po_data_rec.vendor_name
       g_xxcfo_po_data_rec.vendor_name || gv_report_title
--MOD_Ver.1.8_2009/12/24_END------------------------------------------------------------------------------
      ,g_xxcfo_po_data_rec.vendor_phone
      ,g_xxcfo_po_data_rec.vendor_fax
      ,g_xxcfo_po_data_rec.area_code
      ,g_xxcfo_po_data_rec.fax_area_code
      ,g_xxcfo_po_data_rec.po_num
      ,g_xxcfo_po_data_rec.revision_num
      ,g_xxcfo_po_data_rec.po_location_name
      ,g_xxcfo_po_data_rec.po_address_line1
--MOD_Ver.1.7_2009/07/03_START------------------------------------------------------------------------------
--      ,g_xxcfo_po_data_rec.po_zip
      ,lt_po_zip
--MOD_Ver.1.7_2009/07/03_END--------------------------------------------------------------------------------
      ,g_xxcfo_po_data_rec.po_phone
      ,g_xxcfo_po_data_rec.po_fax
      ,g_xxcfo_po_data_rec.apply_location_short_name
      ,DECODE(g_xxcfo_po_data_rec.attache_judge_code, gv_judge_code_10
                                                  , SUBSTRB( gt_party_name ,1 ,240 )            -- 納品場所名
--MOD_Ver.1.8_2009/12/24_START----------------------------------------------------------------------------                                                  
--                                                  , g_xxcfo_po_data_rec.location_short_name)
                                                  , g_xxcfo_po_data_rec.location_name)
--MOD_Ver.1.8_2009/12/24_END------------------------------------------------------------------------------
      ,DECODE(g_xxcfo_po_data_rec.attache_judge_code, gv_judge_code_10, gt_un_number            -- 発注商品
                                                  , g_xxcfo_po_data_rec.vendor_product_num)
      ,g_xxcfo_po_data_rec.unit_price
      ,g_xxcfo_po_data_rec.quantity_ordered
      ,g_xxcfo_po_data_rec.unit_meas_lookup_code
      ,g_xxcfo_po_data_rec.promised_date
      ,gv_referral_comp
      ,g_xxcfo_po_data_rec.requisition_num
      ,g_xxcfo_po_data_rec.apply_division_code
      ,g_xxcfo_po_data_rec.deliver_division_code
      ,g_xxcfo_po_data_rec.pay_on_code
      ,gn_org_id
      ,NULL
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
                                                                           -- 標準発注書作成用帳票ワークテーブル
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
--
    ELSE
      --登録件数取得
      gn_rep_standard_po_cnt := gn_rep_standard_po_cnt + 1;
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
  END insert_rep_standard_po;
--
  /**********************************************************************************
   * Procedure Name   : insert_po_status_mng
   * Description      : ステータス管理テーブルデータ登録 (A-9)
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
    cv_table CONSTANT VARCHAR2(100) := 'XXCFO_PO_STATUS_MNG'; -- 発注書出力ステータス管理テーブル
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
    --  ステータス管理テーブルデータ登録 (A-9)
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
   * Procedure Name   : no_data_msg
   * Description      : 0件出力メッセージ (A-10)
   ***********************************************************************************/
  PROCEDURE no_data_msg(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'no_data_msg'; -- プログラム名
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
    lv_retcode := xxccp_svfcommon_pkg.no_data_msg;
--
    IF (lv_retcode <> cv_status_normal) THEN
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo               -- アプリケーション短縮名：XXCFO
                                                     ,gv_msg_cfo_00009             -- 共通関数エラー
                                                     ,gv_tkn_func_name             -- トークン'FUNC_NAME'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        gv_msg_kbn_cfo
                                                       ,gt_lookup_code_016A01001
                                                      )                            -- 「SVF帳票共通関数(0件出力メッセージ)」
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END no_data_msg;
--
  /**********************************************************************************
   * Procedure Name   : insert_rep_standard_po_0
   * Description      : ワークテーブルデータ登録（明細0件用） (A-11)
   ***********************************************************************************/
  PROCEDURE insert_rep_standard_po_0(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_rep_standard_po_0'; -- プログラム名
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
    cv_table       CONSTANT VARCHAR2(100) := 'XXCFO_REP_STANDARD_PO'; -- 標準発注書作成用帳票ワークテーブル
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
    -- ====================================================
    -- 帳票０件メッセージ取得
    -- ====================================================
    gt_no_data_msg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo    -- 'XXCFO'
                                                        ,gv_msg_cfo_00008  -- 明細0件用メッセージ
                                                       )
                              ,1
                              ,5000);
    -- =====================================================
    --  ワークテーブルデータ登録（明細0件用） (A-11)
    -- =====================================================
    INSERT INTO xxcfo_rep_standard_po (
       vendor_name                    -- 仕入先名
      ,vendor_phone                   -- 仕入先_電話番号
      ,vendor_fax                     -- 仕入先_FAX番号
      ,area_code                      -- 仕入先_電話エリアコード
      ,fax_area_code                  -- 仕入先_FAXエリアコード
      ,po_num                         -- 発注番号
      ,revision_num                   -- 改訂番号
      ,po_agent_dept_name             -- 発注担当者_所属部署名
      ,address_line1                  -- 発注担当者_住所
      ,zip                            -- 発注担当者_郵便番号
      ,phone                          -- 発注担当者_電話番号
      ,fax                            -- 発注担当者_FAX
      ,apply_location_name            -- 申請拠点名
      ,deliver_location_name          -- 納品場所名
      ,vendor_product_num             -- 発注商品
      ,unit_price                     -- 単価
      ,quantity                       -- 数量
      ,unit_meas_lookup_code          -- 単位
      ,promised_date                  -- 納期
      ,remarks                        -- 備考
      ,requisition_num                -- 購買依頼番号
      ,apply_division_code            -- 申請拠点本部コード
      ,deliver_division_code          -- 納入先本部コード
      ,pay_on_code                    -- 自己請求-支払日
      ,org_id                         -- 組織ID
      ,data_empty_message             -- 0件メッセージ
      ,created_by                     -- 作成者
      ,created_date                   -- 作成日
      ,last_updated_by                -- 最終更新者
      ,last_updated_date              -- 最終更新日
      ,last_update_login              -- 最終更新ログイン
      ,request_id                     -- 要求ID
      ,program_application_id         -- コンカレント・プログラム・アプリケーションID
      ,program_id                     -- コンカレント・プログラムID
      ,program_update_date            -- プログラム更新日
    )
    VALUES (
       NULL                           -- 仕入先名
      ,NULL                           -- 仕入先_電話番号
      ,NULL                           -- 仕入先_FAX番号
      ,NULL                           -- 仕入先_電話エリアコード
      ,NULL                           -- 仕入先_FAXエリアコード
      ,NULL                           -- 発注番号
      ,NULL                           -- 改訂番号
      ,NULL                           -- 発注担当者_所属部署名
      ,NULL                           -- 発注担当者_住所
      ,NULL                           -- 発注担当者_郵便番号
      ,NULL                           -- 発注担当者_電話番号
      ,NULL                           -- 発注担当者_FAX
      ,NULL                           -- 申請拠点名
      ,NULL                           -- 納品場所名
      ,NULL                           -- 発注商品
      ,NULL                           -- 単価
      ,NULL                           -- 数量
      ,NULL                           -- 単位
      ,NULL                           -- 納期
      ,NULL                           -- 備考
      ,NULL                           -- 購買依頼番号
      ,NULL                           -- 申請拠点本部コード
      ,NULL                           -- 納入先本部コード
      ,NULL                           -- 自己請求-支払日
      ,gn_org_id                      -- 組織ID
      ,gt_no_data_msg                 -- 0件メッセージ
      ,cn_created_by                  -- 作成者
      ,cd_creation_date               -- 作成日
      ,cn_last_updated_by             -- 最終更新者
      ,cd_last_update_date            -- 最終更新日
      ,cn_last_update_login           -- 最終更新ログイン
      ,gn_conc_request_id             -- 要求ID
      ,cn_program_application_id      -- コンカレント・プログラム・アプリケーションID
      ,cn_program_id                  -- コンカレント・プログラムID
      ,cd_program_update_date         -- プログラム更新日
    );
--
    IF (SQL%ROWCOUNT = 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo       -- 'XXCFO'
                                                     ,gv_msg_cfo_00035     -- データ挿入エラー
                                                     ,gv_tkn_table         -- トークン'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                           -- 標準発注書作成用帳票ワークテーブル
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
--
    ELSE
      --登録件数取得
      gn_rep_standard_po_cnt := gn_rep_standard_po_cnt + 1;
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
  END insert_rep_standard_po_0;
--
  /**********************************************************************************
   * Procedure Name   : act_svf
   * Description      : SVF起動処理 (A-12)
   ***********************************************************************************/
  PROCEDURE act_svf(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'act_svf'; -- プログラム名
    cv_output_mode    CONSTANT VARCHAR2(1)   := '1';  -- 出力区分(=1：PDF出力）
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
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCFO016A01S.xml';  -- フォーム様式ファイル名
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCFO016A01S.vrq';  -- クエリー様式ファイル名
    cv_language_ja    CONSTANT  fnd_concurrent_programs_tl.language%TYPE := 'JA' ;
    cv_extension_pdf  CONSTANT  VARCHAR2(4)  := '.pdf';  -- 拡張子（pdf）
--
    -- *** ローカル変数 ***
--MOD_Ver.1.6_2009/04/14_START------------------------------------------------------------------------------
--    lv_svf_file_name   VARCHAR2(30);
    lv_svf_file_name   VARCHAR2(100);
--MOD_Ver.1.6_2009/04/14_END------------------------------------------------------------------------------
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
    lv_svf_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
    -- ファイル名の設定
    lv_svf_file_name := gv_pkg_name
                     || TO_CHAR ( cd_creation_date, gv_format_date_ymd )
                     || TO_CHAR ( cn_request_id )
                     || cv_extension_pdf;
--
    -- コンカレント名の設定
      lv_conc_name := gv_pkg_name;
--
    -- ファイル名の設定
      lv_file_id := gv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
     ov_errbuf       => lv_errbuf            -- エラー・メッセージ           --# 固定 #
    ,ov_retcode      => lv_retcode           -- リターン・コード             --# 固定 #
    ,ov_errmsg       => lv_svf_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    ,iv_conc_name    => lv_conc_name         -- コンカレント名
    ,iv_file_name    => lv_svf_file_name     -- 出力ファイル名
    ,iv_file_id      => lv_file_id           -- 帳票ID
    ,iv_output_mode  => cv_output_mode       -- 出力区分(=1：PDF出力）
    ,iv_frm_file     => cv_svf_form_name     -- フォーム様式ファイル名
    ,iv_vrq_file     => cv_svf_query_name    -- クエリー様式ファイル名
    ,iv_org_id       => gn_org_id            -- ORG_ID
    ,iv_user_name    => lv_user_name         -- ログイン・ユーザ名
    ,iv_resp_name    => lv_resp_name         -- ログイン・ユーザの職責名
    ,iv_doc_name     => NULL                 -- 文書名
    ,iv_printer_name => NULL                 -- プリンタ名
    ,iv_request_id   => cn_request_id        -- 要求ID
    ,iv_nodata_msg   => NULL                 -- データなしメッセージ
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo      -- アプリケーション短縮名：XXCFO
                                                     ,gv_msg_cfo_00009    -- 共通関数エラーメッセージ
                                                     ,gv_tkn_func_name    -- トークン'FUNC_NAME'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                      gv_msg_kbn_cfo
                                                      ,gt_lookup_code_016A01002
                                                      )                   -- 「'SVF帳票共通関数(SVFコンカレントの起動)'」
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf := SUBSTRB( lv_errmsg ||cv_msg_part|| lv_errbuf ||cv_msg_part|| lv_svf_errmsg
                           ,1
                           ,5000
                           );
      RAISE global_api_expt;
--
    ELSE
      gn_normal_cnt := gn_target_cnt;
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
  END act_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_rep_standard_po
   * Description      : ワークテーブルデータ削除 (A-13)
   ***********************************************************************************/
  PROCEDURE delete_rep_standard_po(
    ov_errbuf     OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rep_standard_po'; -- プログラム名
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
    cv_table            CONSTANT VARCHAR2(100) := 'XXCFO_REP_STANDARD_PO'; -- 標準発注書作成用帳票ワークテーブル
    ln_del_count        NUMBER := 0;  -- 削除件数
--
    -- *** ローカル・カーソル ***
    -- テーブルロックカーソル
    CURSOR del_table_d_cur
    IS
    SELECT 'X'
      FROM xxcfo_rep_standard_po    xrsp
     WHERE xrsp.request_id = gn_conc_request_id
    FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
--
  xxcfo_del_rec    del_table_d_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- カーソルオープン
    OPEN del_table_d_cur;
--
    BEGIN
      --対象データを削除
      DELETE FROM xxcfo_rep_standard_po  xrsp
      WHERE xrsp.request_id = gn_conc_request_id;
--
      ln_del_count := SQL%ROWCOUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo     -- アプリケーション短縮名：XXCFO
                                                       ,gv_msg_cfo_00025   -- データ削除エラー
                                                       ,gv_tkn_table       -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                           -- 標準発注書作成用帳票ワークテーブル
                                                       ,gv_tkn_errmsg      -- トークン'ERRMSG'
                                                       ,SQLERRM            -- SQLエラーメッセージ
                                                      )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- カーソルクローズ
    IF po_data_cur%ISOPEN THEN
      CLOSE del_table_d_cur;
    END IF;
--
    IF (ln_del_count = 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo     -- アプリケーション短縮名：XXCFO
                                                     ,gv_msg_cfo_00025   -- データ削除エラー
                                                     ,gv_tkn_table       -- トークン'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                         -- 標準発注書作成用帳票ワークテーブル
                                                     ,gv_tkn_errmsg      -- トークン'ERRMSG'
                                                     ,SQLERRM            -- SQLエラーメッセージ
                                                    )
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- テーブルロックエラー
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo        -- 'XXCFO'
                                                     ,gv_msg_cfo_00019      -- テーブルロックエラー
                                                     ,gv_tkn_table          -- トークン'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                    )                       -- 標準発注書作成用帳票ワークテーブル
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF po_data_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF po_data_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF po_data_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF po_data_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END delete_rep_standard_po;
--
  /**********************************************************************************
   * Procedure Name   : delete_po_status_mng
   * Description      : ステータス管理テーブルデータ削除 (A-14)
   ***********************************************************************************/
  PROCEDURE delete_po_status_mng(
    ov_errbuf       OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_po_status_mng'; -- プログラム名
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
    cv_table   CONSTANT VARCHAR2(100) := 'XXCFO_PO_STATUS_MNG'; -- 発注書出力ステータス管理テーブル
--
    -- *** ローカル変数 ***
    ln_po_num_in_count  NUMBER := 1;  -- インクリメント変数
    ln_del_count        NUMBER := 0;  -- 削除件数
--
    -- *** ローカル・カーソル ***
    -- テーブルロックカーソル
    CURSOR del_table_d_cur(in_po_num_in_count IN NUMBER)
    IS
      SELECT xpsm.po_num     po_num      -- 発注番号
        FROM xxcfo_po_status_mng    xpsm
       WHERE xpsm.po_num = gt_po_num(in_po_num_in_count)
         AND xpsm.org_id = gt_org_id(in_po_num_in_count)
      FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
--
    l_xxcfo_del_rec    del_table_d_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    LOOP
      FOR l_xxcfo_del_rec IN del_table_d_cur(ln_po_num_in_count) LOOP
        --対象データを削除
        DELETE FROM xxcfo_po_status_mng  xpsm
        WHERE  CURRENT OF del_table_d_cur;
--
        ln_del_count := SQL%ROWCOUNT;
        -- エラー処理
        IF (ln_del_count = 0) THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo     -- アプリケーション短縮名：XXCFO
                                                         ,gv_msg_cfo_00025   -- データ削除エラー
                                                         ,gv_tkn_table       -- トークン'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                             -- 発注書データ出力ワークテーブル
                                                         ,gv_tkn_errmsg      -- トークン'ERRMSG'
                                                         ,SQLERRM            -- SQLエラーメッセージ
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
        END IF;
--
        ln_po_num_in_count := ln_po_num_in_count + 1;
      END LOOP;
--
      -- 登録件数を超えた場合に終了する
      IF (ln_po_num_in_count > gn_po_num_in_count) THEN
        EXIT;
      END IF;
--
    END LOOP;
--
    -- ループ対象データを取得できなかった場合のエラー処理
    IF (ln_del_count = 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo     -- アプリケーション短縮名：XXCFO
                                                     ,gv_msg_cfo_00025   -- データ削除エラー
                                                     ,gv_tkn_table       -- トークン'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                         -- 発注書データ出力ワークテーブル
                                                     ,gv_tkn_errmsg      -- トークン'ERRMSG'
                                                     ,SQLERRM            -- SQLエラーメッセージ
                                                    )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- テーブルロックエラー
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo        -- 'XXCFO'
                                                     ,gv_msg_cfo_00019      -- テーブルロックエラー
                                                     ,gv_tkn_table          -- トークン'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                    )                       -- ステータス管理テーブル
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
      IF del_table_d_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      IF del_table_d_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF del_table_d_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF del_table_d_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END delete_po_status_mng;
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
    lv_retcode2               VARCHAR2(1);                      -- リターン・コード
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
    gn_rep_standard_po_cnt := 0;     -- 標準発注書作成用帳票ワークテーブルへ未登録
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
       iv_po_creation_date_from      -- 発注作成日From
      ,iv_po_creation_date_to        -- 発注作成日To
      ,iv_po_approved_date_from      -- 発注承認日From
      ,iv_po_approved_date_to        -- 発注承認日To
      ,lv_errbuf                     -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                    -- リターン・コード             --# 固定 #
      ,lv_errmsg);                   -- ユーザー・エラー・メッセージ --# 固定 #
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
    ln_po_agent_code         := TO_NUMBER(iv_po_agent_code);                      -- 発注作成者
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
      -- 添付情報判定コードが10（自販機の場合）
      IF   (g_xxcfo_po_data_rec.attache_judge_code = gv_judge_code_10) THEN
--
        -- =====================================================
        --  添付情報取得処理(A-4)
        -- =====================================================
        get_attache_info(
           lv_errbuf                               -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                              -- リターン・コード             --# 固定 #
          ,lv_errmsg);                             -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合は「ステータス管理テーブルデータ削除」から処理を開始
        IF (lv_retcode != cv_status_error) THEN
--
          -- =====================================================
          --  添付情報編集処理(A-5)
          -- =====================================================
          edit_attache_info(
             lv_errbuf                               -- エラー・メッセージ           --# 固定 #
            ,lv_retcode                              -- リターン・コード             --# 固定 #
            ,lv_errmsg);                             -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- エラーの場合は「ステータス管理テーブルデータ削除」から処理を開始
          IF (lv_retcode != cv_status_error) THEN
--
            -- =====================================================
            --  顧客情報取得処理(A-6)
            -- =====================================================
            get_customer_info(
               lv_errbuf                               -- エラー・メッセージ           --# 固定 #
              ,lv_retcode                              -- リターン・コード             --# 固定 #
              ,lv_errmsg);                             -- ユーザー・エラー・メッセージ --# 固定 #
--
            -- エラーの場合は「ステータス管理テーブルデータ削除」から処理を開始
            IF (lv_retcode != cv_status_error) THEN
--
              -- =====================================================
              --  機種情報取得処理(A-7)
              -- =====================================================
              get_un_info(
                 lv_errbuf                             -- エラー・メッセージ           --# 固定 #
                ,lv_retcode                            -- リターン・コード             --# 固定 #
                ,lv_errmsg);                           -- ユーザー・エラー・メッセージ --# 固定 #
--
            END IF;
          END IF;
        END IF;
      END IF;
--
      -- エラーの場合は「ステータス管理テーブルデータ削除」から処理を開始
      IF (lv_retcode != cv_status_error) THEN
--
        -- =====================================================
        --  ワークテーブルデータ登録(A-8)
        -- =====================================================
        insert_rep_standard_po(
           lv_errbuf                           -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                          -- リターン・コード             --# 固定 #
          ,lv_errmsg);                         -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合は「ステータス管理テーブルデータ削除」から処理を開始
        IF (lv_retcode != cv_status_error) THEN
--
          -- =====================================================
          --  ステータス管理テーブルデータ登録(A-9)
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
              -- 登録できた場合、発注番号・組織IDを保持する。
              IF (lv_retcode != cv_status_error) THEN
                gn_po_num_in_count            := gn_po_num_in_count + 1;
                gt_po_num(gn_po_num_in_count) := lt_po_num;
                gt_org_id(gn_po_num_in_count) := lt_org_id;
--
              END IF;
--
            END IF;
          END IF;
        END IF;
      END IF;
--
      IF (lv_retcode = cv_status_error) THEN
        EXIT;
      END IF;
--
    END LOOP;
--
    IF po_data_cur%ISOPEN THEN
      CLOSE po_data_cur;
    END IF;
--
    -- エラーの場合は「ステータス管理テーブルデータ削除」から処理を開始
    IF (lv_retcode != cv_status_error) THEN
--
      IF (gn_target_cnt = 0) THEN
        -- =====================================================
        --  0件出力メッセージ(A-10)
        -- =====================================================
        no_data_msg(
           lv_errbuf                           -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                          -- リターン・コード             --# 固定 #
          ,lv_errmsg);                         -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合は「ステータス管理テーブルデータ削除」から処理を開始
        IF (lv_retcode != cv_status_error) THEN
--
          -- =====================================================
          --  ワークテーブルデータ登録（明細0件用）(A-11)
          -- =====================================================
          insert_rep_standard_po_0(
             lv_errbuf                           -- エラー・メッセージ           --# 固定 #
            ,lv_retcode                          -- リターン・コード             --# 固定 #
            ,lv_errmsg);                         -- ユーザー・エラー・メッセージ --# 固定 #
--
        END IF;
--
      END IF;
--
      -- エラーの場合は「ステータス管理テーブルデータ削除」から処理を開始
      IF (lv_retcode != cv_status_error) THEN
        -- =====================================================
        --  SVF起動処理(A-12)
        -- =====================================================
        act_svf(
           lv_errbuf                           -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                          -- リターン・コード             --# 固定 #
          ,lv_errmsg);                         -- ユーザー・エラー・メッセージ --# 固定 #
--
      END IF;
--
    END IF;
--
    -- 標準発注書作成用帳票ワークテーブルに1件以上登録されていた場合
    IF (gn_rep_standard_po_cnt >= 1) THEN
      -- =====================================================
      --  ワークテーブルデータ削除(A-13)
      -- =====================================================
      lv_retcode2 := lv_retcode;
      lv_errmsg2  := lv_errmsg;
      lv_errbuf2  := lv_errbuf;
--
      delete_rep_standard_po(
         lv_errbuf                           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                          -- リターン・コード             --# 固定 #
        ,lv_errmsg);                         -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーで削除処理を行う場合COMMITが必要となる
      COMMIT;
--
      -- メッセージを連結
      lv_errmsg := lv_errmsg2 || lv_errmsg;
      lv_errbuf := lv_errbuf2 || lv_errbuf;
      IF (lv_retcode2 = cv_status_error) THEN
        lv_retcode := cv_status_error;
      END IF;
--
    END IF;
--
    -- 警告終了
    IF (gn_target_cnt = 0 AND
        lv_retcode != cv_status_error ) THEN
      lv_retcode := cv_status_warn;
      lv_errmsg  := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo     -- アプリケーション短縮名：XXCFO
                                                      ,gv_msg_cfo_00004   -- 対象データ無しエラー
                                                     )
                            ,1
                            ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
    END IF;
--
    -- 新規・エラー・ステータス管理テーブルに登録済みの場合、削除する。
    IF (  iv_reissue_flag     = gv_reissue_flag_0
      AND lv_retcode          = cv_status_error
      AND gn_po_num_in_count != 0)
    THEN
      -- =====================================================
      --  ステータス管理テーブルデータ削除(A-14)
      -- =====================================================
      lv_retcode2 := lv_retcode;
      lv_errmsg2  := lv_errmsg;
      lv_errbuf2  := lv_errbuf;
--
      delete_po_status_mng(
         lv_errbuf                           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                          -- リターン・コード             --# 固定 #
        ,lv_errmsg );                        -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーで削除処理を行う場合COMMITが必要となる
      COMMIT;
--
      -- メッセージを連結
      lv_errmsg := lv_errmsg2 || lv_errmsg;
      lv_errbuf := lv_errbuf2 || lv_errbuf;
      IF (lv_retcode2 = cv_status_error) THEN
        lv_retcode := cv_status_error;
      END IF;
--
      --(エラー処理)
      RAISE global_process_expt;
--
    END IF;
--
    -- エラーでA-14の処理に入らない場合
    IF (lv_retcode = cv_status_error) THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
--
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
    --  終了処理(A-15)
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
END XXCFO016A01C;
/
