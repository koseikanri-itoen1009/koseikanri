CREATE OR REPLACE PACKAGE BODY xxpo870003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo870003c(body)
 * Description      : 発注単価洗替処理
 * MD.050           : 仕入単価／標準原価マスタ登録 Issue1.0  T_MD050_BPO_870
 * MD.070           : 仕入単価／標準原価マスタ登録 Issue1.0  T_MD070_BPO_870
 * Version          : 1.5
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                       Description
 * --------------------------- ----------------------------------------------------------
 *  func_chk_item_no            品目番号の存在チェック
 *  func_chk_customer           取引先の存在チェック
 *  func_create_sql             SQLの生成
 *  proc_put_process_result     処理結果出力
 *  proc_upd_price_headers_flg  仕入/標準単価ヘッダの変更処理フラグを更新
 *  proc_put_po_log             処理済発注明細情報出力
 *  proc_upd_lot_data           ロット在庫単価更新
 *  proc_upd_po_data            発注明細の更新
 *  proc_calc_data              計算処理
 *  proc_get_unit_price         仕入単価データ取得
 *  proc_get_lot_data           ロットデータ取得
 *  proc_get_po_data            発注明細データ取得
 *  proc_check_param            パラメータチェック
 *  proc_put_parameter_log      前処理(入力パラメータログ出力処理)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/10    1.0   Y.Ishikawa       新規作成
 *  2008/05/01    1.1   Y.Ishikawa       発注明細、発注納入明細、ロットマスタの単価設定を
 *                                       粉引額→粉引単価に修正
 *  2008/05/07    1.2   Y.Ishikawa       トレースの指摘にて、品目チェック時に
 *                                       MTL_SYSTEM_ITEMS_Bの参照を削除
 *  2008/05/09    1.3   Y.Ishikawa       mainの起動時間出力にて、日付のフォーマットを
 *                                       'YYYY/MM/DD HH:MM:SS'→'YYYY/MM/DD HH24:MI:SS'に変更
 *  2008/06/03    1.4   Y.Ishikawa       仕入単価マスタ複数発注更新時に１件のみしか更新されない
 *                                       不具合対応
 *  2008/06/03    1.5   Y.Ishikawa       仕入単価マスタの支給先コードが登録されていない場合は
 *                                       条件に含めない。
 *                                       粉引後単価がNULLの場合は、0として計算する。
 *
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
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
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
  global_user_expt       EXCEPTION;        -- ユーザーにて定義をした例外
  lock_expt              EXCEPTION;        -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxpo870003c';    -- パッケージ名
  -- モジュール名略称
  gv_xxcmn            CONSTANT VARCHAR2(100) := 'XXCMN';        -- モジュール名略称：XXCMN 共通
  gv_xxpo             CONSTANT VARCHAR2(100) := 'XXPO';         -- モジュール名略称：XXPO 販売
--
  ------------------------------
  -- 品目カテゴリ関連
  ------------------------------
  gv_cat_set_goods_class        CONSTANT VARCHAR2(100) := '商品区分' ;      -- 商品区分
  gv_cat_set_item_class         CONSTANT VARCHAR2(100) := '品目区分' ;      -- 品目区分
--
  -- クイックコード名
  gv_xxcmn_date_type  CONSTANT VARCHAR2(100) := 'XXCMN_UNIT_PRICE_DERIVING_DAY'; -- 仕入単価導出日
--
  -- メッセージ
  gv_msg_xxpo30036    CONSTANT VARCHAR2(100) := 'APP-XXPO-30036';  --  入力パラメータメッセージ
  gv_msg_xxpo10102    CONSTANT VARCHAR2(100) := 'APP-XXPO-10102';  --  入力パラメータ必須チェック
  gv_msg_xxpo10103    CONSTANT VARCHAR2(100) := 'APP-XXPO-10103';  --  入力パラメータ存在チェック
  gv_msg_xxpo10104    CONSTANT VARCHAR2(100) := 'APP-XXPO-10104';  --  入力パラメータ日付チェック
  gv_msg_xxpo10105    CONSTANT VARCHAR2(100) := 'APP-XXPO-10105';  --  入力パラメータ比較チェック
  gv_msg_xxpo30032    CONSTANT VARCHAR2(100) := 'APP-XXPO-30032';  --  処理済出力ログ
  gv_msg_xxpo30033    CONSTANT VARCHAR2(100) := 'APP-XXPO-30033';  --  抽出件数出力ログ
  gv_msg_xxpo30031    CONSTANT VARCHAR2(100) := 'APP-XXPO-30031';  --  洗替件数出力ログ
  gv_msg_xxpo30029    CONSTANT VARCHAR2(100) := 'APP-XXPO-30029';  --  未仕入単価出力ログ
  gv_msg_xxpo30030    CONSTANT VARCHAR2(100) := 'APP-XXPO-30030';  --  未処理出力ログ
  gv_msg_xxpo10093    CONSTANT VARCHAR2(100) := 'APP-XXPO-10093';  --  発注未取得エラー
  gv_msg_xxcmn10018   CONSTANT VARCHAR2(100) := 'APP-XXCMN-10018'; --  APIエラー
  gv_msg_xxcmn10019   CONSTANT VARCHAR2(100) := 'APP-XXCMN-10019'; --  ロックエラー
--
  -- トークン
  gv_tkn_data_type          CONSTANT VARCHAR2(100) := 'DATE_TYPE';      -- 日付タイプ
  gv_tkn_date_from          CONSTANT VARCHAR2(100) := 'DATE_FROM';      -- 開始日
  gv_tkn_data_to            CONSTANT VARCHAR2(100) := 'DATE_TO';        -- 終了日
  gv_tkn_item_no            CONSTANT VARCHAR2(100) := 'ITEM_NO';        -- 品目
  gv_tkn_vendor_code        CONSTANT VARCHAR2(100) := 'VENDOR_CODE';    -- 取引先
  gv_tkn_item_category      CONSTANT VARCHAR2(100) := 'ITEM_CATEGORY';  -- 品目区分
  gv_tkn_goods_category     CONSTANT VARCHAR2(100) := 'GOODS_CATEGORY'; -- 商品区分
  gv_tkn_param_name         CONSTANT VARCHAR2(100) := 'PARAM_NAME';     -- パラメータ名
  gv_tkn_param_value        CONSTANT VARCHAR2(100) := 'PARAM_VALUE';    -- パラメータ値
  gv_tkn_target_count       CONSTANT VARCHAR2(100) := 'TARGET_COUNT';   -- 発注明細条件合致件数
  gv_tkn_count              CONSTANT VARCHAR2(100) := 'COUNT';          -- 洗替件数
  gv_tkn_h_no               CONSTANT VARCHAR2(100) := 'H_NO';           -- 発注番号
  gv_tkn_m_no               CONSTANT VARCHAR2(100) := 'M_NO';           -- 発注明細番号
  gv_tkn_nonyu_date         CONSTANT VARCHAR2(100) := 'NONYU_DATE';     -- 納入日
  gv_tkn_ng_h_no            CONSTANT VARCHAR2(100) := 'NG_H_NO';        -- NG発注番号
  gv_tkn_ng_m_no            CONSTANT VARCHAR2(100) := 'NG_M_NO';        -- NG発注明細番号
  gv_tkn_ng_item_no         CONSTANT VARCHAR2(100) := 'NG_ITEM_NO';     -- NG品目
  gv_tkn_ng_nonyu_date      CONSTANT VARCHAR2(100) := 'NG_NONYU_DATE';  -- NG納入日
  gv_tkn_ng_count           CONSTANT VARCHAR2(100) := 'NG_COUNT';       -- NG件数
  gv_tkn_api_name           CONSTANT VARCHAR2(100) := 'API_NAME';       -- API名
  gv_tkn_table              CONSTANT VARCHAR2(100) := 'TABLE';          -- テーブル
  gv_tkn_ng_profile         CONSTANT VARCHAR2(100) := 'NG_PROFILE';     -- NG_PROFILE
--
  gv_tkn_val_date_type      CONSTANT VARCHAR2(100) := '日付タイプ';
  gv_tkn_val_start_date     CONSTANT VARCHAR2(100) := '期間開始';
  gv_tkn_val_end_date       CONSTANT VARCHAR2(100) := '期間終了';
  gv_tkn_val_commodity_type CONSTANT VARCHAR2(100) := '商品区分';
  gv_tkn_val_item_type      CONSTANT VARCHAR2(100) := '品目区分';
  gv_tkn_val_item           CONSTANT VARCHAR2(100) := '品目';
  gv_tkn_val_customer       CONSTANT VARCHAR2(100) := '取引先';
--
  -- ロックテーブル名
  gv_po_line                CONSTANT VARCHAR2(100) := '発注明細';
  gv_po_location            CONSTANT VARCHAR2(100) := '発注納入明細';
  gv_lot_mst                CONSTANT VARCHAR2(100) := 'OPMロットマスタ';
  gv_price_headers          CONSTANT VARCHAR2(100) := '仕入/標準単価ヘッダ';
--
  -- 日付フォーマット
  gv_format_yyyymmdd        CONSTANT VARCHAR2(100) := 'YYYY/MM/DD';     -- YYYY/MM/DD
  gv_format_yyyymm          CONSTANT VARCHAR2(100) := 'YYYY/MM';        -- YYYYMM
  gv_dt_format              CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';
--
  -- YES/NO
  gv_y                      CONSTANT VARCHAR2(1) := 'Y';
  gv_n                      CONSTANT VARCHAR2(1) := 'N';
--
  -- 日付タイプ
  gv_mgc_day                CONSTANT VARCHAR2(1) := '1';   -- 製造日
  gv_deliver_day            CONSTANT VARCHAR2(1) := '2';   -- 納入日
--
  -- 直送区分
  gv_provision              CONSTANT VARCHAR2(1) := '3';   -- 支給
--
-- 計算処理
  gn_100                    CONSTANT NUMBER(3)   := 100;   -- 100
--
-- 口銭区分
  gv_rate                   CONSTANT VARCHAR2(1) := '2';   -- 率
--
-- 発注ステータス
  gv_po_stats               CONSTANT VARCHAR2(2) := '25';   -- 受入あり
--
-- 発注変更API
  gv_version                CONSTANT VARCHAR2(8) := '1.0'; -- バージョン
  gn_zero                   CONSTANT NUMBER      := 0;     -- 0エラー
--
-- 計算フラグ
  gn_depo_flg               NUMBER;                       -- 預り口銭金額計算フラグ
  gn_cane_flg               NUMBER;                       -- 賦課金額計算フラグ
--
  -- WHOカラム
  gn_user_id    po_lines_all.last_updated_by%TYPE   DEFAULT FND_GLOBAL.USER_ID;         -- ﾕｰｻﾞｰID
  gd_sysdate    po_lines_all.last_update_date%TYPE  DEFAULT SYSDATE;                    -- ｼｽﾃﾑ日
  gn_login_id   po_lines_all.last_update_login%TYPE DEFAULT FND_GLOBAL.LOGIN_ID;        -- ﾛｸﾞｲﾝID
  gn_request_id po_lines_all.request_id%TYPE        DEFAULT FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
  gn_appl_id    po_lines_all.program_application_id%TYPE DEFAULT FND_GLOBAL.PROG_APPL_ID; -- APID
  gn_program_id po_lines_all.program_id%TYPE        DEFAULT FND_GLOBAL.CONC_PROGRAM_ID;   -- PGID
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 発注情報データ
  TYPE get_rec_type IS RECORD (
    status               po_headers_all.attribute1%TYPE,              -- ステータス
    vendor_id            po_headers_all.vendor_id%TYPE,               -- 仕入先ID
    delivery_code        po_headers_all.attribute7%TYPE,              -- 配送先コード
    direct_sending_type  po_headers_all.attribute6%TYPE,              -- 直送区分
    delivery_day         po_headers_all.attribute4%TYPE,              -- 納入日
    po_no                po_headers_all.segment1%TYPE,                -- 発注番号
    revision_num         po_headers_all.revision_num%TYPE,            -- バージョン
    po_line_id           po_lines_all.po_line_id%TYPE,                -- 発注明細ID
    po_l_no              po_lines_all.line_num%TYPE,                  -- 発注明細番号
    lot_no               po_lines_all.attribute1%TYPE,                -- ロット番号
    po_quantity          po_lines_all.attribute11%TYPE,               -- 発注数量
    rcv_quantity         po_lines_all.attribute7%TYPE,                -- 受入数量
    fact_code            po_lines_all.attribute2%TYPE,                -- 工場コード
    accompany_code       po_lines_all.attribute3%TYPE,                -- 付帯コード
    base_uom             po_lines_all.unit_meas_lookup_code%TYPE,     -- 発注基準単位
    po_uom               po_lines_all.attribute10%TYPE,               -- 発注単位
    line_location_id     po_line_locations_all.line_location_id%TYPE, -- 納入明細番号
    shipment_num         po_line_locations_all.shipment_num%TYPE,     -- 納入明細番号
    powde_lead           po_line_locations_all.attribute1%TYPE,       -- 粉引率
    commission_type      po_line_locations_all.attribute3%TYPE,       -- 口銭区分
    commission           po_line_locations_all.attribute4%TYPE,       -- 口銭
    assessment_type      po_line_locations_all.attribute6%TYPE,       -- 賦課金区分
    assessment           po_line_locations_all.attribute7%TYPE,       -- 賦課金
    num_of_cases         xxcmn_item_mst_v.num_of_cases%TYPE,          -- ケース入数
    conv_unit            xxcmn_item_mst_v.conv_unit%TYPE,             -- 入出庫換算単位
    item_id              xxcmn_item_mst_v.item_id%TYPE,               -- 品目ID
    item_no              xxcmn_item_mst_v.item_no%TYPE,               -- 品目番号
    cost_manage_code     xxcmn_item_mst_v.cost_manage_code%TYPE       -- 原価管理区分
    );
--
  --ロット情報
  TYPE get_rec_lot IS RECORD (
    lot_id               ic_lots_mst.lot_id%TYPE,                     -- ロットID
    lot_desc             ic_lots_mst.lot_desc%TYPE,                   -- ロット摘要
    qc_grade             ic_lots_mst.qc_grade%TYPE,                   -- グレード
    expaction_code       ic_lots_mst.expaction_code%TYPE,             -- 処理コード
    expaction_date       ic_lots_mst.expaction_date%TYPE,             -- 失効日付
    lot_created          ic_lots_mst.lot_created%TYPE,                -- ロット作成日
    expire_date          ic_lots_mst.expire_date%TYPE,                -- 期限日
    retest_date          ic_lots_mst.retest_date%TYPE,                -- 再テスト日
    strength             ic_lots_mst.strength%TYPE,                   -- 強度
    inactive_ind         ic_lots_mst.inactive_ind%TYPE,               -- 有効フラグ
    shipvend_id          ic_lots_mst.shipvend_id%TYPE,                -- 仕入先ID
    vendor_lot_no        ic_lots_mst.vendor_lot_no%TYPE,              -- 仕入ロットNO
    create_day           ic_lots_mst.attribute1%TYPE,                 -- 製造年月日
    attribute2           ic_lots_mst.attribute2%TYPE,                 -- 固有記号
    attribute3           ic_lots_mst.attribute3%TYPE,                 -- 賞味期限
    attribute4           ic_lots_mst.attribute4%TYPE,                 -- 納入日（初回）
    attribute5           ic_lots_mst.attribute5%TYPE,                 -- 納入日（最終）
    attribute6           ic_lots_mst.attribute6%TYPE,                 -- 在庫入数
    attribute7           ic_lots_mst.attribute7%TYPE,                 -- 在庫単価
    attribute8           ic_lots_mst.attribute8%TYPE,                 -- 取引先
    attribute9           ic_lots_mst.attribute9%TYPE,                 -- 仕入形態
    attribute10          ic_lots_mst.attribute10%TYPE,                -- 茶期区分
    attribute11          ic_lots_mst.attribute11%TYPE,                -- 年度
    attribute12          ic_lots_mst.attribute12%TYPE,                -- 産地
    attribute13          ic_lots_mst.attribute13%TYPE,                -- タイプ
    attribute14          ic_lots_mst.attribute14%TYPE,                -- ランク１
    attribute15          ic_lots_mst.attribute15%TYPE,                -- ランク２
    attribute16          ic_lots_mst.attribute16%TYPE,                -- 生産伝票区分
    attribute17          ic_lots_mst.attribute17%TYPE,                -- ライン№
    attribute18          ic_lots_mst.attribute18%TYPE,                -- 摘要
    attribute19          ic_lots_mst.attribute19%TYPE,                -- ランク３
    attribute20          ic_lots_mst.attribute20%TYPE,                -- 原料製造工場
    attribute21          ic_lots_mst.attribute21%TYPE,                -- 原料製造元ロット番号
    attribute22          ic_lots_mst.attribute22%TYPE,                -- 検査依頼No
    attribute23          ic_lots_mst.attribute23%TYPE,                -- DFF23
    attribute24          ic_lots_mst.attribute24%TYPE,                -- DFF24
    attribute25          ic_lots_mst.attribute25%TYPE,                -- DFF25
    attribute26          ic_lots_mst.attribute26%TYPE,                -- DFF26
    attribute27          ic_lots_mst.attribute27%TYPE,                -- DFF27
    attribute28          ic_lots_mst.attribute28%TYPE,                -- DFF28
    attribute29          ic_lots_mst.attribute29%TYPE,                -- DFF29
    attribute30          ic_lots_mst.attribute30%TYPE,                -- DFF30
    attribute_category   ic_lots_mst.attribute_category%TYPE,         -- DFF23
    ic_hold_date         ic_lots_cpg.ic_hold_date%TYPE                -- 保持日
    );
--
  -- 入力パラメータ
  TYPE gt_item_no    IS TABLE OF xxcmn_item_mst_v.item_no%TYPE INDEX BY BINARY_INTEGER;
  TYPE gt_vender_cd  IS TABLE OF xxcmn_vendors_v.segment1%TYPE INDEX BY BINARY_INTEGER;
  TYPE gt_item_id    IS TABLE OF mtl_system_items_b.inventory_item_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE gt_vender_id  IS TABLE OF xxcmn_vendors_v.vendor_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- 仕入単価ヘッダーID
  TYPE gt_p_header_id IS TABLE OF xxpo_price_headers.price_header_id%TYPE INDEX BY BINARY_INTEGER;
--
  TYPE g_rec_item IS RECORD(
    item_no            gt_item_no,     -- 品目コード
    item_id            gt_item_id      -- 品目ID
  );
--
  TYPE g_rec_vender IS RECORD(
    vender_code        gt_vender_cd,   -- 仕入先コード
    vender_id          gt_vender_id    -- 仕入先ID
  );
--
  -- 発注情報データ
  TYPE get_po_tbl IS TABLE OF get_rec_type INDEX BY BINARY_INTEGER;
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN句の内容を返します。(g_rec_item)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      l_rec_item IN g_rec_item
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_in_statement' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_in          VARCHAR2(1000) ;
--
  BEGIN
--
    <<item_loop>>
    FOR i IN 1..l_rec_item.item_id.COUNT LOOP
      lv_in := lv_in || TO_CHAR(l_rec_item.item_id(i)) || ',';
    END LOOP item_loop;
--
    RETURN(
      SUBSTR(lv_in,1,LENGTH(lv_in) - 1));
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  固定部 END   #########################################
--
  END fnc_get_in_statement;
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN句の内容を返します。(g_rec_vender)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      l_rec_vender IN g_rec_vender
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_in_statement' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_in          VARCHAR2(1000) ;
--
  BEGIN
--
    <<vender_loop>>
    FOR i IN 1..l_rec_vender.vender_id.COUNT LOOP
      lv_in := lv_in || TO_CHAR(l_rec_vender.vender_id(i)) || ',';
    END LOOP vender_loop;
--
    RETURN(
      SUBSTR(lv_in,1,LENGTH(lv_in) - 1));
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  固定部 END   #########################################
--
  END fnc_get_in_statement;
--
  /**********************************************************************************
   * Function Name    : func_chk_item_no
   * Description      : 品目番号の存在チェック
   ***********************************************************************************/
  FUNCTION func_chk_item_no(
    iv_item_no         IN     VARCHAR2)   -- 品目番号
  RETURN NUMBER                          -- (戻値) 品目ID
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'func_chk_item_no'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    ln_item_id  xxcmn_item_mst_v.inventory_item_id%TYPE DEFAULT NULL;        -- 品目ID
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    -- ==============================================================
    -- OPM品目マスタチェック
    -- ==============================================================
    BEGIN
      SELECT ximv.inventory_item_id item_id
      INTO   ln_item_id
      FROM   xxcmn_item_mst_v    ximv      -- OPM品目情報VIEW
      WHERE  ximv.item_no   = iv_item_no
      AND    ROWNUM         = 1;
    EXCEPTION
    -- データがない場合はエラー
      WHEN NO_DATA_FOUND THEN
            --リターン
        ln_item_id := NULL;
      -- その他エラー
      WHEN OTHERS THEN
        RAISE;
    END;
--
    --リターン
    RETURN ln_item_id;
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  固定部 END   #########################################
  END func_chk_item_no;
--
--
  /**********************************************************************************
   * Function Name    : func_chk_customer
   * Description      : 取引先の存在チェック
   ***********************************************************************************/
  FUNCTION func_chk_customer(
    iv_customer_code   IN     VARCHAR2)   -- 仕入先番号
  RETURN NUMBER                           -- (戻値) 仕入先ID
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'func_chk_customer'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    ln_vendor_id  xxcmn_vendors_v.vendor_id%TYPE DEFAULT NULL;       -- 仕入先ID
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    -- ==============================================================
    -- 仕入先マスタチェック
    -- ==============================================================
    BEGIN
      SELECT xvv.vendor_id vendor_id
      INTO   ln_vendor_id
      FROM   xxcmn_vendors_v xvv           -- 仕入先情報VIEW
      WHERE  xvv.segment1 = iv_customer_code
      AND    ROWNUM      = 1;
    EXCEPTION
    -- データがない場合はエラー
      WHEN NO_DATA_FOUND THEN
        ln_vendor_id := NULL;
      -- その他エラー
      WHEN OTHERS THEN
        RAISE;
    END;
--
    --リターン
    RETURN ln_vendor_id;
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  固定部 END   #########################################
  END func_chk_customer;
--
--
  /**********************************************************************************
   * Function Name    : func_create_sql
   * Description      : SQLの生成
   ***********************************************************************************/
  FUNCTION func_create_sql(
    iv_date_type        IN  VARCHAR2,      -- 日付タイプ(1:製造日 2:納入日)
    iv_start_date       IN  VARCHAR2,      -- 期間開始日(YYYY/MM/DD)
    iv_end_date         IN  VARCHAR2,      -- 期間終了日(YYYY/MM/DD)
    iv_goods_type_name  IN  VARCHAR2,      -- 商品区分名
    iv_item_type_name   IN  VARCHAR2,      -- 品目区分名
    ir_item             IN  g_rec_item,    -- 品目情報
    ir_vender           IN  g_rec_vender)  -- 取引先情報
  RETURN VARCHAR2                          -- (戻値) SQL文
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'func_create_sql'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_select_sql CONSTANT VARCHAR2(32767) :=
      ' SELECT  pha.attribute1            AS  status'                -- ステータス
          || ' ,pha.vendor_id             AS  vendor_id'             -- 仕入先ID
          || ' ,pha.attribute7            AS  delivery_code'         -- 配送先コード
          || ' ,pha.attribute6            AS  direct_sending_type'   -- 直送区分
          || ' ,pha.attribute4            AS  delivery_day'          -- 納入日
          || ' ,pha.segment1              AS  po_no'                 -- 発注番号
          || ' ,pha.revision_num          AS  revision_num'          -- バージョン
          || ' ,pla.po_line_id            AS  po_line_id'            -- 発注明細ID
          || ' ,pla.line_num              AS  po_l_no'               -- 発注明細番号
          || ' ,pla.attribute1            AS  lot_no'                -- ロット番号
          || ' ,pla.attribute11           AS  po_quantity'           -- 発注数量
          || ' ,pla.attribute7            AS  rcv_quantity'          -- 受入数量
          || ' ,pla.attribute2            AS  fact_code'             -- 工場コード
          || ' ,pla.attribute3            AS  accompany_code'        -- 付帯コード
          || ' ,pla.unit_meas_lookup_code AS  base_uom'              -- 発注単位
          || ' ,pla.attribute10           AS  po_uom'                -- 発注単位
          || ' ,plla.line_location_id     AS  line_location_id'      -- 納入明細ID
          || ' ,plla.shipment_num         AS  shipment_num'          -- 納入明細番号
          || ' ,NVL(plla.attribute1,'|| '''0''' || ')  AS  powde_lead' -- 粉引率
          || ' ,plla.attribute3           AS  commission_type'       -- 口銭区分
          || ' ,plla.attribute4           AS  commission'            -- 口銭
          || ' ,plla.attribute6           AS  assessment_type'       -- 賦課金区分
          || ' ,plla.attribute7           AS  assessment'            -- 賦課金
          || ' ,ximv.num_of_cases         AS  num_of_cases'          -- ケース入数
          || ' ,ximv.conv_unit            AS  conv_unit'             -- 入出庫換算単位
          || ' ,ximv.item_id              AS  item_id'               -- 品目ID
          || ' ,ximv.item_no              AS  item_no'               -- 品目番号
          || ' ,ximv.cost_manage_code     AS  cost_manage_code';     -- 原価管理区分
--
    cv_po_ok       CONSTANT VARCHAR2(10) := '20';                 -- 発注作成済
    cv_quantity_ok CONSTANT VARCHAR2(10) := '30';                 -- 数量確定済
    cv_no          CONSTANT VARCHAR2(10) := 'N';                  -- N
    cv_one         CONSTANT VARCHAR2(10) := '01';                 -- 01日
--
    -- *** ローカル変数 ***
    lv_close_date        VARCHAR2(10)    DEFAULT NULL;            -- 会計クローズ日
    lv_from_where_sql    VARCHAR2(32767) DEFAULT NULL;            -- WHERE句用SQL
    lv_and_sql1          VARCHAR2(32767) DEFAULT NULL;            -- AND句用SQL
    lv_and_sql2          VARCHAR2(32767) DEFAULT NULL;            -- AND句用SQL
    lv_and_sql3          VARCHAR2(32767) DEFAULT NULL;            -- AND句用SQL
    lv_and_sql4          VARCHAR2(32767) DEFAULT NULL;            -- AND句用SQL
    lv_sql               VARCHAR2(32767) DEFAULT NULL;            -- SQL
    lv_in                VARCHAR2(1000)  DEFAULT NULL;            -- IN句
    -- *** ローカル・レコード ***
    -- *** ローカル・カーソル ***
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    -- 会計クローズの取得
    lv_close_date := TO_CHAR(FND_DATE.STRING_TO_DATE(xxcmn_common_pkg.get_opminv_close_period
                             || cv_one,gv_format_yyyymmdd),gv_format_yyyymmdd);
    -- ===============================
    -- AND句作成
    -- ===============================
    -- 日付タイプ条件SQL生成
    IF (iv_date_type = gv_deliver_day) THEN
      -- 日付タイプが納入日の場合
      lv_and_sql2 := ' AND pha.attribute4 BETWEEN ' || '''' || iv_start_date || ''''
                  || ' AND ' || '''' || iv_end_date || '''';
    END IF;
--
    -- 品目条件SQL生成
    IF (ir_item.item_id.COUNT = 1) THEN
      -- 1件のみ
      lv_and_sql3 := ' AND pla.item_id = ' || TO_CHAR(ir_item.item_id(1));
    ELSIF (ir_item.item_id.COUNT > 0) THEN
      -- 1件以上
      lv_in := fnc_get_in_statement(ir_item);
      lv_and_sql3 := ' AND pla.item_id IN('|| lv_in || ') ';
    ELSE
      NULL;
    END IF;
--
    -- 取引先条件SQL生成
    IF (ir_vender.vender_id.COUNT = 1) THEN
      -- 1件のみ
      lv_and_sql4 := ' AND pha.vendor_id = ' || TO_CHAR(ir_vender.vender_id(1));
    ELSIF (ir_vender.vender_id.COUNT > 0) THEN
      -- 1件以上
      lv_in := fnc_get_in_statement(ir_vender);
      lv_and_sql4 := ' AND pha.vendor_id IN('|| lv_in || ') ';
    ELSE
      NULL;
    END IF;
--
    -- ===============================
    -- WHERE句作成
    -- ===============================
    lv_from_where_sql :=
      ' FROM   po_headers_all         pha'                    -- 発注ヘッダ
      ||     ' ,po_lines_all          pla'                    -- 発注明細
      ||     ' ,po_line_locations_all plla'                   -- 発注納入明細
      ||     ' ,xxcmn_item_mst_v      ximv'                   -- OPM品目情報VIEW
      ||     ' WHERE  pha.attribute4 > ' || '''' || lv_close_date || ''''; -- 納入日
--
    -- 取引先がパラメータに入力されていた場合条件追加
    IF (lv_and_sql4 IS NOT NULL) THEN
      lv_from_where_sql := lv_from_where_sql || lv_and_sql4;
    END IF;
--
    -- 日付タイプが納入日の場合条件追加
    IF (lv_and_sql2 IS NOT NULL) THEN
      lv_from_where_sql := lv_from_where_sql || lv_and_sql2;
    END IF;
--
    lv_from_where_sql := lv_from_where_sql
      ||     ' AND pha.attribute1 BETWEEN ' || ''''|| cv_po_ok || ''''
      ||     ' AND ' || ''''||    cv_quantity_ok   || ''''              -- ステータス
      ||     ' AND pha.po_header_id  = pla.po_header_id ';              -- 発注ヘッダID
--
    -- 品目がパラメータに入力されていた場合条件追加
    IF (lv_and_sql3 IS NOT NULL) THEN
      lv_from_where_sql := lv_from_where_sql || lv_and_sql3;
    END IF;
--
    lv_from_where_sql := lv_from_where_sql
      ||     ' AND pla.attribute14              = ' || ''''|| cv_no || ''''    -- 金額確定フラグ
      ||     ' AND pla.po_header_id             = plla.po_header_id'           -- 発注ヘッダID
      ||     ' AND pla.po_line_id               = plla.po_line_id'             -- 発注明細ID
      ||     ' AND pla.item_id                  = ximv.inventory_item_id'      -- 品目ID
      ||     ' AND xxcmn_common_pkg.get_category_desc(ximv.item_no,'
      ||     ''''|| gv_cat_set_item_class || '''' || ')  = ' || '''' || iv_item_type_name || ''''
      ||     ' AND xxcmn_common_pkg.get_category_desc(ximv.item_no,'
      ||     ''''|| gv_cat_set_goods_class || '''' || ') = ' || '''' || iv_goods_type_name || ''''
      ||     ' AND ximv.unit_price_calc_code      = ' || '''' || iv_date_type || ''''
      ||     ' FOR UPDATE OF pla.po_line_id,plla.line_location_id NOWAIT';
--
--
    -- SQL文の結合
    lv_sql := lv_select_sql || lv_from_where_sql;
--
    --リターン
    RETURN lv_sql;
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  固定部 END   #########################################
  END func_create_sql;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_put_process_result
   * Description      : 処理結果出力(C-11)
   ***********************************************************************************/
  PROCEDURE proc_put_process_result(
    ov_errbuf          OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_put_process_result'; -- プログラム名
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
    lv_out_msg       VARCHAR2(5000);
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 指定パラメータの条件に合致した発注明細件数出力
    -- ===============================
    lv_out_msg := SUBSTRB(xxcmn_common_pkg.get_msg(
                    iv_application  => gv_xxpo,
                    iv_name         => gv_msg_xxpo30033,
                    iv_token_name1  => gv_tkn_target_count,
                    iv_token_value1 => TO_CHAR(gn_target_cnt)
                  ),1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    -- ===============================
    -- 単価を更新した件数出力
    -- ===============================
    lv_out_msg := SUBSTRB(xxcmn_common_pkg.get_msg(
                    iv_application  => gv_xxpo,
                    iv_name         => gv_msg_xxpo30031,
                    iv_token_name1  => gv_tkn_count,
                    iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  ),1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    -- ===============================
    -- 仕入単価データを取得できなかった発注明細の件数出力
    -- ===============================
    lv_out_msg := SUBSTRB(xxcmn_common_pkg.get_msg(
                    iv_application  => gv_xxpo,
                    iv_name         => gv_msg_xxpo30029,
                    iv_token_name1  => gv_tkn_ng_count,
                    iv_token_value1 => TO_CHAR(gn_warn_cnt)
                  ),1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_put_process_result;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_price_headers_flg
   * Description      : 仕入/標準単価ヘッダの変更処理フラグを更新(C-10)
   ***********************************************************************************/
  PROCEDURE proc_upd_price_headers_flg(
    in_price_header_id IN  xxcmn_vendors_v.vendor_id%TYPE, -- ヘッダID
    ov_errbuf          OUT VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_price_headers_flg'; -- プログラム名
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
    ln_result             NUMBER;                            -- API関数戻り値
    ltbl_api_errors       PO_API_ERRORS_REC_TYPE;            -- APIエラー戻り値
    lv_out_msg            VARCHAR2(2000);                    -- ログメッセージ
--
    -- *** ローカル・カーソル ***
    -- <カーソル名>
--
    -- *** ローカル・レコード ***
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
--
    -- ===============================
    -- 仕入/標準単価ヘッダの更新
    -- ===============================
    UPDATE xxpo_price_headers xpha                             -- 仕入/標準単価ヘッダ
    SET    xpha.record_change_flg      = gv_n                  -- 変更処理フラグ
          ,xpha.last_updated_by        = gn_user_id            -- 最終更新者
          ,xpha.last_update_date       = gd_sysdate            -- 最終更新日
          ,xpha.last_update_login      = gn_login_id           -- 最終更新ログイン
          ,xpha.request_id             = gn_request_id         -- 要求ID
          ,xpha.program_application_id = gn_appl_id            -- ｱﾌﾟﾘｹｰｼｮﾝID
          ,xpha.program_id             = gn_program_id         -- プログラムID
          ,xpha.program_update_date    = gd_sysdate            -- プログラム更新日
    WHERE xpha.price_header_id         = in_price_header_id    -- ヘッダID
    ;
--
--
  EXCEPTION
--
    WHEN global_user_expt THEN   --*** ユーザー定義例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_upd_price_headers_flg;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_put_po_log
   * Description      : 処理済発注明細情報出力(C-9)
   ***********************************************************************************/
  PROCEDURE proc_put_po_log(
    iv_msg_no          IN  VARCHAR2,      -- メッセージ番号
    iv_tkn_itm_no      IN  VARCHAR2,      -- トークン品目
    iv_tkn_h_no        IN  VARCHAR2,      -- トークン発注番号
    iv_tkn_m_no        IN  VARCHAR2,      -- トークン発注明細
    iv_tkn_nonyu_date  IN  VARCHAR2,      -- トークン納入日
    iv_po_no           IN  VARCHAR2,      -- 発注番号
    iv_po_l_no         IN  VARCHAR2,      -- 明細番号
    iv_item_no         IN  VARCHAR2,      -- 品目番号
    iv_delivery_day    IN  VARCHAR2,      -- 納入番号
    ov_errbuf          OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_put_po_log'; -- プログラム名
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
    lv_2space CONSTANT VARCHAR2(2) := '  ';   -- 2スペース
--
    -- *** ローカル変数 ***
    lv_out_msg       VARCHAR2(5000);
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 発注情報出力
    -- ===============================iv_delivery_day
    lv_out_msg := SUBSTRB(xxcmn_common_pkg.get_msg(
                    iv_application  => gv_xxpo,
                    iv_name         => iv_msg_no,
                    iv_token_name1  => iv_tkn_h_no,
                    iv_token_value1 => iv_po_no,
                    iv_token_name2  => iv_tkn_m_no,
                    iv_token_value2 => iv_po_l_no,
                    iv_token_name3  => iv_tkn_itm_no,
                    iv_token_value3 => iv_item_no,
                    iv_token_name4  => iv_tkn_nonyu_date,
                    iv_token_value4 => iv_delivery_day
                  ),1,5000);
--
    -- 未処理発注明細情報出力の場合は、メッセージの頭にスペース付与
    IF (iv_msg_no = gv_msg_xxpo30030) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_2space || lv_out_msg);
--
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
    END IF;
--
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_put_po_log;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_lot_data
   * Description      : ロット在庫単価更新(C-8)
   ***********************************************************************************/
  PROCEDURE proc_upd_lot_data(
    ir_po_data         IN  get_rec_type,  -- 発注明細情報
    ir_lot_data        IN  get_rec_lot,   -- ロット情報
    in_cohi_unit_price IN  NUMBER,        -- 粉引後単価
    in_total_amount    IN  NUMBER,        -- 内訳合計
    in_depo_commission IN  NUMBER,        -- 預り口銭金額
    in_cane            IN  NUMBER,        -- 賦課金額
    in_cohi_rest       IN  NUMBER,        -- 粉引後金額
    ov_errbuf          OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_lot_data'; -- プログラム名
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
    cv_api_name  CONSTANT VARCHAR2(100) := 'GMI_LOTUPDATE_PUB.UPDATE_LOT'; --ロット変更API
    cv_jisei              VARCHAR2(1)   := '0';                            -- 実勢(0)
--
    -- *** ローカル変数 ***
    lv_result             VARCHAR2(1);                       -- API関数戻り値(終了ステータス)
    ln_msg_cnt            NUMBER;                            -- API関数戻り値(スタック数)
    lv_msg                VARCHAR2(2000);                    -- API関数戻り値(メッセージ)
    l_lot_mst_rec         ic_lots_mst%ROWTYPE;               -- ロットマスタレコードタイプ
    l_lot_cpg_rec         ic_lots_cpg%ROWTYPE;               -- ロット期間レコードタイプ
    lv_out_msg            VARCHAR2(2000);                    -- ログメッセージ
--
    -- *** ローカル・カーソル ***
    -- <カーソル名>
--
    -- *** ローカル・レコード ***
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
--
   -- 原価管理区分が実勢の場合のみロット更新
   IF (ir_po_data.cost_manage_code = cv_jisei) AND (ir_lot_data.lot_id IS NOT NULL) THEN
--
     -- ロットマスタレコードセット
     l_lot_mst_rec.item_id            := ir_po_data.item_id;           -- 品目ID
     l_lot_mst_rec.lot_id             := ir_lot_data.lot_id;           -- ロットID
     l_lot_mst_rec.lot_desc           := ir_lot_data.lot_desc;         -- ロット摘要
     l_lot_mst_rec.qc_grade           := ir_lot_data.qc_grade;         -- グレード
     l_lot_mst_rec.expaction_code     := ir_lot_data.expaction_code;   -- 処理コード
     l_lot_mst_rec.expaction_date     := ir_lot_data.expaction_date;   -- 失効日付
     l_lot_mst_rec.lot_created        := ir_lot_data.lot_created;      -- ロット作成日
     l_lot_mst_rec.expire_date        := ir_lot_data.expire_date;      -- 期限日
     l_lot_mst_rec.retest_date        := ir_lot_data.retest_date;      -- 再テスト日
     l_lot_mst_rec.strength           := ir_lot_data.strength;         -- 強度
     l_lot_mst_rec.inactive_ind       := ir_lot_data.inactive_ind;     -- 有効フラグ
     l_lot_mst_rec.shipvend_id        := ir_lot_data.shipvend_id;      -- 仕入先ID
     l_lot_mst_rec.vendor_lot_no      := ir_lot_data.vendor_lot_no;    -- 仕入ロットNO
     l_lot_mst_rec.attribute1         := ir_lot_data.create_day;       -- 製造年月日
     l_lot_mst_rec.attribute2         := ir_lot_data.attribute2;       -- 固有記号
     l_lot_mst_rec.attribute3         := ir_lot_data.attribute3;       -- 賞味期限
     l_lot_mst_rec.attribute4         := ir_lot_data.attribute4;       -- 納入日（初回）
     l_lot_mst_rec.attribute5         := ir_lot_data.attribute5;       -- 納入日（最終）
     l_lot_mst_rec.attribute6         := ir_lot_data.attribute6;       -- 在庫入数
     l_lot_mst_rec.attribute7         := in_cohi_unit_price;           -- 在庫単価
     l_lot_mst_rec.attribute8         := ir_lot_data.attribute8;       -- 取引先
     l_lot_mst_rec.attribute9         := ir_lot_data.attribute9;       -- 仕入形態
     l_lot_mst_rec.attribute10        := ir_lot_data.attribute10;      -- 茶期区分
     l_lot_mst_rec.attribute11        := ir_lot_data.attribute11;      -- 年度
     l_lot_mst_rec.attribute12        := ir_lot_data.attribute12;      -- 産地
     l_lot_mst_rec.attribute13        := ir_lot_data.attribute13;      -- タイプ
     l_lot_mst_rec.attribute14        := ir_lot_data.attribute14;      -- ランク１
     l_lot_mst_rec.attribute15        := ir_lot_data.attribute15;      -- ランク２
     l_lot_mst_rec.attribute16        := ir_lot_data.attribute16;      -- 生産伝票区分
     l_lot_mst_rec.attribute17        := ir_lot_data.attribute17;      -- ライン№
     l_lot_mst_rec.attribute18        := ir_lot_data.attribute18;      -- 摘要
     l_lot_mst_rec.attribute19        := ir_lot_data.attribute19;      -- ランク３
     l_lot_mst_rec.attribute20        := ir_lot_data.attribute20;      -- 原料製造工場
     l_lot_mst_rec.attribute21        := ir_lot_data.attribute21;      -- 製造元ロット番号
     l_lot_mst_rec.attribute22        := ir_lot_data.attribute22;      -- 検査依頼No
     l_lot_mst_rec.attribute23        := ir_lot_data.attribute23;      -- DFF23
     l_lot_mst_rec.attribute24        := ir_lot_data.attribute24;      -- DFF24
     l_lot_mst_rec.attribute25        := ir_lot_data.attribute25;      -- DFF25
     l_lot_mst_rec.attribute26        := ir_lot_data.attribute26;      -- DFF26
     l_lot_mst_rec.attribute27        := ir_lot_data.attribute27;      -- DFF27
     l_lot_mst_rec.attribute28        := ir_lot_data.attribute28;      -- DFF28
     l_lot_mst_rec.attribute29        := ir_lot_data.attribute29;      -- DFF29
     l_lot_mst_rec.attribute30        := ir_lot_data.attribute30;      -- DFF30
     l_lot_mst_rec.attribute_category := ir_lot_data.attribute_category;  -- DFFカテゴリ
     l_lot_mst_rec.last_update_date   := gd_sysdate;                   -- 更新日
     l_lot_mst_rec.last_updated_by    := gn_user_id;                   -- ユーザーID
--
     -- ロット期間レコードセット
     l_lot_cpg_rec.item_id            := ir_po_data.item_id;           -- 品目ID
     l_lot_cpg_rec.lot_id             := ir_lot_data.lot_id;           -- ロットID
     l_lot_cpg_rec.ic_hold_date       := ir_lot_data.ic_hold_date;     -- 保持日
     l_lot_cpg_rec.last_update_date   := gd_sysdate;                   -- 更新日
     l_lot_cpg_rec.last_updated_by    := gn_user_id;                   -- ユーザーID
--
     -- ===============================
     -- ロット単価変更API実行
     -- ===============================
     GMI_LOTUPDATE_PUB.UPDATE_LOT(
       p_api_version          => gv_version,       -- バージョン
       p_init_msg_list        => NULL,             -- メッセージ初期化フラグ
       p_commit               => NULL,             -- 処理確定フラグ
       p_validation_level     => NULL,             -- 検証レベル
       x_return_status        => lv_result,        -- 終了ステータス
       x_msg_count            => ln_msg_cnt,       -- メッセージスタック数
       x_msg_data             => lv_msg,           -- メッセージ
       p_lot_rec              => l_lot_mst_rec,    -- ロットマスタレコード
       p_lot_cpg_rec          => l_lot_cpg_rec);   -- ロット期間レコード
--
      -- APIエラー
     IF (lv_result <> FND_API.G_RET_STS_SUCCESS) THEN
       lv_errmsg  := xxcmn_common_pkg.get_msg(
                       iv_application  => gv_xxcmn,
                       iv_name         => gv_msg_xxcmn10018,
                       iv_token_name1  => gv_tkn_api_name,
                       iv_token_value1 => cv_api_name);  -- メッセージ取得
        RAISE global_user_expt;
     END IF;
   END IF;
--
--
  EXCEPTION
--
    WHEN global_user_expt THEN   --*** ユーザー定義例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_upd_lot_data;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_po_data
   * Description      : 発注明細の更新(C-7)
   ***********************************************************************************/
  PROCEDURE proc_upd_po_data(
    ir_po_data         IN  get_rec_type,  -- 発注明細情報
    in_total_amount    IN  NUMBER,        -- 内訳合計
    in_cohi_unit_price IN  NUMBER,        -- 粉引後単価
    in_depo_commission IN  NUMBER,        -- 預り口銭金額
    in_cane            IN  NUMBER,        -- 賦課金額
    in_cohi_rest       IN  NUMBER,        -- 粉引後金額
    ov_errbuf          OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_po_data'; -- プログラム名
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
    cv_api_name    CONSTANT VARCHAR2(100) := 'PO_CHANGE_API1_S.UPDATE_PO'; --発注変更API
--
    -- *** ローカル変数 ***
    ln_result             NUMBER;                            -- API関数戻り値
    ltbl_api_errors       PO_API_ERRORS_REC_TYPE;            -- APIエラー戻り値
    lv_out_msg            VARCHAR2(2000);                    -- ログメッセージ
--
    -- *** ローカル・カーソル ***
    -- <カーソル名>
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- ===============================
    -- 発注変更API実行
    -- ===============================
    ln_result := PO_CHANGE_API1_S.UPDATE_PO(
                   x_po_number               => ir_po_data.po_no,                 -- 発注番号
                   x_release_number          => NULL,                             -- リリース番号
                   x_revision_number         => ir_po_data.revision_num,          -- バージョン番号
                   x_line_number             => ir_po_data.po_l_no,               -- 発注明細番号
                   x_shipment_number         => NULL,                             -- 納入明細番号
                   new_quantity              => NULL,                             -- 数量
                   new_price                 => in_cohi_unit_price,               -- 価格
                   new_promised_date         => NULL,                             -- 納期
                   launch_approvals_flag     => gv_y,                             -- 承認ステータス
                   update_source             => NULL,                             -- アップデート
                   version                   => gv_version,                       -- バージョン
                   x_override_date           => NULL,                             -- 上書日付
                   x_api_errors              => ltbl_api_errors,                  -- エラー情報
                   p_buyer_name              => NULL);                            -- 担当者
--
    -- APIエラー
    IF (ln_result = gn_zero) THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxcmn,
                      iv_name         => gv_msg_xxcmn10018,
                      iv_token_name1  => gv_tkn_api_name,
                      iv_token_value1 => cv_api_name);  -- メッセージ取得
      RAISE global_user_expt;
    END IF;
--
    -- ===============================
    -- 発注明細の更新
    -- ===============================
    UPDATE po_lines_all pla                                                -- 発注明細
    SET    pla.attribute8             = in_total_amount                    -- 仕入定価(DFF)
          ,pla.last_updated_by        = gn_user_id                         -- 最終更新者
          ,pla.last_update_date       = gd_sysdate                         -- 最終更新日
          ,pla.last_update_login      = gn_login_id                        -- 最終更新ログイン
          ,pla.request_id             = gn_request_id                      -- 要求ID
          ,pla.program_application_id = gn_appl_id                         -- ｱﾌﾟﾘｹｰｼｮﾝID
          ,pla.program_id             = gn_program_id                      -- プログラムID
          ,pla.program_update_date    = gd_sysdate                         -- プログラム更新日
    WHERE pla.po_line_id              = ir_po_data.po_line_id              -- 発注明細ID
    ;
--
    -- ===============================
    -- 発注納入明細の更新
    -- ===============================
    -- 預り口銭金額、賦課金額、粉引後金額のいずれかの計算が行われた場合のみ更新
    IF (gn_depo_flg = 1) OR (gn_cane_flg = 1) THEN
--
      UPDATE po_line_locations_all plla                                       -- 発注納入明細
      SET    plla.attribute2             = in_cohi_unit_price                 -- 粉引後単価
            ,plla.attribute5             = CASE
                                             WHEN gn_depo_flg = 0 THEN plla.attribute5
                                             ELSE TO_CHAR(in_depo_commission) -- 預り口銭金額
                                           END
            ,plla.attribute8             = CASE
                                             WHEN gn_cane_flg = 0 THEN  plla.attribute8
                                             ELSE TO_CHAR(in_cane)            -- 賦課金額
                                           END
            ,plla.attribute9             = in_cohi_rest                       -- 粉引後金額
            ,plla.last_updated_by        = gn_user_id                         -- 最終更新者
            ,plla.last_update_date       = gd_sysdate                         -- 最終更新日
            ,plla.last_update_login      = gn_login_id                        -- 最終更新ログイン
            ,plla.request_id             = gn_request_id                      -- 要求ID
            ,plla.program_application_id = gn_appl_id                         -- ｱﾌﾟﾘｹｰｼｮﾝID
            ,plla.program_id             = gn_program_id                      -- プログラムID
            ,plla.program_update_date    = gd_sysdate                         -- プログラム更新日
      WHERE plla.line_location_id        = ir_po_data.line_location_id        -- 発注納入明細ID
      ;
--
    END IF;
--
    -- 更新件数
    gn_normal_cnt := gn_normal_cnt + 1;
--
--
  EXCEPTION
--
    WHEN global_user_expt THEN   --*** ユーザー定義例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_upd_po_data;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_calc_data
   * Description      : 計算処理(C-6)
   ***********************************************************************************/
  PROCEDURE proc_calc_data(
    ir_po_data         IN  get_rec_type,  -- 発注明細情報
    in_total_amount    IN  NUMBER,        -- 内訳合計
    on_cohi_unit_price OUT NUMBER,        -- 粉引後単価
    on_depo_commission OUT NUMBER,        -- 預り口銭金額
    on_cane            OUT NUMBER,        -- 賦課金額
    on_cohi_rest       OUT NUMBER,        -- 粉引後金額
    ov_errbuf          OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_calc_data'; -- プログラム名
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
    ln_quantity               NUMBER DEFAULT 0;            -- 数量
    ln_kona                   NUMBER DEFAULT 0;            -- 粉引額
--
    -- *** ローカル・カーソル ***
    -- <カーソル名>
--
    -- *** ローカル・レコード ***
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
--
    -- ===============================
    -- 数量の算出
    -- ===============================
    IF (ir_po_data.status > gv_po_stats) THEN
      ln_quantity := TRUNC(TO_NUMBER(ir_po_data.po_quantity));
    ELSE
      ln_quantity := TRUNC(TO_NUMBER(ir_po_data.rcv_quantity));
    END IF;
--
    -- 品目がドリンク製品の場合(単位と発注単位が異なる場合)は 数量 = 数量 * ケース入数
    IF (ir_po_data.base_uom <> ir_po_data.po_uom) THEN
      ln_quantity := TRUNC(ln_quantity * TO_NUMBER(ir_po_data.num_of_cases));
    END IF;
--
    -- ===============================
    -- 粉引後単価の計算
    -- ===============================
    on_cohi_unit_price := TRUNC(in_total_amount * (gn_100 - TO_NUMBER(ir_po_data.powde_lead))
                          / gn_100);
--
    -- ===============================
    -- 預り口銭金額の計算
    -- ===============================
    IF (ir_po_data.commission_type = gv_rate)
      AND  (ir_po_data.commission IS NOT NULL) THEN
      on_depo_commission := TRUNC(ln_quantity * in_total_amount *
                            ir_po_data.commission / gn_100);
      gn_depo_flg := 1;
    END IF;
--
    -- ===============================
    -- 賦課金額の計算
    -- ===============================
    IF ((ir_po_data.assessment_type = gv_rate)
      AND (ir_po_data.assessment IS NOT NULL)) THEN
      ln_kona := in_total_amount * ln_quantity * TO_NUMBER(ir_po_data.powde_lead) / gn_100;
      on_cane := TRUNC((in_total_amount * ln_quantity - ln_kona)
                       * TO_NUMBER(ir_po_data.assessment) / gn_100);
      gn_cane_flg := 1;
    END IF;
--
    -- ===============================
    -- 粉引後金額の計算
    -- ===============================
    on_cohi_rest := TRUNC(on_cohi_unit_price * ln_quantity);
--
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_calc_data;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_unit_price
   * Description      : 仕入単価データ取得(C-5)
   ***********************************************************************************/
  PROCEDURE proc_get_unit_price(
    iv_date_type       IN     VARCHAR2,      -- 日付タイプ(1:製造日 2:納入日)
    ir_po_data         IN     get_rec_type,  -- 発注明細情報
    ir_lot_data        IN     get_rec_lot,   -- ロット情報
    on_price_header_id OUT    NUMBER,        -- ヘッダID
    on_total_amount    OUT    NUMBER,        -- 内訳合計
    ov_errbuf          OUT    VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT    VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg          OUT    VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_unit_price'; -- プログラム名
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
    lc_vend              CONSTANT VARCHAR2(1) := '1';             -- 仕入
--
    -- *** ローカル変数 ***
    lv_sql               VARCHAR2(32767) DEFAULT NULL;            -- SQL
    ld_active            DATE;                                    -- 日付
--
    -- *** ローカル・カーソル ***
    -- <カーソル名>
--
    -- *** ローカル・レコード ***
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
--
    -- ===============================
    -- 日付の判定
    -- ===============================
    IF (iv_date_type = gv_mgc_day) THEN
    -- 日付タイプが製造日(1)の場合は製造年月日が対象
      ld_active := FND_DATE.STRING_TO_DATE(ir_lot_data.create_day,gv_format_yyyymmdd);
    ELSE
    -- 日付タイプが納入日(2)の場合は納入年月日が対象
      ld_active := FND_DATE.STRING_TO_DATE(ir_po_data.delivery_day,gv_format_yyyymmdd);
    END IF;
--
    BEGIN
--
      -- ===============================
      -- 仕入/標準単価ヘッダの取得
      -- ===============================
      lv_sql :=
        '   SELECT xph.price_header_id price_header_id,'            -- ヘッダID
        || '       xph.total_amount    total_amount'                -- 内訳合計
        || '  FROM xxpo_price_headers xph'                          -- 仕入/標準単価ヘッダ
        || ' WHERE xph.item_id             = :item_id'              -- 品目ID
        || '   AND xph.price_type          = :type'                 -- マスタ区分
        || '   AND xph.vendor_id           = :vendor_id'            -- 取引先ID
        || '   AND (xph.start_date_active <= :start_date_active'    -- 適用開始日
        || '   AND xph.end_date_active    >= :end_date_active)'     -- 適用終了日
        || '   AND xph.record_change_flg   = :change_y'             -- 変更処理フラグ
        || '   AND xph.factory_code        = :factory_code'         -- 工場コード
        || '   AND xph.futai_code          = :futai_code';          -- 付帯コード
--
      -- 直送区分が支給(3)の場合は支給先コードを条件にする
      IF (ir_po_data.direct_sending_type = gv_provision) THEN
--
        lv_sql := lv_sql
          || '   AND (xph.supply_to_code      = :supply_to_code'    -- 支給先コード
          || '        OR xph.supply_to_code   IS NULL)'
          || ' FOR UPDATE NOWAIT';
--
        EXECUTE IMMEDIATE lv_sql
                     INTO on_price_header_id,
                          on_total_amount
          USING ir_po_data.item_id,
                lc_vend,
                ir_po_data.vendor_id,
                ld_active,
                ld_active,
                gv_y,
                ir_po_data.fact_code,
                ir_po_data.accompany_code,
                ir_po_data.delivery_code;
      ELSE
--
        lv_sql := lv_sql
          || ' FOR UPDATE NOWAIT';
--
        EXECUTE IMMEDIATE lv_sql
                     INTO on_price_header_id,
                          on_total_amount
          USING ir_po_data.item_id,
                lc_vend,
                ir_po_data.vendor_id,
                ld_active,
                ld_active,
                gv_y,
                ir_po_data.fact_code,
                ir_po_data.accompany_code;
      END IF;
--
    EXCEPTION
--
      --*** ロック取得エラー ***
      WHEN lock_expt THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxcmn,
                        iv_name         => gv_msg_xxcmn10019,
                        iv_token_name1  => gv_tkn_table,
                        iv_token_value1 => gv_price_headers ),1,5000);
        RAISE global_user_expt;
--
      --*** データなし取得エラー ***
      WHEN NO_DATA_FOUND THEN
        gn_warn_cnt := gn_warn_cnt + 1;
--
        -- ===============================
        -- C-12.未処理発注明細情報出力
        -- ===============================
        proc_put_po_log(
          iv_msg_no         =>  gv_msg_xxpo30030,             -- メッセージ番号
          iv_tkn_itm_no     =>  gv_tkn_ng_item_no,           -- トークン品目
          iv_tkn_h_no       =>  gv_tkn_ng_h_no,              -- トークン発注番号
          iv_tkn_m_no       =>  gv_tkn_ng_m_no,              -- トークン発注明細
          iv_tkn_nonyu_date =>  gv_tkn_ng_nonyu_date,        -- トークン納入日
          iv_po_no          =>  ir_po_data.po_no,            -- 発注番号
          iv_po_l_no        =>  ir_po_data.po_l_no,          -- 明細番号
          iv_item_no        =>  ir_po_data.item_no,          -- 品目番号
          iv_delivery_day   =>  ir_po_data.delivery_day,     -- 納入日
          ov_errbuf         =>  lv_errbuf,                   -- エラー・メッセージ
          ov_retcode        =>  lv_retcode,                  -- リターン・コード
          ov_errmsg         =>  lv_errmsg);                  -- ユーザー・エラー・メッセージ
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_user_expt;
        END IF;
    END;
--
  EXCEPTION
--
    --*** ユーザー定義例外 ***
    WHEN global_user_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_get_unit_price;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_lot_data
   * Description      : ロットデータ取得
   ***********************************************************************************/
  PROCEDURE proc_get_lot_data(
    iv_date_type       IN     VARCHAR2,      -- 日付タイプ(1:製造日 2:納入日)
    iv_start_date      IN     VARCHAR2,      -- 期間開始日(YYYY/MM/DD)
    iv_end_date        IN     VARCHAR2,      -- 期間終了日(YYYY/MM/DD)
    ir_po_data         IN     get_rec_type,  -- 発注明細情報
    or_lot_data        OUT    get_rec_lot,   -- ロット情報
    ov_errbuf          OUT    VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT    VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg          OUT    VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_lot_data'; -- プログラム名
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
    lv_sql               VARCHAR2(32767) DEFAULT NULL;            -- SQL
--
    -- *** ローカル・カーソル ***
    -- <カーソル名>
--
    -- *** ローカル・レコード ***
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
--
    BEGIN
--
      -- ===============================
      -- ロットマスタ情報の取得
      -- ===============================
      lv_sql :=
        '    SELECT ilm.lot_id             AS  lot_id'                -- ロットID
        || '       ,ilm.lot_desc           AS  lot_desc'              -- ロット摘要
        || '       ,ilm.qc_grade           AS  qc_grade'              -- グレード
        || '       ,ilm.expaction_code     AS  expaction_code'        -- 処理コード
        || '       ,ilm.expaction_date     AS  expaction_date'        -- 失効日付
        || '       ,ilm.lot_created        AS  lot_created'           -- ロット作成日
        || '       ,ilm.expire_date        AS  expire_date'           -- 期限日
        || '       ,ilm.retest_date        AS  retest_date'           -- 再テスト日
        || '       ,ilm.strength           AS  strength'              -- 強度
        || '       ,ilm.inactive_ind       AS  inactive_ind'          -- 有効フラグ
        || '       ,ilm.shipvend_id        AS  shipvend_id'           -- 仕入先ID
        || '       ,ilm.vendor_lot_no      AS  vendor_lot_no'         -- 仕入ロットNO
        || '       ,ilm.attribute1         AS  create_day'            -- 製造年月日
        || '       ,ilm.attribute2         AS  attribute2'            -- 固有記号
        || '       ,ilm.attribute3         AS  attribute3'            -- 賞味期限
        || '       ,ilm.attribute4         AS  attribute4'            -- 納入日（初回）
        || '       ,ilm.attribute5         AS  attribute5'            -- 納入日（最終）
        || '       ,ilm.attribute6         AS  attribute6'            -- 在庫入数
        || '       ,ilm.attribute7         AS  attribute7'            -- 在庫単価
        || '       ,ilm.attribute8         AS  attribute8'            -- 取引先
        || '       ,ilm.attribute9         AS  attribute9'            -- 仕入形態
        || '       ,ilm.attribute10        AS  attribute10'           -- 茶期区分
        || '       ,ilm.attribute11        AS  attribute11'           -- 年度
        || '       ,ilm.attribute12        AS  attribute12'           -- 産地
        || '       ,ilm.attribute13        AS  attribute13'           -- タイプ
        || '       ,ilm.attribute14        AS  attribute14'           -- ランク１
        || '       ,ilm.attribute15        AS  attribute15'           -- ランク２
        || '       ,ilm.attribute16        AS  attribute16'           -- 生産伝票区分
        || '       ,ilm.attribute17        AS  attribute17'           -- ライン№
        || '       ,ilm.attribute18        AS  attribute18'           -- 摘要
        || '       ,ilm.attribute19        AS  attribute19'           -- ランク３
        || '       ,ilm.attribute20        AS  attribute20'           -- 原料製造工場
        || '       ,ilm.attribute21        AS  attribute21'           -- 原料製造元ロット番号
        || '       ,ilm.attribute22        AS  attribute22'           -- 検査依頼No
        || '       ,ilm.attribute23        AS  attribute23'           -- DFF23
        || '       ,ilm.attribute24        AS  attribute24'           -- DFF24
        || '       ,ilm.attribute25        AS  attribute25'           -- DFF25
        || '       ,ilm.attribute26        AS  attribute26'           -- DFF26
        || '       ,ilm.attribute27        AS  attribute27'           -- DFF27
        || '       ,ilm.attribute28        AS  attribute28'           -- DFF28
        || '       ,ilm.attribute29        AS  attribute29'           -- DFF29
        || '       ,ilm.attribute30        AS  attribute30'           -- DFF30
        || '       ,ilm.attribute_category AS  attribute_category'    -- DFFカテゴリ
        || '       ,ilc.ic_hold_date       AS  ic_hold_date'          -- 保持日
        || ' FROM ic_lots_mst           ilm '                         -- OPMロットマスタ
        || '     ,ic_lots_cpg           ilc ';                        -- OPMロット保持期間
--
    -- 日付タイプ条件SQL生成
    IF (iv_date_type = gv_mgc_day) THEN
      -- 日付タイプが製造日の場合
      lv_sql := lv_sql || ' WHERE ilm.attribute1 BETWEEN :start_date AND :end_date' --製造日
                       || ' AND   ilm.item_id    = :item_id'     -- 品目ID
                       || ' AND   ilm.lot_no     = :lot_no'      -- ロットNO
                       || ' AND   ilc.item_id(+) = ilm.item_id'  -- 品目ID
                       || ' AND   ilc.lot_id(+)  = ilm.lot_id'   -- ロットID
                       || ' FOR UPDATE NOWAIT';
--
       EXECUTE IMMEDIATE lv_sql
                    INTO or_lot_data.lot_id,
                         or_lot_data.lot_desc,
                         or_lot_data.qc_grade,
                         or_lot_data.expaction_code,
                         or_lot_data.expaction_date,
                         or_lot_data.lot_created,
                         or_lot_data.expire_date,
                         or_lot_data.retest_date,
                         or_lot_data.strength,
                         or_lot_data.inactive_ind,
                         or_lot_data.shipvend_id,
                         or_lot_data.vendor_lot_no,
                         or_lot_data.create_day,
                         or_lot_data.attribute2,
                         or_lot_data.attribute3,
                         or_lot_data.attribute4,
                         or_lot_data.attribute5,
                         or_lot_data.attribute6,
                         or_lot_data.attribute7,
                         or_lot_data.attribute8,
                         or_lot_data.attribute9,
                         or_lot_data.attribute10,
                         or_lot_data.attribute11,
                         or_lot_data.attribute12,
                         or_lot_data.attribute13,
                         or_lot_data.attribute14,
                         or_lot_data.attribute15,
                         or_lot_data.attribute16,
                         or_lot_data.attribute17,
                         or_lot_data.attribute18,
                         or_lot_data.attribute19,
                         or_lot_data.attribute20,
                         or_lot_data.attribute21,
                         or_lot_data.attribute22,
                         or_lot_data.attribute23,
                         or_lot_data.attribute24,
                         or_lot_data.attribute25,
                         or_lot_data.attribute26,
                         or_lot_data.attribute27,
                         or_lot_data.attribute28,
                         or_lot_data.attribute29,
                         or_lot_data.attribute30,
                         or_lot_data.attribute_category,
                         or_lot_data.ic_hold_date
         USING iv_start_date,
               iv_end_date,
               ir_po_data.item_id,
               ir_po_data.lot_no;
--
    ELSE
      lv_sql := lv_sql || ' WHERE ilm.item_id(+) = :item_id'     -- 品目ID
                       || ' AND   ilm.lot_no(+)  = :lot_no'      -- ロットNO
                       || ' AND   ilc.item_id(+) = ilm.item_id'  -- 品目ID
                       || ' AND   ilc.lot_id(+)  = ilm.lot_id'   -- ロットID
                       || ' FOR UPDATE NOWAIT';
--
       EXECUTE IMMEDIATE lv_sql
                    INTO or_lot_data.lot_id,
                         or_lot_data.lot_desc,
                         or_lot_data.qc_grade,
                         or_lot_data.expaction_code,
                         or_lot_data.expaction_date,
                         or_lot_data.lot_created,
                         or_lot_data.expire_date,
                         or_lot_data.retest_date,
                         or_lot_data.strength,
                         or_lot_data.inactive_ind,
                         or_lot_data.shipvend_id,
                         or_lot_data.vendor_lot_no,
                         or_lot_data.create_day,
                         or_lot_data.attribute2,
                         or_lot_data.attribute3,
                         or_lot_data.attribute4,
                         or_lot_data.attribute5,
                         or_lot_data.attribute6,
                         or_lot_data.attribute7,
                         or_lot_data.attribute8,
                         or_lot_data.attribute9,
                         or_lot_data.attribute10,
                         or_lot_data.attribute11,
                         or_lot_data.attribute12,
                         or_lot_data.attribute13,
                         or_lot_data.attribute14,
                         or_lot_data.attribute15,
                         or_lot_data.attribute16,
                         or_lot_data.attribute17,
                         or_lot_data.attribute18,
                         or_lot_data.attribute19,
                         or_lot_data.attribute20,
                         or_lot_data.attribute21,
                         or_lot_data.attribute22,
                         or_lot_data.attribute23,
                         or_lot_data.attribute24,
                         or_lot_data.attribute25,
                         or_lot_data.attribute26,
                         or_lot_data.attribute27,
                         or_lot_data.attribute28,
                         or_lot_data.attribute29,
                         or_lot_data.attribute30,
                         or_lot_data.attribute_category,
                         or_lot_data.ic_hold_date
         USING ir_po_data.item_id,
               ir_po_data.lot_no;
    END IF;
--
    EXCEPTION
--
      --*** ロック取得エラー ***
      WHEN lock_expt THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxcmn,
                        iv_name         => gv_msg_xxcmn10019,
                        iv_token_name1  => gv_tkn_table,
                        iv_token_value1 => gv_po_line     || gv_msg_comma
                                        || gv_po_location || gv_msg_comma
                                        || gv_lot_mst ),1,5000);
        RAISE global_user_expt;
--
    END;
--
--
  EXCEPTION
--
    --*** ユーザー定義例外 ***
    WHEN global_user_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_get_lot_data;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_po_data
   * Description      : 発注明細データ取得(C-3,C-4)
   ***********************************************************************************/
  PROCEDURE proc_get_po_data(
    iv_date_type       IN  VARCHAR2,      -- 日付タイプ(1:製造日 2:納入日)
    iv_start_date      IN  VARCHAR2,      -- 期間開始日(YYYY/MM/DD)
    iv_end_date        IN  VARCHAR2,      -- 期間終了日(YYYY/MM/DD)
    iv_item_type_name  IN  VARCHAR2,      -- 品目区分名
    iv_goods_type_name IN  VARCHAR2,      -- 商品区分名
    ir_item            IN  g_rec_item,    -- 品目情報
    ir_vender          IN  g_rec_vender,  -- 取引先情報
    ot_data_rec        OUT get_po_tbl,    -- 発注情報
    ov_errbuf          OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_po_data'; -- プログラム名
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
    lv_sql               VARCHAR2(32767) DEFAULT NULL;            -- SQL
--
    -- *** ローカル・カーソル ***
    -- <カーソル名>
    TYPE cursor_type IS REF CURSOR;
    data_cur cursor_type;
--
    -- *** ローカル・レコード ***
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
--
--
    -- ===============================
    -- SQL文の取得
    -- ===============================
    lv_sql := func_create_sql(
                iv_date_type       => iv_date_type,       -- 日付タイプ(1:製造日 2:納入日)
                iv_start_date      => iv_start_date,      -- 期間開始日(YYYY/MM/DD)
                iv_end_date        => iv_end_date,        -- 期間終了日(YYYY/MM/DD)
                iv_goods_type_name => iv_goods_type_name, -- 商品区分名
                iv_item_type_name  => iv_item_type_name,  -- 品目区分名
                ir_item            => ir_item,            -- 品目ID1
                ir_vender          => ir_vender);         -- 取引先ID3
--
    BEGIN
--
    -- カーソルオープン
      OPEN data_cur FOR lv_sql;
      -- バルクフェッチ
      FETCH data_cur BULK COLLECT INTO ot_data_rec ;
--
      IF (ot_data_rec.COUNT = 0) THEN
        -- 対象データが存在しない場合は警告終了
        -- 取得データが０件の場合エラー
        ov_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxpo,
                        iv_name         => gv_msg_xxpo10093
                      ),1,5000);
        ov_retcode := gv_status_warn;
      END IF;
      -- カーソルクローズ
      CLOSE data_cur;
--
    EXCEPTION
      --*** ロック取得エラー ***
      WHEN lock_expt THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxcmn,
                        iv_name         => gv_msg_xxcmn10019,
                        iv_token_name1  => gv_tkn_table,
                        iv_token_value1 => gv_po_line     || gv_msg_comma
                                        || gv_po_location || gv_msg_comma
                                        || gv_lot_mst ),1,5000);
        RAISE global_user_expt;
    END;
--
--
  EXCEPTION
--
    --*** ユーザー定義例外 ***
    WHEN global_user_expt THEN
      IF ( data_cur%ISOPEN ) THEN
        CLOSE data_cur ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( data_cur%ISOPEN ) THEN
        CLOSE data_cur ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( data_cur%ISOPEN ) THEN
        CLOSE data_cur ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( data_cur%ISOPEN ) THEN
        CLOSE data_cur ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_get_po_data;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_check_param
   * Description      : パラメータチェック(C-2)
   ***********************************************************************************/
  PROCEDURE proc_check_param(
    iv_date_type       IN     VARCHAR2,      -- 日付タイプ(1:製造日 2:納入日)
    iv_start_date      IN     VARCHAR2,      -- 期間開始日(YYYY/MM/DD HH24:MI:SS)
    iv_end_date        IN     VARCHAR2,      -- 期間終了日(YYYY/MM/DD HH24:MI:SS)
    iv_commodity_type  IN     VARCHAR2,      -- 商品区分
    iv_item_type       IN     VARCHAR2,      -- 品目区分
    ior_item           IN OUT g_rec_item,    -- 品目情報
    ior_vender         IN OUT g_rec_vender,  -- 取引先情報
    ov_start_date      OUT     VARCHAR2,     -- 期間開始日(YYYY/MM/DD)
    ov_end_date        OUT     VARCHAR2,     -- 期間終了日(YYYY/MM/DD)
    ov_item_type_name  OUT    VARCHAR2,      -- 品目区分名
    ov_goods_type_name OUT    VARCHAR2,      -- 商品区分名
    ov_errbuf          OUT    VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT    VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg          OUT    VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_check_param'; -- プログラム名
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
    lv_lookup_code          xxcmn_lookup_values_v.lookup_code%TYPE; -- ルックアップコード
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================================================
    -- 日付タイプが入力されているかチェックします。
    -- ==============================================================
    IF (iv_date_type IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxpo,
                      iv_name         => gv_msg_xxpo10102,
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => gv_tkn_val_date_type
                    ),1,5000);
      RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- 期間(開始)が入力されているかチェックします。
    -- ==============================================================
    IF (iv_start_date IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxpo,
                      iv_name         => gv_msg_xxpo10102,
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => gv_tkn_val_start_date
                    ),1,5000);
      RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- 期間(終了)が入力されているかチェックします。
    -- ==============================================================
    IF (iv_end_date IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxpo,
                      iv_name         => gv_msg_xxpo10102,
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => gv_tkn_val_end_date
                    ),1,5000);
      RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- 商品区分が入力されているかチェックします。
    -- ==============================================================
    IF (iv_commodity_type IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxpo,
                      iv_name         => gv_msg_xxpo10102,
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => gv_tkn_val_commodity_type
                    ),1,5000);
      RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- 品目区分が入力されているかチェックします。
    -- ==============================================================
    IF (iv_item_type IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxpo,
                      iv_name         => gv_msg_xxpo10102,
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => gv_tkn_val_item_type
                    ),1,5000);
      RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- 日付タイプがクイックコード情報に存在するかチェック
    -- ==============================================================
    BEGIN
      SELECT lookup_code lookup_code
      INTO   lv_lookup_code
      FROM   xxcmn_lookup_values_v xlvv             -- クイックコード情報VIEW
      WHERE  lookup_type = gv_xxcmn_date_type
      AND    lookup_code = iv_date_type
      AND    ROWNUM      = 1;
    EXCEPTION
    -- データがない場合はエラー
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxpo,
                        iv_name         => gv_msg_xxpo10103,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => gv_tkn_val_date_type,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => iv_date_type
                    ),1,5000);
        RAISE global_user_expt;
      -- その他エラー
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ==============================================================
    -- 商品区分が品目カテゴリ情報に存在するかチェック
    -- ==============================================================
    BEGIN
      SELECT xcv.description description
      INTO   ov_goods_type_name
      FROM   xxcmn_categories_v xcv             -- 品目カテゴリ情報VIEW
      WHERE  xcv.category_set_name = gv_cat_set_goods_class
      AND    xcv.segment1          = iv_commodity_type
      AND    ROWNUM                = 1;
    EXCEPTION
    -- データがない場合はエラー
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxpo,
                        iv_name         => gv_msg_xxpo10103,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => gv_tkn_val_commodity_type,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => iv_commodity_type
                    ),1,5000);
        RAISE global_user_expt;
      -- その他エラー
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ==============================================================
    -- 品目区分がカテゴリ情報に存在するかチェック
    -- ==============================================================
    BEGIN
      SELECT xcv.description description
      INTO   ov_item_type_name
      FROM   xxcmn_categories_v xcv             -- 品目カテゴリ情報VIEW
      WHERE  xcv.category_set_name = gv_cat_set_item_class
      AND    xcv.segment1          = iv_item_type
      AND    ROWNUM                = 1;
    EXCEPTION
    -- データがない場合はエラー
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxpo,
                        iv_name         => gv_msg_xxpo10103,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => gv_tkn_val_item_type,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => iv_item_type
                    ),1,5000);
        RAISE global_user_expt;
      -- その他エラー
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ==============================================================
    -- 品目がOPM品目マスタに存在するかチェック
    -- ==============================================================
    <<item_chek_loop>>
    FOR i IN 1..ior_item.item_no.COUNT LOOP
--
      ior_item.item_id(i) := func_chk_item_no(
                       iv_item_no => ior_item.item_no(i));
      IF (ior_item.item_id(i) IS NULL) THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxpo,
                        iv_name         => gv_msg_xxpo10103,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => gv_tkn_val_item,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => ior_item.item_no(i)
                    ),1,5000);
        RAISE global_user_expt;
      END IF;
--
    END LOOP item_chek_loop;
--
    -- ==============================================================
    -- 取引先コードが仕入先マスタに存在するかチェック
    -- ==============================================================
    <<vender_chek_loop>>
    FOR i IN 1..ior_vender.vender_code.COUNT LOOP
      ior_vender.vender_id(i) := func_chk_customer(
                           iv_customer_code => ior_vender.vender_code(i));
      IF (ior_vender.vender_id(i) IS NULL) THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxpo,
                        iv_name         => gv_msg_xxpo10103,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => gv_tkn_val_customer,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => ior_vender.vender_code(i)
                    ),1,5000);
        RAISE global_user_expt;
      END IF;
    END LOOP vender_chek_loop;
--
    -- ==============================================================
    -- 期間開始日が年月日として正しいかチェック
    -- ==============================================================
    ov_start_date := TO_CHAR(FND_DATE.STRING_TO_DATE(iv_start_date,gv_dt_format),
                            gv_format_yyyymmdd);
    IF (ov_start_date IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxpo,
                      iv_name         => gv_msg_xxpo10104,
                      iv_token_name1  => gv_tkn_param_value,
                      iv_token_value1 => iv_start_date
                  ),1,5000);
      RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- 期間終了日が年月日として正しいかチェック
    -- ==============================================================
    ov_end_date := TO_CHAR(FND_DATE.STRING_TO_DATE(iv_end_date, gv_dt_format),
                            gv_format_yyyymmdd);
    IF (ov_end_date IS NULL) THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxpo,
                        iv_name         => gv_msg_xxpo10104,
                        iv_token_name1  => gv_tkn_param_value,
                        iv_token_value1 => iv_end_date
                    ),1,5000);
        RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- 期間(開始) ≦ 期間(終了) になっているかチェック
    -- ==============================================================
    IF (iv_start_date > iv_end_date) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxpo,
                      iv_name         => gv_msg_xxpo10105
                    ),1,5000);
      RAISE global_user_expt;
    END IF;
--
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ユーザー定義例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_check_param;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_put_parameter_log
   * Description      : 前処理(入力パラメータログ出力処理)(C-1)
   ***********************************************************************************/
  PROCEDURE proc_put_parameter_log(
    iv_date_type       IN  VARCHAR2,      -- 日付タイプ(1:製造日 2:納入日)
    iv_start_date      IN  VARCHAR2,      -- 期間開始日(YYYY/MM/DD)
    iv_end_date        IN  VARCHAR2,      -- 期間終了日(YYYY/MM/DD)
    iv_commodity_type  IN  VARCHAR2,      -- 商品区分
    iv_item_type       IN  VARCHAR2,      -- 品目区分
    iv_item_code1      IN  VARCHAR2,      -- 品目コード1
    iv_item_code2      IN  VARCHAR2,      -- 品目コード2
    iv_item_code3      IN  VARCHAR2,      -- 品目コード3
    iv_customer_code1  IN  VARCHAR2,      -- 取引先コード1
    iv_customer_code2  IN  VARCHAR2,      -- 取引先コード2
    iv_customer_code3  IN  VARCHAR2,      -- 取引先コード3
    ov_errbuf          OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_put_parameter_log'; -- プログラム名
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
    lv_out_msg       VARCHAR2(5000);
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- パラメーター情報出力
    -- ===============================
    lv_out_msg := SUBSTRB(xxcmn_common_pkg.get_msg(
                    iv_application  => gv_xxpo,
                    iv_name         => gv_msg_xxpo30036,
                    iv_token_name1  => gv_tkn_data_type,
                    iv_token_value1 => iv_date_type,
                    iv_token_name2  => gv_tkn_date_from,
                    iv_token_value2 => iv_start_date,
                    iv_token_name3  => gv_tkn_data_to,
                    iv_token_value3 => iv_end_date,
                    iv_token_name4  => gv_tkn_goods_category,
                    iv_token_value4 => iv_commodity_type,
                    iv_token_name5  => gv_tkn_item_category,
                    iv_token_value5 => iv_item_type,
                    iv_token_name6  => gv_tkn_item_no,
                    iv_token_value6 => iv_item_code1     || gv_msg_comma ||
                                       iv_item_code2     || gv_msg_comma ||
                                       iv_item_code3     || gv_msg_comma,
                    iv_token_name7  => gv_tkn_vendor_code,
                    iv_token_value7 => iv_customer_code1 || gv_msg_comma ||
                                       iv_customer_code2 || gv_msg_comma ||
                                       iv_customer_code3 || gv_msg_comma
                  ),1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_put_parameter_log;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_date_type       IN  VARCHAR2,      -- 日付タイプ(1:製造日 2:納入日)
    iv_start_date      IN  VARCHAR2,      -- 期間開始日(YYYY/MM/DD)
    iv_end_date        IN  VARCHAR2,      -- 期間終了日(YYYY/MM/DD)
    iv_commodity_type  IN  VARCHAR2,      -- 商品区分
    iv_item_type       IN  VARCHAR2,      -- 品目区分
    iv_item_code1      IN  VARCHAR2,      -- 品目コード1
    iv_item_code2      IN  VARCHAR2,      -- 品目コード2
    iv_item_code3      IN  VARCHAR2,      -- 品目コード3
    iv_customer_code1  IN  VARCHAR2,      -- 取引先コード1
    iv_customer_code2  IN  VARCHAR2,      -- 取引先コード2
    iv_customer_code3  IN  VARCHAR2,      -- 取引先コード3
    ov_errbuf          OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
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
    ln_request_count NUMBER;    -- 要求IDカウント
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_start_date      ic_lots_mst.attribute1%TYPE DEFAULT NULL;               -- 開始日
    lv_end_date        ic_lots_mst.attribute1%TYPE DEFAULT NULL;               -- 終了日
    lv_p_item_type     fnd_profile_option_values.profile_option_value%TYPE;    -- 品目区分
    lv_p_goods_type    fnd_profile_option_values.profile_option_value%TYPE;    -- 商品区分
    lv_item_type_name  xxcmn_categories_v.description%TYPE;                    -- 品目区分名
    lv_goods_type_name xxcmn_categories_v.description%TYPE;                    -- 商品区分名
    ln_item_id1        mtl_system_items_b.inventory_item_id%TYPE DEFAULT NULL; -- 品目ID1
    ln_item_id2        mtl_system_items_b.inventory_item_id%TYPE DEFAULT NULL; -- 品目ID2
    ln_item_id3        mtl_system_items_b.inventory_item_id%TYPE DEFAULT NULL; -- 品目ID3
    ln_vendor_id1      po_vendors.vendor_id%TYPE DEFAULT NULL;                 -- 仕入先ID1
    ln_vendor_id2      po_vendors.vendor_id%TYPE DEFAULT NULL;                 -- 仕入先ID2
    ln_vendor_id3      po_vendors.vendor_id%TYPE DEFAULT NULL;                 -- 仕入先ID3
    ln_price_header_id xxpo_price_headers.price_header_id%TYPE DEFAULT NULL;   -- ヘッダID
    ln_total_amount    xxpo_price_headers.total_amount%TYPE DEFAULT NULL;      -- 内訳合計
    ln_cohi_unit_price NUMBER DEFAULT 0;                                       -- 粉引後単価
    ln_depo_commission NUMBER DEFAULT 0;                                       -- 預り口銭金額
    ln_cane            NUMBER DEFAULT 0;                                       -- 賦課金額
    ln_cohi_rest       NUMBER DEFAULT 0;                                       -- 粉引後金額
    ln_item_cnt        NUMBER DEFAULT 0;                                       -- 件数
    ln_vender_cnt      NUMBER DEFAULT 0;                                       -- 件数
    ln_p_h_cnt         NUMBER DEFAULT 1;                                       -- 件数
    lt_p_header_id     gt_p_header_id;                                         -- 仕入単価ID
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lt_data_rec  get_po_tbl;
    l_rec_item   g_rec_item;
    l_rec_vender g_rec_vender;
    lr_lot_data  get_rec_lot;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
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
    -- C-1.前処理(入力パラメータログ出力処理)
    -- ===============================
    proc_put_parameter_log(
      iv_date_type       => iv_date_type,       -- 日付タイプ(1:製造日 2:納入日)
      iv_start_date      => iv_start_date,      -- 期間開始日(YYYY/MM/DD)
      iv_end_date        => iv_end_date,        -- 期間終了日(YYYY/MM/DD)
      iv_commodity_type  => iv_commodity_type,  -- 商品区分
      iv_item_type       => iv_item_type,       -- 品目区分
      iv_item_code1      => iv_item_code1,      -- 品目コード1
      iv_item_code2      => iv_item_code2,      -- 品目コード2
      iv_item_code3      => iv_item_code3,      -- 品目コード3
      iv_customer_code1  => iv_customer_code1,  -- 取引先コード1
      iv_customer_code2  => iv_customer_code2,  -- 取引先コード2
      iv_customer_code3  => iv_customer_code3,  -- 取引先コード3
      ov_errbuf          => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      ov_retcode         => lv_retcode,         -- リターン・コード             --# 固定 #
      ov_errmsg          => lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 入力バラメータ格納
--
    -- 品目１
    IF (TRIM(iv_item_code1) IS NOT NULL) THEN
      ln_item_cnt := l_rec_item.item_no.COUNT + 1;
      l_rec_item.item_no(ln_item_cnt) := iv_item_code1;
    END IF;
    -- 品目２
    IF (TRIM(iv_item_code2) IS NOT NULL) THEN
      ln_item_cnt := l_rec_item.item_no.COUNT + 1;
      l_rec_item.item_no(ln_item_cnt) := iv_item_code2;
    END IF;
    -- 品目３
    IF (TRIM(iv_item_code3) IS NOT NULL) THEN
      ln_item_cnt := l_rec_item.item_no.COUNT + 1;
      l_rec_item.item_no(ln_item_cnt) := iv_item_code3;
    END IF;
--
    -- 取引先１
    IF (TRIM(iv_customer_code1) IS NOT NULL) THEN
      ln_vender_cnt := l_rec_vender.vender_code.COUNT + 1;
      l_rec_vender.vender_code(ln_vender_cnt) := iv_customer_code1;
    END IF;
    -- 取引先２
    IF (TRIM(iv_customer_code2) IS NOT NULL) THEN
      ln_vender_cnt := l_rec_vender.vender_code.COUNT + 1;
      l_rec_vender.vender_code(ln_vender_cnt) := iv_customer_code2;
    END IF;
    -- 取引先３
    IF (TRIM(iv_customer_code3) IS NOT NULL) THEN
      ln_vender_cnt := l_rec_vender.vender_code.COUNT + 1;
      l_rec_vender.vender_code(ln_vender_cnt) := iv_customer_code3;
    END IF;
--
    -- ===============================
    -- C-2.パラメータチェック
    -- ===============================
    proc_check_param(
      iv_date_type       => iv_date_type,       -- 日付タイプ(1:製造日 2:納入日)
      iv_start_date      => iv_start_date,      -- 期間開始日(YYYY/MM/DD)
      iv_end_date        => iv_end_date,        -- 期間終了日(YYYY/MM/DD)
      iv_commodity_type  => iv_commodity_type,  -- 商品区分
      iv_item_type       => iv_item_type,       -- 品目区分
      ior_item           => l_rec_item,         -- 品目情報
      ior_vender         => l_rec_vender,       -- 取引先情報
      ov_start_date      => lv_start_date,      -- 期間開始日(YYYY/MM/DD)
      ov_end_date        => lv_end_date,        -- 期間終了日(YYYY/MM/DD)
      ov_item_type_name  => lv_item_type_name,  -- 品目区分名
      ov_goods_type_name => lv_goods_type_name, -- 商品区分名
      ov_errbuf          => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      ov_retcode         => lv_retcode,         -- リターン・コード             --# 固定 #
      ov_errmsg          => lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- C-3,C-4.発注明細データ取得
    -- ===============================
    proc_get_po_data(
      iv_date_type       => iv_date_type,       -- 日付タイプ(1:製造日 2:納入日)
      iv_start_date      => lv_start_date,      -- 期間開始日(YYYY/MM/DD)
      iv_end_date        => lv_end_date,        -- 期間終了日(YYYY/MM/DD)
      iv_item_type_name  => lv_item_type_name,  -- 品目区分名
      iv_goods_type_name => lv_goods_type_name, -- 商品区分名
      ir_item            => l_rec_item,         -- 品目情報
      ir_vender          => l_rec_vender,       -- 取引先情報
      ot_data_rec        => lt_data_rec,        -- 発注情報
      ov_errbuf          => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      ov_retcode         => lv_retcode,         -- リターン・コード             --# 固定 #
      ov_errmsg          => lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      RAISE global_user_expt;
    ELSE
      NULL;
    END IF;
--
    <<main_data_loop>>
    FOR i IN 1..lt_data_rec.COUNT LOOP
--
      -- 変数初期化
      gn_depo_flg         := 0;
      gn_cane_flg         := 0;
      ln_price_header_id  := NULL;
      ln_total_amount     := 0;
      ln_cohi_unit_price  := 0;
      ln_depo_commission  := 0;
      ln_cane             := 0;
      ln_cohi_rest        := 0;
      lr_lot_data         := NULL;
--;
      -- ===============================
      -- ロット情報取得
      -- ===============================
      proc_get_lot_data(
        iv_date_type        =>  iv_date_type,               -- 日付タイプ(1:製造日 2:納入日)
        iv_start_date       =>  lv_start_date,              -- 期間開始日(YYYY/MM/DD)
        iv_end_date         =>  lv_end_date,                -- 期間終了日(YYYY/MM/DD)
        ir_po_data          =>  lt_data_rec(i),             -- 発注情報
        or_lot_data         =>  lr_lot_data,                -- ロット情報
        ov_errbuf           =>  lv_errbuf,                  -- エラー・メッセージ
        ov_retcode          =>  lv_retcode,                 -- リターン・コード
        ov_errmsg           =>  lv_errmsg);                 -- ユーザー・エラー・メッセージ
--
--
      IF (((iv_date_type = gv_mgc_day) AND (lr_lot_data.lot_id IS NOT NULL))
        OR (iv_date_type = gv_deliver_day))THEN
--
        -- 対象件数COUNT
        gn_target_cnt := gn_target_cnt + 1;
--
        -- ===============================
        -- C-5.仕入単価データ取得
        -- ===============================
        proc_get_unit_price(
          iv_date_type        =>  iv_date_type,               -- 日付タイプ(1:製造日 2:納入日)
          ir_po_data          =>  lt_data_rec(i),             -- 発注情報
          ir_lot_data         =>  lr_lot_data,                -- ロット情報
          on_price_header_id  =>  ln_price_header_id,         -- ヘッダID
          on_total_amount     =>  ln_total_amount,            -- 内訳合計
          ov_errbuf           =>  lv_errbuf,                  -- エラー・メッセージ
          ov_retcode          =>  lv_retcode,                 -- リターン・コード
          ov_errmsg           =>  lv_errmsg);                 -- ユーザー・エラー・メッセージ
--
        -- エラー処理
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 仕入単価取得時のみ処理対象
        IF (ln_price_header_id IS NOT NULL) THEN
          -- ===============================
          -- C-6.計算処理
          -- ===============================
          proc_calc_data(
            ir_po_data          =>  lt_data_rec(i),             -- 発注情報
            in_total_amount     =>  ln_total_amount,            -- 内訳合計
            on_cohi_unit_price  =>  ln_cohi_unit_price,         -- 粉引後単価
            on_depo_commission  =>  ln_depo_commission,         -- 預り口銭金額
            on_cane             =>  ln_cane,                    -- 賦課金額
            on_cohi_rest        =>  ln_cohi_rest,               -- 粉引後金額
            ov_errbuf           =>  lv_errbuf,                  -- エラー・メッセージ
            ov_retcode          =>  lv_retcode,                 -- リターン・コード
            ov_errmsg           =>  lv_errmsg);                 -- ユーザー・エラー・メッセージ
--
          -- エラー処理
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- C-7.発注情報更新処理
          -- ===============================
          proc_upd_po_data(
            ir_po_data          =>  lt_data_rec(i),             -- 発注情報
            in_total_amount     =>  ln_total_amount,            -- 内訳合計
            in_cohi_unit_price  =>  ln_cohi_unit_price,         -- 粉引後単価
            in_depo_commission  =>  ln_depo_commission,         -- 預り口銭金額
            in_cane             =>  ln_cane,                    -- 賦課金額
            in_cohi_rest        =>  ln_cohi_rest,               -- 粉引後金額
            ov_errbuf           =>  lv_errbuf,                  -- エラー・メッセージ
            ov_retcode          =>  lv_retcode,                 -- リターン・コード
            ov_errmsg           =>  lv_errmsg);                 -- ユーザー・エラー・メッセージ
--
          -- エラー処理
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
--
          -- ===============================
          -- C-8.ロットの在庫単価更新
          -- ===============================
          proc_upd_lot_data(
            ir_po_data          =>  lt_data_rec(i),             -- 発注情報
            ir_lot_data         =>  lr_lot_data,                -- ロット情報
            in_total_amount     =>  ln_total_amount,            -- 内訳合計
            in_cohi_unit_price  =>  ln_cohi_unit_price,         -- 粉引後単価
            in_depo_commission  =>  ln_depo_commission,         -- 預り口銭金額
            in_cane             =>  ln_cane,                    -- 賦課金額
            in_cohi_rest        =>  ln_cohi_rest,               -- 粉引後金額
            ov_errbuf           =>  lv_errbuf,                  -- エラー・メッセージ
            ov_retcode          =>  lv_retcode,                 -- リターン・コード
            ov_errmsg           =>  lv_errmsg);                 -- ユーザー・エラー・メッセージ
--
          -- エラー処理
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- C-9.処理済発注明細情報出力
          -- ===============================
          proc_put_po_log(
            iv_msg_no         =>  gv_msg_xxpo30032,              -- メッセージ番号
            iv_tkn_itm_no     =>  gv_tkn_item_no,                -- トークン品目
            iv_tkn_h_no       =>  gv_tkn_h_no,                   -- トークン発注番号
            iv_tkn_m_no       =>  gv_tkn_m_no,                   -- トークン発注明細
            iv_tkn_nonyu_date =>  gv_tkn_nonyu_date,             -- トークン納入日
            iv_po_no          =>  lt_data_rec(i).po_no,          -- 発注番号
            iv_po_l_no        =>  lt_data_rec(i).po_l_no,        -- 明細番号
            iv_item_no        =>  lt_data_rec(i).item_no,        -- 品目番号
            iv_delivery_day   =>  lt_data_rec(i).delivery_day,   -- 納入日
            ov_errbuf         =>  lv_errbuf,                     -- エラー・メッセージ
            ov_retcode        =>  lv_retcode,                    -- リターン・コード
            ov_errmsg         =>  lv_errmsg);                    -- ユーザー・エラー・メッセージ
--
          -- エラー処理
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 仕入単価ヘッダーIDの格納
          lt_p_header_id(ln_p_h_cnt) := ln_price_header_id;
--
          -- 仕入単価ヘッダー更新件数の取得
          ln_p_h_cnt := ln_p_h_cnt + 1;
--
        END IF;
--
      END IF;
--
    END LOOP main_data_loop ;
--
    <<ph_loop>>
    FOR i IN 1..lt_p_header_id.COUNT LOOP
      -- ===============================
      -- C-10.仕入/標準単価ヘッダ(アドオン)の変更処理フラグを更新
      -- ===============================
      proc_upd_price_headers_flg(
        in_price_header_id  =>  lt_p_header_id(i),          -- ヘッダID
        ov_errbuf           =>  lv_errbuf,                  -- エラー・メッセージ
        ov_retcode          =>  lv_retcode,                 -- リターン・コード
        ov_errmsg           =>  lv_errmsg);                 -- ユーザー・エラー・メッセージ
--
      -- エラー処理
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP ph_loop ;
--
    -- ===============================
    -- C-11.処理結果出力
    -- ===============================
    proc_put_process_result(
      ov_errbuf          => lv_errbuf,                    -- エラー・メッセージ
      ov_retcode         => lv_retcode,                   -- リターン・コード
      ov_errmsg          => lv_errmsg);                   -- ユーザー・エラー・メッセージ
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 仕入単価が１つでも取得できなかった場合は警告終了
    IF (gn_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ユーザー定義例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
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
  PROCEDURE main(
    errbuf             OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode            OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_date_type       IN  VARCHAR2,      --   日付タイプ(1:製造日 2:納入日)
    iv_start_date      IN  VARCHAR2,      --   期間開始日(YYYY/MM/DD)
    iv_end_date        IN  VARCHAR2,      --   期間終了日(YYYY/MM/DD)
    iv_commodity_type  IN  VARCHAR2,      --   商品区分
    iv_item_type       IN  VARCHAR2,      --   品目区分
    iv_item_code1      IN  VARCHAR2,      --   品目コード1
    iv_item_code2      IN  VARCHAR2,      --   品目コード2
    iv_item_code3      IN  VARCHAR2,      --   品目コード3
    iv_customer_code1  IN  VARCHAR2,      --   取引先コード1
    iv_customer_code2  IN  VARCHAR2,      --   取引先コード2
    iv_customer_code3  IN  VARCHAR2       --   取引先コード3
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
    gv_exec_user := FND_GLOBAL.USER_NAME;
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = FND_GLOBAL.PROG_APPL_ID
    AND    fcp.concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID
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
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_date_type       => iv_date_type,       -- 日付タイプ(1:製造日 2:納入日)
      iv_start_date      => iv_start_date,      -- 期間開始日(YYYY/MM/DD)
      iv_end_date        => iv_end_date,        -- 期間終了日(YYYY/MM/DD)
      iv_commodity_type  => iv_commodity_type,  -- 商品区分
      iv_item_type       => iv_item_type,       -- 品目区分
      iv_item_code1      => iv_item_code1,      -- 品目コード1
      iv_item_code2      => iv_item_code2,      -- 品目コード2
      iv_item_code3      => iv_item_code3,      -- 品目コード3
      iv_customer_code1  => iv_customer_code1,  -- 取引先コード1
      iv_customer_code2  => iv_customer_code2,  -- 取引先コード2
      iv_customer_code3  => iv_customer_code3,  -- 取引先コード3
      ov_errbuf          => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      ov_retcode         => lv_retcode,         -- リターン・コード             --# 固定 #
      ov_errmsg          => lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) OR (lv_retcode = gv_status_warn) THEN
      IF (lv_errmsg IS NULL) THEN
        IF (lv_retcode <> gv_status_warn) THEN
          --定型メッセージ・セット
          lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
        END IF;
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- D-15.リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
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
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxpo870003c;
/
