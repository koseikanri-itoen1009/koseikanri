CREATE OR REPLACE PACKAGE      XXCMM_004COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcmm_004common_pkg(spec)
 * Description            : 品目関連API
 * MD.070                 : MD070_IPO_XXCMM_共通関数
 * Version                : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  put_message              メッセージ出力
 *  proc_opmcost_ref         OPM原価反映処理
 *  proc_opmitem_categ_ref   OPM品目カテゴリ割当反映処理
 *  del_opmitem_categ        OPM品目カテゴリ割当削除処理
 *  proc_discitem_categ_ref  Disc品目カテゴリ割当反映処理
 *  del_discitem_categ       Disc品目カテゴリ割当削除処理
 *  proc_uom_class_ref       単位換算反映処理
 *  proc_conc_request        コンカレント実行(+実行待ち)
 *  ins_opm_item             OPM品目登録処理
 *  upd_opm_item             OPM品目更新処理
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/07    1.0   H.Yoshikawa      新規作成
 *  2009/04/10    1.2   H.Yoshikawa      障害T1_0215 対応(chk_single_byte を削除)
 *
 *****************************************************************************************/
--
  --==============================================
  -- 固定値
  --==============================================
  -- 品目ステータス
  cn_itm_status_num_tmp        CONSTANT NUMBER       := 10;                         -- 仮採番
  cn_itm_status_pre_reg        CONSTANT NUMBER       := 20;                         -- 仮登録
  cn_itm_status_regist         CONSTANT NUMBER       := 30;                         -- 本登録
  cn_itm_status_no_sch         CONSTANT NUMBER       := 40;                         -- 廃
  cn_itm_status_trn_only       CONSTANT NUMBER       := 50;                         -- Ｄ’
  cn_itm_status_no_use         CONSTANT NUMBER       := 60;                         -- Ｄ
  --
  -- 標準原価設定用コンスタント値
  cv_whse_code                 CONSTANT VARCHAR2(3)  := '000';                      -- 倉庫
  cv_cost_mthd_code            CONSTANT VARCHAR2(4)  := 'STDU';                     -- 原価方法
  cv_cost_analysis_code        CONSTANT VARCHAR2(4)  := '0000';                     -- 分析コード
  --
  -- 標準原価コンポーネント区分名
  cv_cost_cmpnt_01gen          CONSTANT VARCHAR2(5)  := '01GEN';                    -- 原料
  cv_cost_cmpnt_02sai          CONSTANT VARCHAR2(5)  := '02SAI';                    -- 再製費
  cv_cost_cmpnt_03szi          CONSTANT VARCHAR2(5)  := '03SZI';                    -- 資材費
  cv_cost_cmpnt_04hou          CONSTANT VARCHAR2(5)  := '04HOU';                    -- 包装費
  cv_cost_cmpnt_05gai          CONSTANT VARCHAR2(5)  := '05GAI';                    -- 外注管理費
  cv_cost_cmpnt_06hkn          CONSTANT VARCHAR2(5)  := '06HKN';                    -- 保管費
  cv_cost_cmpnt_07kei          CONSTANT VARCHAR2(5)  := '07KEI';                    -- その他経費
  --
  -- ファイルアップロードチェック関連
  cv_lookup_type_upload_obj    CONSTANT VARCHAR2(30) := 'XXCCP1_FILE_UPLOAD_OBJ';   -- ファイルアップロードオブジェクト
  cv_null_ok                   CONSTANT VARCHAR2(10) := 'NULL_OK';                  -- 任意項目
  cv_null_ng                   CONSTANT VARCHAR2(10) := 'NULL_NG';                  -- 必須項目
  cv_varchar                   CONSTANT VARCHAR2(10) := 'VARCHAR2';                 -- 文字列
  cv_number                    CONSTANT VARCHAR2(10) := 'NUMBER';                   -- 数値
  cv_date                      CONSTANT VARCHAR2(10) := 'DATE';                     -- 日付
  cv_varchar_cd                CONSTANT VARCHAR2(1)  := '0';                        -- 文字列項目
  cv_number_cd                 CONSTANT VARCHAR2(1)  := '1';                        -- 数値項目
  cv_date_cd                   CONSTANT VARCHAR2(1)  := '2';                        -- 日付項目
  cv_not_null                  CONSTANT VARCHAR2(1)  := '1';                        -- 必須
  --
  -- 品目カテゴリセット名
  cv_categ_set_seisakugun      CONSTANT VARCHAR2(20) := '政策群コード';             -- 政策群
  cv_categ_set_hon_prod        CONSTANT VARCHAR2(20) := '本社商品区分';             -- 本社商品区分
  cv_categ_set_item_prod       CONSTANT VARCHAR2(20) := '商品製品区分';             -- 商品製品区分
  --
  -- 日付書式
  cv_date_fmt_ymd              CONSTANT VARCHAR2(10) := 'YYYYMMDD';                 -- YYYYMMDD
  cv_date_fmt_std              CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';               -- YYYY/MM/DD
  cv_date_fmt_dt_ymdhms        CONSTANT VARCHAR2(20) := 'YYYYMMDDHH24MISS';         -- YYYYMMDDHH24MISS
  cv_date_fmt_dt_std           CONSTANT VARCHAR2(25) := 'YYYY/MM/DD HH24:MI:SS';    -- YYYY/MM/DD HH24:MI:SS
  --
  --==============================================
  -- レコードタイプ
  --==============================================
  -- 原価（ヘッダ）反映用レコードタイプ
  TYPE opm_cost_header_rtype IS RECORD
  ( calendar_code      cm_cmpt_dtl.calendar_code%TYPE          -- カレンダコード（必須）
   ,period_code        cm_cmpt_dtl.period_code%TYPE            -- 期間コード（必須）
   ,item_id            ic_item_mst_b.item_id%TYPE              -- OPM品目ID（必須）
  );
  --
  -- 原価（明細）反映用レコードタイプ
  TYPE opm_cost_dist_rtype IS RECORD
  ( cmpntcost_id       cm_cmpt_dtl.cmpntcost_id%TYPE           -- OPM原価ID（更新時のみに使用可能。設定しなくてもコンポーネントIDが設定されていれば大丈夫）
   ,cost_cmpntcls_id   cm_cmpt_mst_b.cost_cmpntcls_id%TYPE     -- コンポーネントID（登録・更新どちらも必須）
   ,cmpnt_cost         cm_cmpt_dtl.cmpnt_cost%TYPE             -- 原価（必須）
  );
  --
  -- OPM品目カテゴリ割当用レコードタイプ
  TYPE opmitem_category_rtype IS RECORD
  ( item_id            ic_item_mst_b.item_id%TYPE              -- OPM品目ID
   ,category_set_id    mtl_category_sets.category_set_id%TYPE  -- カテゴリセットID
   ,category_id        mtl_categories.category_id%TYPE         -- カテゴリID
  );
  -- Disc品目カテゴリ割当用レコードタイプ
  TYPE discitem_category_rtype IS RECORD
  ( inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE  -- Disc品目ID
   ,category_set_id    mtl_category_sets.category_set_id%TYPE     -- カテゴリセットID
   ,category_id        mtl_categories.category_id%TYPE            -- カテゴリID
  );
  --
  -- 区分間換算用レコードタイプ
  TYPE uom_class_conv_rtype IS RECORD
  ( inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE       -- Disc品目ID
   ,from_uom_code      mtl_uom_class_conversions.from_uom_code%TYPE    -- 単位コード（換算元） Disc品目の基準単位
   ,to_uom_code        mtl_uom_class_conversions.to_uom_code%TYPE      -- 単位コード（換算先）
   ,conversion_rate    mtl_uom_class_conversions.conversion_rate%TYPE  -- 換算レート（入り数）
  );
  --
  -- コンカレントパラメータ レコードタイプ
  TYPE conc_argument_rtype IS RECORD
  ( argument           VARCHAR2(100)    -- パラメータ
  );
  --
  --==============================================
  -- テーブルタイプ
  --==============================================
  -- 原価（明細）反映用テーブルタイプ
  TYPE opm_cost_dist_ttype IS TABLE OF opm_cost_dist_rtype INDEX BY BINARY_INTEGER;
  -- 
  -- コンカレントパラメータ テーブルタイプ
  TYPE conc_argument_ttype IS TABLE OF conc_argument_rtype INDEX BY BINARY_INTEGER;
  -- 
  /**********************************************************************************
   * Procedure Name   : put_message
   * Description      : メッセージ出力
   ***********************************************************************************/
  PROCEDURE put_message(
    iv_message_buff   IN       VARCHAR2                                        -- 出力メッセージ
   ,iv_output_div     IN       VARCHAR2 DEFAULT FND_FILE.OUTPUT                -- 出力区分
   ,ov_errbuf         OUT      VARCHAR2                                        -- エラー・メッセージ
   ,ov_retcode        OUT      VARCHAR2                                        -- リターン・コード
   ,ov_errmsg         OUT      VARCHAR2                                        -- ユーザー・エラー・メッセージ
  );
  --
  /**********************************************************************************
   * Procedure Name   : ins_opmitem_categ
   * Description      : OPM原価反映処理
   **********************************************************************************/
  PROCEDURE proc_opmcost_ref(
    i_cost_header_rec   IN         opm_cost_header_rtype   -- 原価ヘッダ
   ,i_cost_dist_tab     IN         opm_cost_dist_ttype     -- 原価明細
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- リターン・コード             --# 固定 #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ユーザー・エラー・メッセージ --# 固定 #
  );
  --
  /**********************************************************************************
   * Procedure Name   : proc_opmitem_categ_ref
   * Description      : OPM品目カテゴリ割当登録処理
   **********************************************************************************/
  PROCEDURE proc_opmitem_categ_ref(
    i_item_category_rec IN         opmitem_category_rtype
                                                      -- 品目カテゴリ割当レコードタイプ
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- リターン・コード             --# 固定 #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ユーザー・エラー・メッセージ --# 固定 #
  );
  --
  /**********************************************************************************
   * Procedure Name   : del_opmitem_categ
   * Description      : OPM品目カテゴリ割当削除処理
   **********************************************************************************/
  PROCEDURE del_opmitem_categ(
    i_item_category_rec IN         opmitem_category_rtype
                                                      -- 品目カテゴリ割当レコードタイプ
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- リターン・コード             --# 固定 #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ユーザー・エラー・メッセージ --# 固定 #
  );
  --
  /**********************************************************************************
   * Procedure Name   : proc_discitem_categ_ref
   * Description      : Disc品目カテゴリ割当登録処理
   **********************************************************************************/
  PROCEDURE proc_discitem_categ_ref(
    i_item_category_rec IN         discitem_category_rtype
                                                      -- Disc品目カテゴリ割当レコードタイプ
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- リターン・コード             --# 固定 #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ユーザー・エラー・メッセージ --# 固定 #
  );
  --
  /**********************************************************************************
   * Procedure Name   : del_discitem_categ
   * Description      : Disc品目カテゴリ割当削除処理
   **********************************************************************************/
  PROCEDURE del_discitem_categ(
    i_item_category_rec IN         discitem_category_rtype
                                                      -- Disc品目カテゴリ割当レコードタイプ
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- リターン・コード             --# 固定 #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ユーザー・エラー・メッセージ --# 固定 #
  );
  --
  /**********************************************************************************
   * Procedure Name   : proc_uom_class_ref
   * Description      : 単位換算反映処理
   **********************************************************************************/
  PROCEDURE proc_uom_class_ref(
    i_uom_class_conv_rec IN        uom_class_conv_rtype
                                                      -- 区分間換算反映用レコードタイプ
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- リターン・コード             --# 固定 #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ユーザー・エラー・メッセージ --# 固定 #
  );
  --
  /**********************************************************************************
   * Procedure Name   : proc_conc_request
   * Description      : コンカレント実行
   **********************************************************************************/
  PROCEDURE proc_conc_request(
    iv_appl_short_name  IN         VARCHAR2                 -- 1.アプリケーション短縮名【必須】
   ,iv_program          IN         VARCHAR2                 -- 2.コンカレントプログラム短縮名【必須】
   ,iv_description      IN         VARCHAR2 DEFAULT NULL    -- 3.摘要【指定不要】
   ,iv_start_time       IN         VARCHAR2 DEFAULT NULL    -- 4.要求開始時刻(DD-MON-YY HH24:MI[:SS])【指定不要】
   ,ib_sub_request      IN         BOOLEAN  DEFAULT FALSE   -- 5.サブリクエスト【指定不要】
   ,i_argument_tab      IN         conc_argument_ttype      -- 6.コンカレントパラメータ【任意】
   ,iv_wait_flag        IN         VARCHAR2 DEFAULT 'Y'     -- 7.コンカレント実行待ちフラグ
   ,on_request_id       OUT        NUMBER                   -- 8.要求ID
   ,ov_errbuf           OUT NOCOPY VARCHAR2                 -- エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT NOCOPY VARCHAR2                 -- リターン・コード             --# 固定 #
   ,ov_errmsg           OUT NOCOPY VARCHAR2                 -- ユーザー・エラー・メッセージ --# 固定 #
  );
  --
  /**********************************************************************************
   * Procedure Name   : ins_opm_item
   * Description      : OPM品目登録処理
   **********************************************************************************/
  PROCEDURE ins_opm_item(
    i_opm_item_rec      IN         ic_item_mst_b%ROWTYPE,  -- OPM品目レコードタイプ
    ov_errbuf           OUT NOCOPY VARCHAR2,               -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,               -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ --# 固定 #
  );
  --
  /**********************************************************************************
   * Procedure Name   : upd_opm_item
   * Description      : OPM品目更新処理
   **********************************************************************************/
  PROCEDURE upd_opm_item(
    i_opm_item_rec      IN         ic_item_mst_b%ROWTYPE,  -- OPM品目レコードタイプ
    ov_errbuf           OUT NOCOPY VARCHAR2,               -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,               -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ --# 固定 #
  );
  --
-- Ver1.2  2009/04/10  Del  H.Yoshikawa  障害T1_0215 対応
--  /**********************************************************************************
--   * Function Name    : chk_single_byte
--   * Description      : 半角チェック
--   **********************************************************************************/
--  FUNCTION chk_single_byte(
--    iv_chk_char IN VARCHAR2             --チェック対象文字列
--  )
--  RETURN BOOLEAN;
--  --
----ito->20090202 TEST
--  --業務日付取得関数
--  FUNCTION get_process_date
--    RETURN DATE;
-- End
--
END XXCMM_004COMMON_PKG;
/
