CREATE OR REPLACE PACKAGE BODY xxinv540001
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxinv540001(BODY)
 * Description            : 在庫照会画面データソースパッケージ(BODY)
 * MD.050                 : T_MD050_BPO_540_在庫照会Issue1.0.doc
 * MD.070                 : T_MD070_BPO_54A_在庫照会画面Draft1A.doc
 * Version                : 1.1
 *
 * Program List
 *  --------------------  ---- ----- -------------------------------------------------
 *   Name                 Type  Ret   Description
 *  --------------------  ---- ----- -------------------------------------------------
 *  blk_ilm_qry             P    -    データ取得
 *  get_parent_item_id      F   NUM   親品目ID取得
 *  get_attribute5          F   VAR   代表倉庫取得
 *  get_organization_id     F   NUM   在庫組織ID取得
 *  get_inv_stock_vol       F   NUM   手持在庫数取得
 *  get_supply_stock_plan   F   NUM   入庫予定数取得
 *  get_take_stock_plan     F   NUM   出庫予定数取得
 *  get_subtractable        F   NUM   引当可能数取得
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/01/16   1.0   Jun.Komatsu      新規作成
 *  2008/03/13   1.1   Jun.Komatsu      変更要求#15、#7対応
 *  2008/03/19   1.2   Jun.Komatsu      変更要求#15対応(2回目)
 *  2008/04/18   1.3   Jun.Komatsu      変更要求#43、#51対応
 *  2008/05/26   1.4   Kazuo.Kumamoto   変更要求##119対応
 *
 *****************************************************************************************/
--
  -- 定数宣言
  cv_status_normal        CONSTANT VARCHAR2(1)  := '0';
  cv_status_warning       CONSTANT VARCHAR2(1)  := '1';
  cv_status_error         CONSTANT VARCHAR2(1)  := '2';
  cv_yes                  CONSTANT VARCHAR2(1)  := 'Y';
  cv_no                   CONSTANT VARCHAR2(1)  := 'N';
  cv_lang_ja              CONSTANT VARCHAR2(2)  := 'JA';
  cv_date_format          CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  cv_type_xxcmn_l05       CONSTANT VARCHAR2(9)  := 'XXCMN_L05';
  cv_type_xxcmn_l06       CONSTANT VARCHAR2(9)  := 'XXCMN_L06';
  cv_type_xxcmn_l07       CONSTANT VARCHAR2(9)  := 'XXCMN_L07';
  cv_type_xxcmn_l08       CONSTANT VARCHAR2(9)  := 'XXCMN_L08';
  cv_type_xxcmn_l03       CONSTANT VARCHAR2(9)  := 'XXCMN_L03';
  cv_type_xxwip_qt_status CONSTANT VARCHAR2(15) := 'XXWIP_QT_STATUS';
  cv_dummy                CONSTANT VARCHAR2(11) := '@@@@@@@@@@@';       -- ダミー文字列
  cv_lot_seihin           CONSTANT VARCHAR2(1)  := '5';                 -- 製品(ロット品)
  cv_lot_hanseihin        CONSTANT VARCHAR2(1)  := '4';                 -- 半製品(ロット品)
  cv_lot_gennryou         CONSTANT VARCHAR2(1)  := '1';                 -- 原料(ロット品)
  cv_lot_shizai           CONSTANT VARCHAR2(1)  := '2';                 -- 資材(非ロット品)
  cv_unit_case            CONSTANT VARCHAR2(6)  := 'ケース';            -- 単位区分：ケース
  cn_zero                 CONSTANT NUMBER       := 0;
  cn_one                  CONSTANT NUMBER       := 1;
  cn_round_effect_num     CONSTANT NUMBER       := 3;                   -- 単位換算有効桁数
  cv_min_date             CONSTANT VARCHAR2(10) := '0000/00/00';
  cv_max_date             CONSTANT VARCHAR2(10) := '9999/99/99';
  cv_type_xxcmn_lotstatus CONSTANT VARCHAR2(16) := 'XXCMN_LOT_STATUS';
  cv_lot_code0            CONSTANT VARCHAR2(1)  := '0';                 -- 非ロット管理区分コード
  cv_lot_code1            CONSTANT VARCHAR2(1)  := '1';                 -- ロット管理区分コード
  cn_dummy                CONSTANT NUMBER       := 99999999999;         -- 品質依頼Noダミー(11桁)
--
  /***********************************************************************************
   * Procedure Name   : blk_ilm_qry
   * Description      : データ取得(REFカーソルオープン)
   ***********************************************************************************/
  PROCEDURE blk_ilm_qry(
              ior_ilm_data             IN OUT NOCOPY tbl_ilm_block,
              in_item_id               IN xxcmn_item_mst_v.item_id%TYPE,          --品目ID
              iv_parent_div            IN VARCHAR2,                               --親コード区分
              in_inventory_location_id IN xxcmn_item_locations_v.inventory_location_id%TYPE,
                                                                                  --保管倉庫ID
              iv_deleg_house           IN VARCHAR2,                               --代表倉庫照会
              iv_ext_warehouse         IN VARCHAR2,                               --倉庫抽出フラグ
              iv_item_div_code         IN xxcmn_item_categories_v.segment1%TYPE,  --品目区分コード
              iv_prod_div_code         IN xxcmn_item_categories_v.segment1%TYPE,  --商品区分コード
              iv_unit_div              IN VARCHAR2,                               --単位区分
              iv_qt_status_code        IN xxwip_qt_inspection.qt_effect1%TYPE,    --品質判定結果
              id_manu_date_from        IN DATE,                                   --製造年月日From
              id_manu_date_to          IN DATE,                                   --製造年月日To
              iv_prop_sign             IN ic_lots_mst.attribute2%TYPE,            --固有記号
              id_consume_from          IN DATE,                                   --賞味期限From
              id_consume_to            IN DATE,                                   --賞味期限To
              iv_lot_no                IN ic_lots_mst.lot_no%TYPE,                --ロット№
              iv_register_code         IN xxcmn_item_locations_v.customer_stock_whse%TYPE,
                                                                                  --名義コード
              id_effective_date        IN DATE,                                   --有効日付
              iv_ext_show              IN VARCHAR2)                               --在庫有だけ表示
  IS
--
    -- 変数宣言
    ln_parent_item_id        xxcmn_item_mst_b.parent_item_id%TYPE;                -- 親品目ID
    lv_attribute5            xxcmn_item_locations_v.frequent_whse%TYPE;           -- 代表倉庫
    ln_organization_id       xxcmn_item_locations_v.mtl_organization_id%TYPE;     -- 在庫組織ID
    ln_prof_xtt              NUMBER;                                              -- 在庫照会対象
    lv_prof_xid              VARCHAR2(8);                                         -- 品目区分
    lv_prof_xpd              VARCHAR2(8);                                         -- 商品区分
    ld_target_date           DATE;                                                -- 対象日付
    ln_cnt                   NUMBER;                                              -- 配列の添字
    ln_num_of_cases          xxcmn_item_mst_v.num_of_cases%TYPE;                  -- ケース入数
    ln_cnt_work              NUMBER;                                              -- 集計用索引
    lv_sort_flag             VARCHAR2(1);                                         -- ソートフラグ
    lv_frequent_whse         xxcmn_item_locations_v.frequent_whse%TYPE;
--
    -- カーソル宣言
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_a1 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id         = ln_parent_item_id
      AND    iiim.frequent_whse          = lv_frequent_whse
      AND    iiim.mtl_organization_id    = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_a2 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.frequent_whse         = lv_frequent_whse
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_a3 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_a4 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_a5 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.frequent_whse         = lv_frequent_whse
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_a6 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.frequent_whse         = lv_frequent_whse
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_a7 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id        = ln_parent_item_id
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_a8 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id        = ln_parent_item_id
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_a9 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_b1 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_b2 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.segment1),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_b3 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.segment1),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_b4 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_b5 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_b6 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.segment1),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'Y'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_b7 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.parent_item_id        = ln_parent_item_id
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.segment1),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_b8 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.frequent_whse         = lv_frequent_whse
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_b9 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.frequent_whse         = lv_frequent_whse
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_c1 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_c2 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_c3 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.frequent_whse         = lv_frequent_whse
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_c4 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.frequent_whse         = lv_frequent_whse
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_c5 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'Y'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_c6 IS
      SELECT NVL(iiim.frequent_whse, iiim.segment1),                   -- (代表)保管倉庫コード
            (SELECT NVL(xilv_freq.short_name, iiim.short_name)
             FROM   xxcmn_item_locations_v xilv_freq
             WHERE  xilv_freq.segment1 = iiim.frequent_whse),          -- (代表)保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      ORDER BY TO_NUMBER(NVL(iiim.frequent_whse, iiim.segment1)),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_c7 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_c8 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_c9 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.segment1),
               iiim.attribute1,
               iiim.attribute2;
--
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'Y'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_d1 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.mtl_organization_id   = ln_organization_id
      ORDER BY TO_NUMBER(iiim.segment1),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_d2 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.item_no),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目、保管倉庫入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_d3 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.item_no),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品
    --===============================================================
    CURSOR cur_data_d4 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.segment1),
               iiim.attribute1,
               iiim.attribute2;
    --
    --===============================================================
    -- 検索条件.親コード区分値          ⇒ 'N'
    -- 検索条件.代表倉庫照会値          ⇒ 'N'
    -- 検索条件.倉庫抽出フラグ値        ⇒ 'N'
    -- 検索条件.品目、倉庫入力パターン  ⇒ 品目のみ入力
    -- 検索条件.品目区分値              ⇒ 製品以外
    --===============================================================
    CURSOR cur_data_d5 IS
      SELECT iiim.segment1,                                            -- 保管倉庫コード
             iiim.short_name,                                          -- 保管倉庫名
             iiim.inventory_location_id,                               -- 保管倉庫ID
             iiim.item_id,                                             -- 品目ID
             iiim.item_no,                                             -- 品目コード
             iiim.item_short_name,                                     -- 品目名
             NVL(iiim.num_of_cases, cn_one),                           -- ケース入数
             DECODE(iiim.lot_ctl, cv_lot_code0, NULL, iiim.lot_no),    -- ロットNo
             iiim.lot_id,                                              -- ロットID
             FND_DATE.STRING_TO_DATE(iiim.attribute1, cv_date_format), -- 製造年月日(DFF1)
             FND_DATE.STRING_TO_DATE(iiim.attribute3, cv_date_format), -- 賞味期限(DFF3)
             iiim.attribute2,                                          -- 固有記号(DFF2)
             FND_DATE.STRING_TO_DATE(iiim.attribute4, cv_date_format), -- 初回納入日(DFF4)
             FND_DATE.STRING_TO_DATE(iiim.attribute5, cv_date_format), -- 最終納入日(DFF5)
             TO_NUMBER(iiim.attribute6),                               -- 在庫入数(DFF6)
             TO_NUMBER(iiim.attribute7),                               -- 在庫単価(DFF7)
             iiim.attribute8,                                          -- 受払先(DFF8)
             xvv.vendor_short_name,                                    -- 受払先名
             iiim.attribute9,                                          -- 仕入形態(DFF9)
             xlvv_xl5.meaning,                                         -- 仕入形態内容
             iiim.attribute10,                                         -- 茶期区分(DFF10)
             xlvv_xl6.meaning,                                         -- 茶期区分内容
             iiim.attribute11,                                         -- 年度(DFF11)
             iiim.attribute12,                                         -- 産地(DFF12)
             xlvv_xl7.meaning,                                         -- 産地内容
             iiim.attribute13,                                         -- タイプ(DFF13)
             xlvv_xl8.meaning,                                         -- タイプ内容
             iiim.attribute14,                                         -- ランク1(DFF14)
             iiim.attribute15,                                         -- ランク2(DFF15)
             iiim.attribute19,                                         -- ランク3(DFF19)
             iiim.attribute16,                                         -- 生産伝票区分(DFF16)
             xlvv_xl3.meaning,                                         -- 生産伝票区分内容
             iiim.attribute17,                                         -- ラインNo(DFF17)
             gr.routing_desc,                                          -- 工順摘要
             iiim.attribute18,                                         -- 摘要(DFF18)
             xlvv_xls.meaning,                                         -- ロットステータス内容
             xqi.qt_inspect_req_no,                                    -- 品質検査依頼情報
             xlvv_xqs.meaning,                                         -- 品質結果内容
             NVL(ili.loct_onhand, cn_zero),                            -- 手持数量
             get_inv_stock_vol(
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               NVL(ili.loct_onhand, cn_zero)),                         -- 手持在庫数
             get_subtractable(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 引当可能数
             get_supply_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_no,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 入庫予定数
             get_take_stock_plan(
               iiim.segment1,
               iiim.inventory_location_id,
               iiim.item_no,
               iiim.item_id,
               iiim.lot_id,
               id_effective_date,
               NVL(ili.loct_onhand, cn_zero)),                         -- 出庫予定数
             iiim.created_by,                                          -- 作成者
             iiim.creation_date,                                       -- 作成日
             iiim.last_updated_by,                                     -- 最終更新者
             iiim.last_update_date,                                    -- 最終更新日
             iiim.last_update_login,                                   -- 最終更新ログイン
             iiim.frequent_whse                                        -- 代表倉庫
      FROM   ic_loct_inv                ili,     -- OPM手持数量
             (SELECT xilv.segment1,              -- 保管倉庫
                     xilv.short_name,            -- 保管倉庫名
                     xilv.inventory_location_id, -- 保管倉庫ID
                     xilv.mtl_organization_id,   -- 在庫組織ID
                     xilv.frequent_whse,         -- 代表倉庫
                     xilv.customer_stock_whse,   -- 倉庫名義
                     ximv.item_id,               -- 品目ID
                     ximv.item_short_name,       -- 品目略称
                     ximv.parent_item_id,        -- 親品目ID
                     ximv.item_no,               -- 品目コード
                     ximv.lot_ctl,               -- ロット管理区分
                     ximv.num_of_cases,          -- ケース入数
                     ilm.lot_id,                 -- ロットID
                     ilm.lot_no,                 -- ロットNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute4,
                     ilm.attribute5,
                     ilm.attribute6,
                     ilm.attribute7,
                     ilm.attribute8,
                     ilm.attribute9,
                     ilm.attribute10,
                     ilm.attribute11,
                     ilm.attribute12,
                     ilm.attribute13,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute16,
                     ilm.attribute17,
                     ilm.attribute18,
                     ilm.attribute19,
                     ilm.attribute22,
                     ilm.attribute23,
                     ilm.created_by,
                     ilm.creation_date,
                     ilm.last_updated_by,
                     ilm.last_update_date,
                     ilm.last_update_login
              FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                     ic_lots_mst ilm,               -- OPMロットマスタ
                     xxcmn_item_locations_v  xilv,  -- OPM保管場所情報VIEW
                     xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                     xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
              WHERE  ximv.item_id            = ilm.item_id
              AND    xicv1.category_set_name = lv_prof_xid
              AND    xicv1.segment1          = iv_item_div_code
              AND    xicv1.item_id           = ximv.item_id
              AND    xicv2.item_id           = ximv.item_id
              AND    xicv2.category_set_name = lv_prof_xpd
              AND    xicv2.segment1          = NVL(iv_prod_div_code, xicv2.segment1)
              AND  ((ximv.lot_ctl            = cv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = cv_lot_code0)) iiim,
            (SELECT xq.qt_inspect_req_no,
--mod start 1.4
--                    NVL(NVL(xq.qt_effect3, xq.qt_effect2), xq.qt_effect1) AS qt_effect
                    CASE
                      WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                        xq.qt_effect3                      -- 結果3
                      WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                        xq.qt_effect2                      -- 結果2
                      WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                        xq.qt_effect1                      -- 結果1
                      ELSE
                        NULL
                    END  qt_effect
--mod end 1.4
             FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l05) xlvv_xl5,
                                                    -- クイックコード(仕入形態内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l06) xlvv_xl6,
                                                    -- クイックコード(茶期区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l07) xlvv_xl7,
                                                    -- クイックコード(産地内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l08) xlvv_xl8,
                                                    -- クイックコード(タイプ内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_l03) xlvv_xl3,
                                                    -- クイックコード(生産伝票区分内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxwip_qt_status) xlvv_xqs,
                                                    -- クイックコード(品質結果内容)
            (SELECT xlvv.lookup_code,
                    xlvv.meaning
             FROM   xxcmn_lookup_values_v xlvv
             WHERE  xlvv.lookup_type = cv_type_xxcmn_lotstatus) xlvv_xls,
                                                    -- クイックコード(ロットステータス)
             xxcmn_vendors_v            xvv,        -- 仕入先情報
            (SELECT grb.routing_no,
                    grt.routing_desc
             FROM   gmd_routings_b  grb,            -- 工順マスタ
                    gmd_routings_tl grt             -- 工順マスタ名称
             WHERE  grb.routing_id = grt.routing_id
             AND    grt.language   = cv_lang_ja) gr
      -- 品目(保管場所)と手持数量の関連付け
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- 名称取得
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    iiim.attribute9             = xlvv_xl5.lookup_code(+)
      AND    iiim.attribute10            = xlvv_xl6.lookup_code(+)
      AND    iiim.attribute12            = xlvv_xl7.lookup_code(+)
      AND    iiim.attribute13            = xlvv_xl8.lookup_code(+)
      AND    iiim.attribute16            = xlvv_xl3.lookup_code(+)
      AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
      AND    iiim.attribute23            = xlvv_xls.lookup_code(+)
      AND    iiim.attribute17            = gr.routing_no(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- 手持数量.最終更新日：在庫がない場合(EBS標準のマスタ未反映分)はシステム日付とする
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- 抽出条件(画面検索値)
      AND    iiim.customer_stock_whse    = iv_register_code
      AND    NVL(iiim.attribute3, cv_min_date)
             >= NVL(TO_CHAR(id_consume_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute3, cv_max_date)
             <= NVL(TO_CHAR(id_consume_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.lot_no, cv_dummy)  = NVL(NVL(iv_lot_no, iiim.lot_no), cv_dummy)
      AND    NVL(iiim.attribute1, cv_min_date)
             >= NVL(TO_CHAR(id_manu_date_from, cv_date_format), cv_min_date)
      AND    NVL(iiim.attribute1, cv_max_date)
             <= NVL(TO_CHAR(id_manu_date_to, cv_date_format), cv_max_date)
      AND    NVL(iiim.attribute2, cv_dummy) = NVL(NVL(iv_prop_sign, iiim.attribute2), cv_dummy)
      AND    NVL(xqi.qt_effect, cn_dummy)
             =  NVL(NVL(iv_qt_status_code, xqi.qt_effect), cn_dummy)
      -- 画面検索パターン別に異なる、カーソル毎の抽出、ソート条件
      AND    iiim.item_id               = NVL(in_item_id, iiim.item_id)
      AND    iiim.inventory_location_id = NVL(in_inventory_location_id, iiim.inventory_location_id)
      ORDER BY TO_NUMBER(iiim.segment1),
               DECODE(iiim.lot_id, cn_zero, TO_NUMBER(NULL), TO_NUMBER(iiim.lot_no));
--
  BEGIN
--
    -- プロファイル値取得
    ln_prof_xtt := FND_PROFILE.VALUE('XXINV_TARGET_TERM');
    lv_prof_xid := FND_PROFILE.VALUE('XXCMN_ARTICLE_DIV');
    lv_prof_xpd := FND_PROFILE.VALUE('XXCMN_ITEM_DIV');
--
    -- プロファイルより取得した日数から、在庫照会対象日付を算出
    ld_target_date := TRUNC(SYSDATE) - ln_prof_xtt;
--
    -- 親品目ID取得
    IF (iv_parent_div = cv_yes) THEN
      ln_parent_item_id := get_parent_item_id(
                             in_parent_item_id => in_item_id);
    END IF;
--
    -- 代表倉庫取得
    IF (iv_deleg_house = cv_yes) THEN
      lv_frequent_whse := get_attribute5(
                            in_inventory_location_id => in_inventory_location_id);
    END IF;
--
    -- 在庫組織ID取得
    IF (iv_ext_warehouse = cv_yes) THEN
      ln_organization_id := get_organization_id(
                              in_inventory_location_id => in_inventory_location_id);
    END IF;
--
    -- 変数の初期化
    ln_cnt := 1;
    lv_sort_flag := '0';
--
    -- カーソルの選定
    IF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_a1;
      -- レコードの取得
      <<fetch_cur_data_a1>>
      LOOP
        FETCH cur_data_a1 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a1%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
--
          <<calculation_a1>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- 代表倉庫に合算(手持数量)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- 代表倉庫に合算(手持在庫数)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- 代表倉庫に合算(引当可能数)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- 代表倉庫に合算(入庫予定数)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- 代表倉庫に合算(出庫予定数)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- 格納済み保管場所を代表倉庫に書換え(代表ではない保管場所が表示される不具合を解消)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- 今回取得したレコードを削除(代表に合算した為)
              ior_ilm_data.DELETE(ln_cnt);
              -- 配列カウンタを1減算
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_a1;
--
          -- 配列カウンタをインクリメント
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a1;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_a2;
      -- レコードの取得
      <<fetch_cur_data_a2>>
      LOOP
        FETCH cur_data_a2 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a2%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
--
          -- 単位換算処理
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
--
          <<calculation_a2>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- 代表倉庫に合算(手持数量)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- 代表倉庫に合算(手持在庫数)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- 代表倉庫に合算(引当可能数)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- 代表倉庫に合算(入庫予定数)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- 代表倉庫に合算(出庫予定数)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- 格納済み保管場所を代表倉庫に書換え(代表ではない保管場所が表示される不具合を解消)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- 今回取得したレコードを削除(代表に合算した為)
              ior_ilm_data.DELETE(ln_cnt);
              -- 配列カウンタを1減算
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_a2;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a2;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_a3;
      -- レコードの取得
      <<fetch_cur_data_a3>>
      LOOP
        FETCH cur_data_a3 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a3%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
--
          <<calculation_a3>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- 代表倉庫に合算(手持数量)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- 代表倉庫に合算(手持在庫数)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- 代表倉庫に合算(引当可能数)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- 代表倉庫に合算(入庫予定数)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- 代表倉庫に合算(出庫予定数)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
--
              -- 格納済み保管場所を代表倉庫に書換え(代表ではない保管場所が表示される不具合を解消)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- 今回取得したレコードを削除(代表に合算した為)
              ior_ilm_data.DELETE(ln_cnt);
              -- 配列カウンタを1減算
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_a3;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a3;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_a4;
      -- レコードの取得
      <<fetch_cur_data_a4>>
      LOOP
        FETCH cur_data_a4 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a4%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          <<calculation_a4>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- 代表倉庫に合算(手持数量)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- 代表倉庫に合算(手持在庫数)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- 代表倉庫に合算(引当可能数)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- 代表倉庫に合算(入庫予定数)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- 代表倉庫に合算(出庫予定数)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- 格納済み保管場所を代表倉庫に書換え(代表ではない保管場所が表示される不具合を解消)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- 今回取得したレコードを削除(代表に合算した為)
              ior_ilm_data.DELETE(ln_cnt);
              -- 配列カウンタを1減算
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_a4;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a4;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_a5;
      -- レコードの取得
      <<fetch_cur_data_a5>>
      LOOP
        FETCH cur_data_a5 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a5%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
--
          <<calculation_a5>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- 代表倉庫に合算(手持数量)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- 代表倉庫に合算(手持在庫数)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- 代表倉庫に合算(引当可能数)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- 代表倉庫に合算(入庫予定数)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- 代表倉庫に合算(出庫予定数)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- 格納済み保管場所を代表倉庫に書換え(代表ではない保管場所が表示される不具合を解消)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- 今回取得したレコードを削除(代表に合算した為)
              ior_ilm_data.DELETE(ln_cnt);
              -- 配列カウンタを1減算
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_a5;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a5;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_a6;
      -- レコードの取得
      <<fetch_cur_data_a6>>
      LOOP
        FETCH cur_data_a6 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a6%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
--
          <<calculation_a6>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- 代表倉庫に合算(手持数量)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- 代表倉庫に合算(手持在庫数)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- 代表倉庫に合算(引当可能数)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- 代表倉庫に合算(入庫予定数)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- 代表倉庫に合算(出庫予定数)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- 格納済み保管場所を代表倉庫に書換え(代表ではない保管場所が表示される不具合を解消)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- 今回取得したレコードを削除(代表に合算した為)
              ior_ilm_data.DELETE(ln_cnt);
              -- 配列カウンタを1減算
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_a6;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a6;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_a7;
      -- レコードの取得
      <<fetch_cur_data_a7>>
      LOOP
        FETCH cur_data_a7 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a7%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
--
          <<calculation_a7>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF (ior_ilm_data.EXISTS(ln_cnt_work)) THEN
              IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
                AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                  AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
              THEN
                IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
                THEN
                  -- ※今回処理したレコードが代表となる場合
                  -- 代表倉庫に合算(手持数量)
                  ior_ilm_data(ln_cnt).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- 代表倉庫に合算(手持在庫数)
                  ior_ilm_data(ln_cnt).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- 代表倉庫に合算(引当可能数)
                  ior_ilm_data(ln_cnt).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- 代表倉庫に合算(入庫予定数)
                  ior_ilm_data(ln_cnt).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- 代表倉庫に合算(出庫予定数)
                  ior_ilm_data(ln_cnt).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- 格納済み側のレコードを削除(代表に合算した為)
                  ior_ilm_data.DELETE(ln_cnt_work);
                  -- No振り直しの必要有り
                  lv_sort_flag := '1';
                  EXIT;
                ELSE
                -- ※既にレコード配列に格納された側のレコードが代表となる場合
                  -- 代表倉庫に合算(手持数量)
                  ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- 代表倉庫に合算(手持在庫数)
                  ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- 代表倉庫に合算(引当可能数)
                  ior_ilm_data(ln_cnt_work).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- 代表倉庫に合算(入庫予定数)
                  ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- 代表倉庫に合算(出庫予定数)
                  ior_ilm_data(ln_cnt_work).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- 今回取得したレコードを削除(代表に合算した為)
                  ior_ilm_data.DELETE(ln_cnt);
                  -- 配列カウンタを1減算
                  ln_cnt := ln_cnt - 1;
                  lv_sort_flag := '1';
                  EXIT;
                END IF;
              END IF;
            END IF;
          END LOOP calculation_a7;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a7;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_a8;
      -- レコードの取得
      <<fetch_cur_data_a8>>
      LOOP
        FETCH cur_data_a8 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a8%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
--
          <<calculation_a8>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF (ior_ilm_data.EXISTS(ln_cnt_work)) THEN
              IF ((ior_ilm_data(ln_cnt_work).xilv_segment1
                                                           = ior_ilm_data(ln_cnt).xilv_segment1)
                AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                  AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
              THEN
                IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
                THEN
                  -- ※今回処理したレコードが代表となる場合
                  -- 代表倉庫に合算(手持数量)
                  ior_ilm_data(ln_cnt).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- 代表倉庫に合算(手持在庫数)
                  ior_ilm_data(ln_cnt).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- 代表倉庫に合算(引当可能数)
                  ior_ilm_data(ln_cnt).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- 代表倉庫に合算(入庫予定数)
                  ior_ilm_data(ln_cnt).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- 代表倉庫に合算(出庫予定数)
                  ior_ilm_data(ln_cnt).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- 格納済み側のレコードを削除(代表に合算した為)
                  ior_ilm_data.DELETE(ln_cnt_work);
                  -- No振り直しの必要有り
                  lv_sort_flag := '1';
                  EXIT;
                ELSE
                -- ※既にレコード配列に格納された側のレコードが代表となる場合
                  -- 代表倉庫に合算(手持数量)
                  ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- 代表倉庫に合算(手持在庫数)
                  ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- 代表倉庫に合算(引当可能数)
                  ior_ilm_data(ln_cnt_work).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- 代表倉庫に合算(入庫予定数)
                  ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- 代表倉庫に合算(出庫予定数)
                  ior_ilm_data(ln_cnt_work).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- 今回取得したレコードを削除(代表に合算した為)
                  ior_ilm_data.DELETE(ln_cnt);
                  -- 配列カウンタを1減算
                  ln_cnt := ln_cnt - 1;
                  lv_sort_flag := '1';
                  EXIT;
                END IF;
              END IF;
            END IF;
          END LOOP calculation_a8;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a8;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_a9;
      -- レコードの取得
      <<fetch_cur_data_a9>>
      LOOP
        FETCH cur_data_a9 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_a9%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_a9;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_b1;
      -- レコードの取得
      <<fetch_cur_data_b1>>
      LOOP
        FETCH cur_data_b1 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b1%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b1;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_b2;
      -- レコードの取得
      <<fetch_cur_data_b2>>
      LOOP
        FETCH cur_data_b2 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b2%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b2;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_b3;
      -- レコードの取得
      <<fetch_cur_data_b3>>
      LOOP
        FETCH cur_data_b3 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b3%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b3;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_b4;
      -- レコードの取得
      <<fetch_cur_data_b4>>
      LOOP
        FETCH cur_data_b4 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b4%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b4;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_b5;
      -- レコードの取得
      <<fetch_cur_data_b5>>
      LOOP
        FETCH cur_data_b5 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b5%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b5;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_b6;
      -- レコードの取得
      <<fetch_cur_data_b6>>
      LOOP
        FETCH cur_data_b6 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b6%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b6;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_yes)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_b7;
      -- レコードの取得
      <<fetch_cur_data_b7>>
      LOOP
        FETCH cur_data_b7 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b7%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b7;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_b8;
      -- レコードの取得
      <<fetch_cur_data_b8>>
      LOOP
        FETCH cur_data_b8 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b8%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
--
          <<calculation_b8>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- 代表倉庫に合算(手持数量)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- 代表倉庫に合算(手持在庫数)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- 代表倉庫に合算(引当可能数)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- 代表倉庫に合算(入庫予定数)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- 代表倉庫に合算(出庫予定数)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- 格納済み保管場所を代表倉庫に書換え(代表ではない保管場所が表示される不具合を解消)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- 今回取得したレコードを削除(代表に合算した為)
              ior_ilm_data.DELETE(ln_cnt);
              -- 配列カウンタを1減算
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_b8;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b8;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_b9;
      -- レコードの取得
      <<fetch_cur_data_b9>>
      LOOP
        FETCH cur_data_b9 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_b9%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
--
          <<calculation_b9>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- 代表倉庫に合算(手持数量)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- 代表倉庫に合算(手持在庫数)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- 代表倉庫に合算(引当可能数)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- 代表倉庫に合算(入庫予定数)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- 代表倉庫に合算(出庫予定数)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- 格納済み保管場所を代表倉庫に書換え(代表ではない保管場所が表示される不具合を解消)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- 今回取得したレコードを削除(代表に合算した為)
              ior_ilm_data.DELETE(ln_cnt);
              -- 配列カウンタを1減算
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_b9;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_b9;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_c1;
      -- レコードの取得
      <<fetch_cur_data_c1>>
      LOOP
        FETCH cur_data_c1 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c1%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
--
          <<calculation_c1>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- 代表倉庫に合算(手持数量)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- 代表倉庫に合算(手持在庫数)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- 代表倉庫に合算(引当可能数)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- 代表倉庫に合算(入庫予定数)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- 代表倉庫に合算(出庫予定数)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- 格納済み保管場所を代表倉庫に書換え(代表ではない保管場所が表示される不具合を解消)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- 今回取得したレコードを削除(代表に合算した為)
              ior_ilm_data.DELETE(ln_cnt);
              -- 配列カウンタを1減算
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_c1;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c1;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_c2;
      -- レコードの取得
      <<fetch_cur_data_c2>>
      LOOP
        FETCH cur_data_c2 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c2%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
--
          <<calculation_c2>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- 代表倉庫に合算(手持数量)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- 代表倉庫に合算(手持在庫数)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- 代表倉庫に合算(引当可能数)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- 代表倉庫に合算(入庫予定数)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- 代表倉庫に合算(出庫予定数)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- 格納済み保管場所を代表倉庫に書換え(代表ではない保管場所が表示される不具合を解消)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- 今回取得したレコードを削除(代表に合算した為)
              ior_ilm_data.DELETE(ln_cnt);
              -- 配列カウンタを1減算
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_c2;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c2;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_c3;
      -- レコードの取得
      <<fetch_cur_data_c3>>
      LOOP
        FETCH cur_data_c3 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c3%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
--
          <<calculation_c3>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- 代表倉庫に合算(手持数量)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- 代表倉庫に合算(手持在庫数)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- 代表倉庫に合算(引当可能数)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- 代表倉庫に合算(入庫予定数)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- 代表倉庫に合算(出庫予定数)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- 格納済み保管場所を代表倉庫に書換え(代表ではない保管場所が表示される不具合を解消)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- 今回取得したレコードを削除(代表に合算した為)
              ior_ilm_data.DELETE(ln_cnt);
              -- 配列カウンタを1減算
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_c3;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c3;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_c4;
      -- レコードの取得
      <<fetch_cur_data_c4>>
      LOOP
        FETCH cur_data_c4 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c4%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
--
          <<calculation_c4>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
              AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
            THEN
              -- 代表倉庫に合算(手持数量)
              ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                 := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                  + ior_ilm_data(ln_cnt).ili_loct_onhand;
              -- 代表倉庫に合算(手持在庫数)
              ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                 := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                  + ior_ilm_data(ln_cnt).inv_stock_vol;
              -- 代表倉庫に合算(引当可能数)
              ior_ilm_data(ln_cnt_work).subtractable
                                                 := ior_ilm_data(ln_cnt_work).subtractable
                                                  + ior_ilm_data(ln_cnt).subtractable;
              -- 代表倉庫に合算(入庫予定数)
              ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                  + ior_ilm_data(ln_cnt).supply_stock_plan;
              -- 代表倉庫に合算(出庫予定数)
              ior_ilm_data(ln_cnt_work).take_stock_plan
                                                 := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                  + ior_ilm_data(ln_cnt).take_stock_plan;
              -- 格納済み保管場所を代表倉庫に書換え(代表ではない保管場所が表示される不具合を解消)
              IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
              THEN
                ior_ilm_data(ln_cnt_work).xilv_segment1 := ior_ilm_data(ln_cnt).xilv_segment1;
                ior_ilm_data(ln_cnt_work).xilv_description := ior_ilm_data(ln_cnt).xilv_description;
                ior_ilm_data(ln_cnt_work).xilv_inventory_location_id
                                                 := ior_ilm_data(ln_cnt).xilv_inventory_location_id;
              END IF;
              -- 今回取得したレコードを削除(代表に合算した為)
              ior_ilm_data.DELETE(ln_cnt);
              -- 配列カウンタを1減算
              ln_cnt := ln_cnt - 1;
              lv_sort_flag := '1';
              EXIT;
            END IF;
          END LOOP calculation_c4;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c4;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no)   = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_c5;
      -- レコードの取得
      <<fetch_cur_data_c5>>
      LOOP
        FETCH cur_data_c5 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c5%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
--
          <<calculation_c5>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF (ior_ilm_data.EXISTS(ln_cnt_work)) THEN
              IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
                AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                  AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
              THEN
                IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
                THEN
                  -- ※今回処理したレコードが代表となる場合
                  -- 代表倉庫に合算(手持数量)
                  ior_ilm_data(ln_cnt).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- 代表倉庫に合算(手持在庫数)
                  ior_ilm_data(ln_cnt).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- 代表倉庫に合算(引当可能数)
                  ior_ilm_data(ln_cnt).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- 代表倉庫に合算(入庫予定数)
                  ior_ilm_data(ln_cnt).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- 代表倉庫に合算(出庫予定数)
                  ior_ilm_data(ln_cnt).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- 格納済み側のレコードを削除(代表に合算した為)
                  ior_ilm_data.DELETE(ln_cnt_work);
                  -- No振り直しの必要有り
                  lv_sort_flag := '1';
                  EXIT;
                ELSE
                -- ※既にレコード配列に格納された側のレコードが代表となる場合
                  -- 代表倉庫に合算(手持数量)
                  ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- 代表倉庫に合算(手持在庫数)
                  ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- 代表倉庫に合算(引当可能数)
                  ior_ilm_data(ln_cnt_work).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- 代表倉庫に合算(入庫予定数)
                  ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- 代表倉庫に合算(出庫予定数)
                  ior_ilm_data(ln_cnt_work).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- 今回取得したレコードを削除(代表に合算した為)
                  ior_ilm_data.DELETE(ln_cnt);
                  -- 配列カウンタを1減算
                  ln_cnt := ln_cnt - 1;
                  lv_sort_flag := '1';
                  EXIT;
                END IF;
              END IF;
            END IF;
          END LOOP calculation_c5;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c5;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_yes)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_c6;
      -- レコードの取得
      <<fetch_cur_data_c6>>
      LOOP
        FETCH cur_data_c6 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c6%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
--
          <<calculation_c6>>
          FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
            IF (ior_ilm_data.EXISTS(ln_cnt_work)) THEN
              IF ((ior_ilm_data(ln_cnt_work).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_segment1)
                AND (ior_ilm_data(ln_cnt_work).ximv_item_id = ior_ilm_data(ln_cnt).ximv_item_id)
                  AND (ior_ilm_data(ln_cnt_work).ilm_lot_id = ior_ilm_data(ln_cnt).ilm_lot_id))
              THEN
                IF (ior_ilm_data(ln_cnt).xilv_segment1 = ior_ilm_data(ln_cnt).xilv_frequent_whse)
                THEN
                  -- ※今回処理したレコードが代表となる場合
                  -- 代表倉庫に合算(手持数量)
                  ior_ilm_data(ln_cnt).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- 代表倉庫に合算(手持在庫数)
                  ior_ilm_data(ln_cnt).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- 代表倉庫に合算(引当可能数)
                  ior_ilm_data(ln_cnt).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- 代表倉庫に合算(入庫予定数)
                  ior_ilm_data(ln_cnt).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- 代表倉庫に合算(出庫予定数)
                  ior_ilm_data(ln_cnt).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- 格納済み側のレコードを削除(代表に合算した為)
                  ior_ilm_data.DELETE(ln_cnt_work);
                  -- No振り直しの必要有り
                  lv_sort_flag := '1';
                  EXIT;
                ELSE
                -- ※既にレコード配列に格納された側のレコードが代表となる場合
                  -- 代表倉庫に合算(手持数量)
                  ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                     := ior_ilm_data(ln_cnt_work).ili_loct_onhand
                                                      + ior_ilm_data(ln_cnt).ili_loct_onhand;
                  -- 代表倉庫に合算(手持在庫数)
                  ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                     := ior_ilm_data(ln_cnt_work).inv_stock_vol
                                                      + ior_ilm_data(ln_cnt).inv_stock_vol;
                  -- 代表倉庫に合算(引当可能数)
                  ior_ilm_data(ln_cnt_work).subtractable
                                                     := ior_ilm_data(ln_cnt_work).subtractable
                                                      + ior_ilm_data(ln_cnt).subtractable;
                  -- 代表倉庫に合算(入庫予定数)
                  ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).supply_stock_plan
                                                      + ior_ilm_data(ln_cnt).supply_stock_plan;
                  -- 代表倉庫に合算(出庫予定数)
                  ior_ilm_data(ln_cnt_work).take_stock_plan
                                                     := ior_ilm_data(ln_cnt_work).take_stock_plan
                                                      + ior_ilm_data(ln_cnt).take_stock_plan;
                  -- 今回取得したレコードを削除(代表に合算した為)
                  ior_ilm_data.DELETE(ln_cnt);
                  -- 配列カウンタを1減算
                  ln_cnt := ln_cnt - 1;
                  lv_sort_flag := '1';
                  EXIT;
                END IF;
              END IF;
            END IF;
          END LOOP calculation_c6;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c6;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_c7;
      -- レコードの取得
      <<fetch_cur_data_c7>>
      LOOP
        FETCH cur_data_c7 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c7%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c7;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_c8;
      -- レコードの取得
      <<fetch_cur_data_c8>>
      LOOP
        FETCH cur_data_c8 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c8%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c8;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_c9;
      -- レコードの取得
      <<fetch_cur_data_c9>>
      LOOP
        FETCH cur_data_c9 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_c9%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_c9;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_yes)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_d1;
      -- レコードの取得
      <<fetch_cur_data_d1>>
      LOOP
        FETCH cur_data_d1 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_d1%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_d1;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_d2;
      -- レコードの取得
      <<fetch_cur_data_d2>>
      LOOP
        FETCH cur_data_d2 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_d2%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_d2;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND (NOT ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL)))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_d3;
      -- レコードの取得
      <<fetch_cur_data_d3>>
      LOOP
        FETCH cur_data_d3 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_d3%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_d3;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code = cv_lot_seihin))
    THEN
      OPEN cur_data_d4;
      -- レコードの取得
      <<fetch_cur_data_d4>>
      LOOP
        FETCH cur_data_d4 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_d4%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_d4;
--
    ELSIF ((NVL(iv_parent_div, cv_no) = cv_no)
      AND (NVL(iv_deleg_house, cv_no) = cv_no)
        AND (NVL(iv_ext_warehouse, cv_no) = cv_no)
          AND ((in_item_id IS NOT NULL)
            AND (in_inventory_location_id IS NULL))
              AND (iv_item_div_code <> cv_lot_seihin))
    THEN
      OPEN cur_data_d5;
      -- レコードの取得
      <<fetch_cur_data_d5>>
      LOOP
        FETCH cur_data_d5 INTO
          ior_ilm_data(ln_cnt).xilv_segment1,
          ior_ilm_data(ln_cnt).xilv_description,
          ior_ilm_data(ln_cnt).xilv_inventory_location_id,
          ior_ilm_data(ln_cnt).ximv_item_id,
          ior_ilm_data(ln_cnt).ximv_item_no,
          ior_ilm_data(ln_cnt).ximv_item_short_name,
          ln_num_of_cases,
          ior_ilm_data(ln_cnt).ilm_lot_no,
          ior_ilm_data(ln_cnt).ilm_lot_id,
          ior_ilm_data(ln_cnt).ilm_attribute1,
          ior_ilm_data(ln_cnt).ilm_attribute3,
          ior_ilm_data(ln_cnt).ilm_attribute2,
          ior_ilm_data(ln_cnt).ilm_attribute4,
          ior_ilm_data(ln_cnt).ilm_attribute5,
          ior_ilm_data(ln_cnt).ilm_attribute6,
          ior_ilm_data(ln_cnt).ilm_attribute7,
          ior_ilm_data(ln_cnt).ilm_attribute8,
          ior_ilm_data(ln_cnt).xvv_vendor_short_name,
          ior_ilm_data(ln_cnt).ilm_attribute9,
          ior_ilm_data(ln_cnt).xlvv_xl5_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute10,
          ior_ilm_data(ln_cnt).xlvv_xl6_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute11,
          ior_ilm_data(ln_cnt).ilm_attribute12,
          ior_ilm_data(ln_cnt).xlvv_xl7_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute13,
          ior_ilm_data(ln_cnt).xlvv_xl8_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute14,
          ior_ilm_data(ln_cnt).ilm_attribute15,
          ior_ilm_data(ln_cnt).ilm_attribute19,
          ior_ilm_data(ln_cnt).ilm_attribute16,
          ior_ilm_data(ln_cnt).xlvv_xl3_meaning,
          ior_ilm_data(ln_cnt).ilm_attribute17,
          ior_ilm_data(ln_cnt).grb_routing_desc,
          ior_ilm_data(ln_cnt).ilm_attribute18,
          ior_ilm_data(ln_cnt).ilm_attribute23,
          ior_ilm_data(ln_cnt).xqi_qt_inspect_req_no,
          ior_ilm_data(ln_cnt).xlvv_xqs_meaning,
          ior_ilm_data(ln_cnt).ili_loct_onhand,
          ior_ilm_data(ln_cnt).inv_stock_vol,
          ior_ilm_data(ln_cnt).subtractable,
          ior_ilm_data(ln_cnt).supply_stock_plan,
          ior_ilm_data(ln_cnt).take_stock_plan,
          ior_ilm_data(ln_cnt).ilm_created_by,
          ior_ilm_data(ln_cnt).ilm_creation_date,
          ior_ilm_data(ln_cnt).ilm_last_updated_by,
          ior_ilm_data(ln_cnt).ilm_last_update_date,
          ior_ilm_data(ln_cnt).ilm_last_update_login,
          ior_ilm_data(ln_cnt).xilv_frequent_whse;
        EXIT WHEN cur_data_d5%NOTFOUND;
--
        ior_ilm_data(ln_cnt).rec_no := ln_cnt;
        ior_ilm_data(ln_cnt).ximv_num_of_cases := ln_num_of_cases;
--
        -- 在庫有だけ表示による抽出レコードの選定
        IF ((NVL(iv_ext_show, cv_no) = cv_yes)
          AND ((ior_ilm_data(ln_cnt).inv_stock_vol = cn_zero)
            AND (ior_ilm_data(ln_cnt).supply_stock_plan = cn_zero)
              AND (ior_ilm_data(ln_cnt).take_stock_plan = cn_zero)))
        THEN
          ior_ilm_data.DELETE(ln_cnt);
        ELSE
          IF ((iv_unit_div = cv_unit_case) AND (ln_num_of_cases <> cn_zero)) THEN
            -- 単位換算処理
            ior_ilm_data(ln_cnt).inv_stock_vol := ROUND(
              ior_ilm_data(ln_cnt).inv_stock_vol / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).subtractable := ROUND(
              ior_ilm_data(ln_cnt).subtractable / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).supply_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).supply_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            ior_ilm_data(ln_cnt).take_stock_plan := ROUND(
              ior_ilm_data(ln_cnt).take_stock_plan / ln_num_of_cases,
              cn_round_effect_num);
            -- 単位換算処理END
          END IF;
          ln_cnt := ln_cnt + 1;
        END IF;
      END LOOP fetch_cur_data_d5;
    END IF;
--
    IF (lv_sort_flag = '1') THEN
      -- 空要素を詰める
      <<cnt_work_loop>>
      FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
        IF (NOT (ior_ilm_data.EXISTS(ln_cnt_work))) THEN
          <<cnt_next_loop>>
          FOR ln_cnt_next IN (ln_cnt_work + 1) .. ln_cnt LOOP
            IF (ior_ilm_data.EXISTS(ln_cnt_next)) THEN
              ior_ilm_data(ln_cnt_work) := ior_ilm_data(ln_cnt_next);
              ior_ilm_data.DELETE(ln_cnt_next);
              EXIT;
            END IF;
          END LOOP cnt_next_loop;
        END IF;
      END LOOP cnt_work_loop;
      -- Noの振直し
      <<renumbering_loop>>
      FOR ln_cnt_work IN 1 .. (ln_cnt - 1) LOOP
        IF NOT(ior_ilm_data.EXISTS(ln_cnt_work)) THEN
          EXIT;
        END IF;
        ior_ilm_data(ln_cnt_work).rec_no := ln_cnt_work;
      END LOOP renumbering_loop;
    END IF;
--
  END blk_ilm_qry;
--
  /***********************************************************************************
   * Function Name    : get_parent_item_id
   * Description      : 親品目ID取得
   ***********************************************************************************/
  FUNCTION  get_parent_item_id(
              in_parent_item_id IN xxcmn_item_mst_v.item_id%TYPE)
              RETURN NUMBER
  IS
    -- 変数宣言
    on_parent_item_id   xxcmn_item_mst_b.parent_item_id%TYPE;
  BEGIN
--
    BEGIN
      SELECT ximv.parent_item_id
      INTO   on_parent_item_id
      FROM   xxcmn_item_mst_v ximv
      WHERE  ximv.item_id = in_parent_item_id;
    END;
--
    -- 取得した親品目IDをリターン
    RETURN on_parent_item_id;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
--
  END get_parent_item_id;
--
--
  /***********************************************************************************
   * Function Name    : get_attribute5
   * Description      : 代表倉庫取得
   ***********************************************************************************/
  FUNCTION  get_attribute5(
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE)
              RETURN VARCHAR2
  IS
    -- 変数宣言
    lv_frequent_whse   xxcmn_item_locations_v.frequent_whse%TYPE;
    lv_segment1        xxcmn_item_locations_v.segment1%TYPE;
  BEGIN
--
    BEGIN
      SELECT xilv.frequent_whse,    -- 代表倉庫
             xilv.segment1          -- 保管倉庫
      INTO   lv_frequent_whse,
             lv_segment1
      FROM   xxcmn_item_locations_v xilv
      WHERE  xilv.inventory_location_id = in_inventory_location_id;
    END;
--
    -- 代表倉庫＝保管倉庫の場合、取得した代表倉庫をリターン
    IF (NVL(lv_frequent_whse, cv_dummy) = lv_segment1) THEN
      RETURN lv_frequent_whse;
    ELSE
      RETURN NULL;
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_attribute5;
--
--
  /***********************************************************************************
   * Function Name    : get_organization_id
   * Description      : 在庫組織ID取得
   ***********************************************************************************/
  FUNCTION  get_organization_id(
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE)
              RETURN NUMBER
  IS
    -- 変数宣言
    on_organization_id  mtl_item_locations.organization_id%TYPE;
  BEGIN
--
    BEGIN
      SELECT xilv.mtl_organization_id
      INTO   on_organization_id
      FROM   xxcmn_item_locations_v xilv
      WHERE  xilv.inventory_location_id = in_inventory_location_id;
    END;
--
    -- 取得した在庫組織IDをリターン
    RETURN on_organization_id;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_organization_id;
--
--
  /***********************************************************************************
   * Function Name    : get_inv_stock_vol
   * Description      : 手持在庫数取得
   ***********************************************************************************/
  FUNCTION  get_inv_stock_vol(
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE,
              iv_item_no                IN xxcmn_item_mst_v.item_no%TYPE,
              in_item_id                IN xxcmn_item_mst_v.item_id%TYPE,
              in_lot_id                 IN ic_lots_mst.lot_id%TYPE,
              in_loct_onhand            IN ic_loct_inv.loct_onhand%TYPE)
              RETURN NUMBER
  IS
--
    -- 変数宣言
    ln_temp_inv_stock_vol           NUMBER;
    ln_lot_id                       ic_lots_mst.lot_id%TYPE;
    lv_lot_ctl                      xxcmn_item_mst_v.lot_ctl%TYPE;
  BEGIN
--
    -- ロット管理区分取得
    BEGIN
      SELECT ximv.lot_ctl
      INTO   lv_lot_ctl
      FROM   xxcmn_item_mst_v ximv
      WHERE  ximv.item_id = in_item_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- 手持在庫数量算出API引数.ロットIDの設定
    IF (lv_lot_ctl = cv_lot_code1) THEN
      -- ロット管理品の場合、抽出したロットIDを設定
      ln_lot_id := in_lot_id;
    ELSE
      -- 非ロット管理品の場合、NULLを設定
      ln_lot_id := NULL;
    END IF;
--
    -- 共通関数｢手持在庫数量算出API｣コール
    ln_temp_inv_stock_vol := xxcmn_common2_pkg.get_stock_qty(
                               in_whse_id => in_inventory_location_id,  -- OPM保管倉庫ID
                               in_item_id => in_item_id,                -- OPM品目ID
                               in_lot_id  => ln_lot_id);                -- ロットID
--
    RETURN ln_temp_inv_stock_vol;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_inv_stock_vol;
--
--
  /***********************************************************************************
   * Function Name    : get_supply_stock_plan
   * Description      : 入庫予定数取得
   ***********************************************************************************/
  FUNCTION  get_supply_stock_plan(
              iv_segment1               IN xxcmn_item_locations_v.segment1%TYPE,
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE,
              iv_item_no                IN xxcmn_item_mst_v.item_no%TYPE,
              in_item_id                IN xxcmn_item_mst_v.item_id%TYPE,
              iv_lot_no                 IN ic_lots_mst.lot_no%TYPE,
              in_lot_id                 IN ic_lots_mst.lot_id%TYPE,
              id_effective_date         IN DATE,
              in_loct_onhand            IN ic_loct_inv.loct_onhand%TYPE)
              RETURN NUMBER
  IS
--
    -- 変数宣言
    lv_errbuf                       VARCHAR2(2000);
    lv_retcode                      VARCHAR2(1);
    lv_errmsg                       VARCHAR2(2000);
    ln_hacchu_ukeire_yotei          NUMBER;    -- 入庫予定数(7-2:発注受入予定)
    ln_idou_nyuuko_yotei_shiji      NUMBER;    -- 入庫予定数(7-3:移動入庫予定 指示)
    ln_idou_nyuuko_yotei_shukko     NUMBER;    -- 入庫予定数(7-4:移動入庫予定 出庫報告有)
    ln_seisan_yotei                 NUMBER;    -- 入庫予定数(7-5:生産予定)
    ln_temp_supply_stock_plan       NUMBER;    -- 入庫予定数退避
    ld_max_date                     DATE;      -- 最大日付格納変数
    lv_lot_ctl                      xxcmn_item_mst_v.lot_ctl%TYPE;
  BEGIN
--
    -- 変数初期化
    ln_hacchu_ukeire_yotei      := 0;
    ln_idou_nyuuko_yotei_shiji  := 0;
    ln_idou_nyuuko_yotei_shukko := 0;
    ln_seisan_yotei             := 0;
--
    -- 有効日付がNULLであれば、日付範囲なしに数量を取得する
    IF (id_effective_date IS NULL) THEN
      ld_max_date := FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), cv_date_format);
    ELSIF (id_effective_date IS NOT NULL) THEN
      ld_max_date := id_effective_date;
    END IF;
--
    -- ロット管理区分取得
    BEGIN
      SELECT ximv.lot_ctl
      INTO   lv_lot_ctl
      FROM   xxcmn_item_mst_v ximv
      WHERE  ximv.item_id = in_item_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    IF (lv_lot_ctl = cv_lot_code1) THEN
      -- ※ロット品※
      -- 入庫予定数(7-2:発注受入予定)
      xxcmn_common2_pkg.get_sup_lot_order_qty(
        iv_whse_code => iv_segment1,             -- 保管倉庫コード
        iv_item_code => iv_item_no,              -- 品目コード
        iv_lot_no    => iv_lot_no,               -- ロットNO
        id_eff_date  => ld_max_date,             -- 有効日付
        on_qty       => ln_hacchu_ukeire_yotei,  -- 数量
        ov_errbuf    => lv_errbuf,               -- エラー・メッセージ           --# 固定 #
        ov_retcode   => lv_retcode,              -- リターン・コード             --# 固定 #
        ov_errmsg    => lv_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 入庫予定数(7-3:移動入庫予定 指示)
      xxcmn_common2_pkg.get_sup_lot_inv_in_qty(
        in_whse_id  => in_inventory_location_id,       -- 保管倉庫ID
        in_item_id  => in_item_id,                     -- 品目ID
        in_lot_id   => in_lot_id,                      -- ロットID
        id_eff_date => ld_max_date,                    -- 有効日付
        on_qty      => ln_idou_nyuuko_yotei_shiji,     -- 数量
        ov_errbuf   => lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,                     -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 入庫予定数(7-4:移動入庫予定 出庫報告有)
      xxcmn_common2_pkg.get_sup_lot_inv_out_qty(
        in_whse_id  => in_inventory_location_id,       -- 保管倉庫ID
        in_item_id  => in_item_id,                     -- 品目ID
        in_lot_id   => in_lot_id,                      -- ロットID
        id_eff_date => ld_max_date,                    -- 有効日付
        on_qty      => ln_idou_nyuuko_yotei_shukko,    -- 数量
        ov_errbuf   => lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,                     -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 入庫予定数(7-5:生産予定)
      xxcmn_common2_pkg.get_sup_lot_produce_qty(
        iv_whse_code => iv_segment1,             -- 保管倉庫コード
        in_item_id   => in_item_id,              -- 品目ID
        in_lot_id    => in_lot_id,               -- ロットID
        id_eff_date  => ld_max_date,             -- 有効日付
        on_qty       => ln_seisan_yotei,         -- 数量
        ov_errbuf    => lv_errbuf,               -- エラー・メッセージ           --# 固定 #
        ov_retcode   => lv_retcode,              -- リターン・コード             --# 固定 #
        ov_errmsg    => lv_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
      -- ※ロット品END※
    ELSIF (lv_lot_ctl = cv_lot_code0) THEN
--
      -- ※非ロット品※
      -- 入庫予定数(7-2:発注受入予定)
      xxcmn_common2_pkg.get_sup_order_qty(
        iv_whse_code => iv_segment1,             -- 保管倉庫コード
        iv_item_code => iv_item_no,              -- 品目コード
        id_eff_date  => ld_max_date,             -- 有効日付
        on_qty       => ln_hacchu_ukeire_yotei,  -- 数量
        ov_errbuf    => lv_errbuf,               -- エラー・メッセージ           --# 固定 #
        ov_retcode   => lv_retcode,              -- リターン・コード             --# 固定 #
        ov_errmsg    => lv_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      --入庫予定数(7-3:移動入庫予定 指示)
      xxcmn_common2_pkg.get_sup_inv_in_qty(
        in_whse_id  => in_inventory_location_id,       -- 保管倉庫ID
        in_item_id  => in_item_id,                     -- 品目ID
        id_eff_date => ld_max_date,                    -- 有効日付
        on_qty      => ln_idou_nyuuko_yotei_shiji,     -- 数量
        ov_errbuf   => lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,                     -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 入庫予定数(7-4:移動入庫予定 出庫報告有)
      xxcmn_common2_pkg.get_sup_inv_out_qty(
        in_whse_id  => in_inventory_location_id,       -- 保管倉庫ID
        in_item_id  => in_item_id,                     -- 品目ID
        id_eff_date => ld_max_date,                    -- 有効日付
        on_qty      => ln_idou_nyuuko_yotei_shukko,    -- 数量
        ov_errbuf   => lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,                     -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
      -- ※非ロット品END※
    END IF;
--
    -- 各共通関数にて取得した値をサマリ = 入庫予定数
    ln_temp_supply_stock_plan := ln_hacchu_ukeire_yotei
                               + ln_idou_nyuuko_yotei_shiji
                               + ln_idou_nyuuko_yotei_shukko
                               + ln_seisan_yotei;
--
    RETURN ln_temp_supply_stock_plan;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_supply_stock_plan;
--
--
  /***********************************************************************************
   * Function Name    : get_take_stock_plan
   * Description      : 出庫予定数取得
   ***********************************************************************************/
  FUNCTION  get_take_stock_plan(
              iv_segment1               IN xxcmn_item_locations_v.segment1%TYPE,
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE,
              iv_item_no                IN xxcmn_item_mst_v.item_no%TYPE,
              in_item_id                IN xxcmn_item_mst_v.item_id%TYPE,
              in_lot_id                 IN ic_lots_mst.lot_id%TYPE,
              id_effective_date         IN DATE,
              in_loct_onhand            IN ic_loct_inv.loct_onhand%TYPE)
              RETURN NUMBER
  IS
--
    -- 変数宣言
    lv_errbuf                       VARCHAR2(2000);
    lv_retcode                      VARCHAR2(1);
    lv_errmsg                       VARCHAR2(2000);
    ln_idou_shukko_yotei_shiji      NUMBER;    -- 出庫予定数(7-6:移動出庫予定 指示)
    ln_idou_shukko_yotei_nyuuko     NUMBER;    -- 出庫予定数(7-7:移動出庫予定 入庫報告有)
    ln_shukka_yotei                 NUMBER;    -- 出庫予定数(7-8:出荷予定)
    ln_yuushou_shukka_yotei         NUMBER;    -- 出庫予定数(7-9:有償出荷予定)
    ln_seisan_gen_tounyuu_yotei     NUMBER;    -- 出庫予定数(7-10:生産原料投入予定)
    ln_aitesaki_zaiko               NUMBER;    -- 出庫予定数(7-11:相手先在庫)
    ln_temp_take_stock_plan         NUMBER;    -- 出庫予定数退避
    ld_max_date                     DATE;      -- 最大日付格納変数
    lv_lot_ctl                      xxcmn_item_mst_v.lot_ctl%TYPE;
  BEGIN
--
    -- 変数初期化
    ln_idou_shukko_yotei_shiji  := 0;
    ln_idou_shukko_yotei_nyuuko := 0;
    ln_shukka_yotei             := 0;
    ln_yuushou_shukka_yotei     := 0;
    ln_seisan_gen_tounyuu_yotei := 0;
    ln_aitesaki_zaiko           := 0;
--
    -- 有効日付がNULLであれば、日付範囲なしに数量を取得する
    IF (id_effective_date IS NULL) THEN
      ld_max_date := FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), cv_date_format);
    ELSIF (id_effective_date IS NOT NULL) THEN
      ld_max_date := id_effective_date;
    END IF;
--
    -- ロット管理区分取得
    BEGIN
      SELECT ximv.lot_ctl
      INTO   lv_lot_ctl
      FROM   xxcmn_item_mst_v ximv
      WHERE  ximv.item_id = in_item_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    IF (lv_lot_ctl = cv_lot_code1) THEN
--
      -- ※ロット品※
      -- 出庫予定数(7-6:移動出庫予定 指示)
      xxcmn_common2_pkg.get_dem_lot_inv_out_qty(
        in_whse_id  => in_inventory_location_id,       -- 保管倉庫ID
        in_item_id  => in_item_id,                     -- 品目ID
        in_lot_id   => in_lot_id,                      -- ロットID
        id_eff_date => ld_max_date,                    -- 有効日付
        on_qty      => ln_idou_shukko_yotei_shiji,     -- 数量
        ov_errbuf   => lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,                     -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 出庫予定数(7-7:移動出庫予定 入庫報告有)
      xxcmn_common2_pkg.get_dem_lot_inv_in_qty(
        in_whse_id  => in_inventory_location_id,       -- 保管倉庫ID
        in_item_id  => in_item_id,                     -- 品目ID
        in_lot_id   => in_lot_id,                      -- ロットID
        id_eff_date => ld_max_date,                    -- 有効日付
        on_qty      => ln_idou_shukko_yotei_nyuuko,    -- 数量
        ov_errbuf   => lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,                     -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 出庫予定数(7-8:出荷予定)
      xxcmn_common2_pkg.get_dem_lot_ship_qty(
        in_whse_id  => in_inventory_location_id,       -- 保管倉庫ID
        in_item_id  => in_item_id,                     -- 品目ID
        in_lot_id   => in_lot_id,                      -- ロットID
        id_eff_date => ld_max_date,                    -- 有効日付
        on_qty      => ln_shukka_yotei,                -- 数量
        ov_errbuf   => lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,                     -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 出庫予定数(7-9:有償出荷予定)
      xxcmn_common2_pkg.get_dem_lot_provide_qty(
        in_whse_id  => in_inventory_location_id,       -- 保管倉庫ID
        in_item_id  => in_item_id,                     -- 品目ID
        in_lot_id   => in_lot_id,                      -- ロットID
        id_eff_date => ld_max_date,                    -- 有効日付
        on_qty      => ln_yuushou_shukka_yotei,        -- 数量
        ov_errbuf   => lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,                     -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 出庫予定数(7-10:生産原料投入予定)
      xxcmn_common2_pkg.get_dem_lot_produce_qty(
        iv_whse_code => iv_segment1,                   -- 保管倉庫ID
        in_item_id   => in_item_id,                    -- 品目ID
        in_lot_id    => in_lot_id,                     -- ロットID
        id_eff_date  => ld_max_date,                   -- 有効日付
        on_qty       => ln_seisan_gen_tounyuu_yotei,   -- 数量
        ov_errbuf    => lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
        ov_retcode   => lv_retcode,                    -- リターン・コード             --# 固定 #
        ov_errmsg    => lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 出庫予定数(7-11:相手先在庫)
      xxcmn_common2_pkg.get_dem_lot_order_qty(
        iv_whse_code => iv_segment1,                   -- 保管倉庫コード
        iv_item_code => iv_item_no,                    -- 品目コード
        in_lot_id    => in_lot_id,                     -- ロットID
        id_eff_date  => ld_max_date,                   -- 有効日付
        on_qty       => ln_aitesaki_zaiko,             -- 数量
        ov_errbuf    => lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
        ov_retcode   => lv_retcode,                    -- リターン・コード             --# 固定 #
        ov_errmsg    => lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
          RETURN NULL;
      END IF;
      -- ※ロット品END※
    ELSIF (lv_lot_ctl = cv_lot_code0) THEN
--
      -- ※非ロット品※
      -- 出庫予定数(7-6:移動出庫予定 指示)
      xxcmn_common2_pkg.get_dem_inv_out_qty(
        in_whse_id  => in_inventory_location_id,       -- 保管倉庫ID
        in_item_id  => in_item_id,                     -- 品目ID
        id_eff_date => ld_max_date,                    -- 有効日付
        on_qty      => ln_idou_shukko_yotei_shiji,     -- 数量
        ov_errbuf   => lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,                     -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 出庫予定数(7-7:移動出庫予定 入庫報告有)
      xxcmn_common2_pkg.get_dem_inv_in_qty(
        in_whse_id  => in_inventory_location_id,       -- 保管倉庫ID
        in_item_id  => in_item_id,                     -- 品目ID
        id_eff_date => ld_max_date,                    -- 有効日付
        on_qty      => ln_idou_shukko_yotei_nyuuko,    -- 数量
        ov_errbuf   => lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,                     -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 出庫予定数(7-8:出荷予定)
      xxcmn_common2_pkg.get_dem_ship_qty(
        in_whse_id   => in_inventory_location_id,      -- 保管倉庫ID
        iv_item_code => iv_item_no,                    -- 品目コード
        id_eff_date  => ld_max_date,                   -- 有効日付
        on_qty       => ln_shukka_yotei,               -- 数量
        ov_errbuf    => lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
        ov_retcode   => lv_retcode,                    -- リターン・コード             --# 固定 #
        ov_errmsg    => lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 出庫予定数(7-9:有償出荷予定)
      xxcmn_common2_pkg.get_dem_provide_qty(
        in_whse_id   => in_inventory_location_id,      -- 保管倉庫ID
        iv_item_code => iv_item_no,                    -- 品目コード
        id_eff_date  => ld_max_date,                   -- 有効日付
        on_qty       => ln_yuushou_shukka_yotei,       -- 数量
        ov_errbuf    => lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
        ov_retcode   => lv_retcode,                    -- リターン・コード             --# 固定 #
        ov_errmsg    => lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- 出庫予定数(7-10:生産原料投入予定)
      xxcmn_common2_pkg.get_dem_produce_qty(
        iv_whse_code => iv_segment1,                   -- 保管倉庫コード
        in_item_id   => in_item_id,                    -- 品目ID
        id_eff_date  => ld_max_date,                   -- 有効日付
        on_qty       => ln_seisan_gen_tounyuu_yotei,   -- 数量
        ov_errbuf    => lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
        ov_retcode   => lv_retcode,                    -- リターン・コード             --# 固定 #
        ov_errmsg    => lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 共通関数処理結果チェック
      IF (lv_retcode = cv_status_error) THEN
        RETURN NULL;
      END IF;
      -- ※非ロット品END※
    END IF;
--
    -- 共通関数にて取得した値をサマリ = 出庫予定数
    ln_temp_take_stock_plan := ln_idou_shukko_yotei_shiji
                             + ln_idou_shukko_yotei_nyuuko
                             + ln_shukka_yotei
                             + ln_yuushou_shukka_yotei
                             + ln_seisan_gen_tounyuu_yotei
                             + ln_aitesaki_zaiko;
--
    RETURN ln_temp_take_stock_plan;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_take_stock_plan;
--
--
  /***********************************************************************************
   * Function Name    : get_subtractable
   * Description      : 引当可能数取得
   ***********************************************************************************/
  FUNCTION  get_subtractable(
              iv_segment1               IN xxcmn_item_locations_v.segment1%TYPE,
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE,
              iv_item_no                IN xxcmn_item_mst_v.item_no%TYPE,
              in_item_id                IN xxcmn_item_mst_v.item_id%TYPE,
              iv_lot_no                 IN ic_lots_mst.lot_no%TYPE,
              in_lot_id                 IN ic_lots_mst.lot_id%TYPE,
              id_effective_date         IN DATE,
              in_loct_onhand            IN ic_loct_inv.loct_onhand%TYPE)
              RETURN NUMBER
  IS
--
    -- 変数宣言
    lv_errbuf                       VARCHAR2(2000);
    lv_retcode                      VARCHAR2(1);
    lv_errmsg                       VARCHAR2(2000);
    ln_temp_inv_stock_vol           NUMBER;    -- 手持在庫数
    ln_temp_supply_stock_plan       NUMBER;    -- 入庫予定数
    ln_temp_take_stock_plan         NUMBER;    -- 出庫予定数
    ln_temp_subtractable            NUMBER;    -- 引当可能数退避
  BEGIN
--
    -- 変数初期化
    ln_temp_inv_stock_vol     := 0;
    ln_temp_supply_stock_plan := 0;
    ln_temp_take_stock_plan   := 0;
--
    -- 手持在庫数取得
    ln_temp_inv_stock_vol := get_inv_stock_vol(
                               in_inventory_location_id,
                               iv_item_no,
                               in_item_id,
                               in_lot_id,
                               in_loct_onhand);
--
    -- 入庫予定数取得
    ln_temp_supply_stock_plan := get_supply_stock_plan(
                                   iv_segment1,
                                   in_inventory_location_id,
                                   iv_item_no,
                                   in_item_id,
                                   iv_lot_no,
                                   in_lot_id,
                                   id_effective_date,
                                   in_loct_onhand);
--
    -- 出庫予定数取得
    ln_temp_take_stock_plan := get_take_stock_plan(
                                 iv_segment1,
                                 in_inventory_location_id,
                                 iv_item_no,
                                 in_item_id,
                                 in_lot_id,
                                 id_effective_date,
                                 in_loct_onhand);
--
    -- 引当可能数算出(引当可能数 = 手持在庫数取得 + 入庫予定数取得 - 出庫予定数取得)
    ln_temp_subtractable := ln_temp_inv_stock_vol
                          + ln_temp_supply_stock_plan
                          - ln_temp_take_stock_plan;
--
    RETURN ln_temp_subtractable;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_subtractable;
--
END xxinv540001;
/
