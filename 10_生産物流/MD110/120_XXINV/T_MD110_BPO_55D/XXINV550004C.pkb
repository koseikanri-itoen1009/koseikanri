CREATE OR REPLACE
PACKAGE BODY xxinv550004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv550004c(body)
 * Description      : 棚卸スナップショット作成
 * MD.050           : 在庫(帳票)               T_MD050_BPO_550
 * MD.070           : 棚卸スナップショット作成 T_MD070_BPO_55D
 * Version          : 1.12
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  create_snapshot      棚卸スナップショット作成ファンクション
 *  add_del_info         削除対象配列セットプロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/10    1.0   R.Matusita       新規作成
 *  2008/05/07    1.1   S.Nakamura       内部変更要求#47,#62
 *  2008/05/20    1.2   K.Kumamoto       結合テスト障害(User-Defined Exception)対応
 *  2008/06/23    1.3   K.Kumamoto       システムテスト障害#260(受払残高リストが終了しない)対応
 *  2008/08/28    1.4   Oracle 山根 一浩 PT 2_1_12 #33,T_S_503対応
 *  2008/09/16    1.5   Y.Yamamoto       PT 2-1_12 #63
 *  2008/09/24    1.6   Y.Kawano         T_S_500対応
 *  2008/10/02    1.7   Y.Yamamoto       PT 2-1_12 #85
 *  2008/11/11    1.8   Y.Kawano         統合テスト指摘#565対応
 *  2008/12/12    1.9   Y.Yamamoto       本番#674対応
 *  2009/03/30    1.10  H.Iida           本番障害#1346対応（営業単位対応）
 *  2009/09/10    1.11  M.Nomura         本番障害#1607対応
 *  2010/05/13    1.12  M.Hokkanji       本稼動障害#2250対応
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
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
-- 手持数量情報を格納するテーブル型の定義
  TYPE  invent_monthly_stock_id   IS TABLE OF  NUMBER               INDEX BY BINARY_INTEGER;  -- 棚卸月末在庫ID
  TYPE  whse_code_type   IS TABLE OF  ic_loct_inv.whse_code%TYPE    INDEX BY BINARY_INTEGER;  -- OPM手持数量  倉庫コード
  TYPE  item_id_type     IS TABLE OF  ic_item_mst_b.item_id%TYPE    INDEX BY BINARY_INTEGER;  -- OPM品目マスタ  品目ID
  TYPE  item_no_type     IS TABLE OF  ic_item_mst_b.item_no%TYPE    INDEX BY BINARY_INTEGER;  -- OPM品目マスタ  品目コード
  TYPE  lot_id_type      IS TABLE OF  ic_lots_mst.lot_id%TYPE       INDEX BY BINARY_INTEGER;  -- OPMロットマスタ  ロットID
  TYPE  lot_no_type      IS TABLE OF  ic_lots_mst.lot_no%TYPE       INDEX BY BINARY_INTEGER;  -- OPMロットマスタ  ロットNo
  TYPE  lot_ctl_type     IS TABLE OF  ic_item_mst_b.lot_ctl%TYPE    INDEX BY BINARY_INTEGER;  -- OPM品目マスタ  ロット管理区分
  TYPE  loct_onhand_type IS TABLE OF  ic_loct_inv.loct_onhand%TYPE  INDEX BY BINARY_INTEGER;  -- OPM手持数量  手持数量
--
--add start 1.3
  TYPE  rec_del_info IS RECORD(
    whse_code  xxinv_stc_inventory_month_stck.whse_code%TYPE
   ,item_id    xxinv_stc_inventory_month_stck.item_id%TYPE
   ,invent_ym  xxinv_stc_inventory_month_stck.invent_ym%TYPE
  );
  TYPE tbl_del_info IS TABLE OF rec_del_info INDEX BY BINARY_INTEGER;
--add end 1.3
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  curr_invent_monthly_stock_id invent_monthly_stock_id; -- 棚卸月末在庫ID
  curr_whse_code_tbl      whse_code_type;             -- OPM手持数量  倉庫コード
  curr_item_id_tbl        item_id_type;               -- OPM品目マスタ  品目ID
  curr_item_no_tbl        item_no_type;               -- OPM品目マスタ  品目コード
  curr_lot_id_tbl         lot_id_type;                -- OPMロットマスタ  ロットID
  curr_lot_no_tbl         lot_no_type;                -- OPMロットマスタ  ロットNo
  curr_lot_ctl_tbl        lot_ctl_type;               -- OPM品目マスタ  ロット管理区分
  curr_loct_onhand_tbl    loct_onhand_type;           -- OPM手持数量  手持数量
--
  -- 前月用
  pre_invent_monthly_stock_id invent_monthly_stock_id; -- 棚卸月末在庫ID
  pre_whse_code_tbl      whse_code_type;             -- OPM手持数量  倉庫コード
  pre_item_id_tbl        item_id_type;               -- OPM品目マスタ  品目ID
  pre_item_no_tbl        item_no_type;               -- OPM品目マスタ  品目コード
  pre_lot_id_tbl         lot_id_type;                -- OPMロットマスタ  ロットID
  pre_lot_no_tbl         lot_no_type;                -- OPMロットマスタ  ロットNo
  pre_lot_ctl_tbl        lot_ctl_type;               -- OPM品目マスタ  ロット管理区分
  pre_loct_onhand_tbl    loct_onhand_type;           -- OPM手持数量  手持数量
--
  i                  NUMBER;                     -- ループカウンター
--add start 1.3
  n                  NUMBER;
--add end 1.3
--
--add start 1.3
  del_info           tbl_del_info;               -- 削除情報
--add end 1.3
  gn_ret_nomal       CONSTANT NUMBER :=  0;      -- 正常
  gn_ret_error       CONSTANT NUMBER :=  1;      -- 初期処理エラー,日付チェックエラー
  gn_ret_lock_error  CONSTANT NUMBER :=  2;      -- ロックエラー
  gn_ret_other_error CONSTANT NUMBER := -1;      -- その他のエラー
--
  gv_pkg_name        CONSTANT VARCHAR2(100) := 'xxinv550004c'; -- パッケージ名
--
  lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
  lv_retcode VARCHAR2(1);     -- リターン・コード
  lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- 2008/09/16 v1.5 Y.Yamamoto ADD Start
  -------------------------------------------------------------------------------------------------
  -- 「D-2. 手持数量情報」構造体
  -------------------------------------------------------------------------------------------------
  TYPE D_2_rec IS RECORD(
    whse_code   xxcmn_item_locations_v.whse_code%TYPE, -- OPM手持数量  倉庫コード (※D-6と違う)
    item_id     xxcmn_item_mst_v.item_id%TYPE,         -- OPM品目マスタ  品目ID
    item_no     xxcmn_item_mst_v.item_no%TYPE,         -- OPM品目マスタ  品目コード
    lot_id      ic_lots_mst.lot_id%TYPE,               -- OPMロットマスタ  ロットID
    lot_no      ic_lots_mst.lot_no%TYPE,               -- OPMロットマスタ  ロットNo
    lot_ctl     xxcmn_item_mst_v.lot_ctl%TYPE,         -- OPM品目マスタ  ロット管理区分
    loct_onhand NUMBER);                               -- OPM手持数量  手持数量
  --レコード型生成
  TYPE D_2_tab IS TABLE OF D_2_rec;
   lr_curr_cargo_rec D_2_tab;
--
  -------------------------------------------------------------------------------------------------
  -- 「D-6. 手持数量情報（前月分）」構造体
  -------------------------------------------------------------------------------------------------
  TYPE D_6_rec IS RECORD(
    whse_code   xxcmn_item_locations_v.whse_code%TYPE, -- OPM手持数量  倉庫コード (※D-6と違う)
    item_id     xxcmn_item_mst_v.item_id%TYPE,         -- OPM品目マスタ  品目ID
    item_no     xxcmn_item_mst_v.item_no%TYPE,         -- OPM品目マスタ  品目コード
    lot_id      ic_lots_mst.lot_id%TYPE,               -- OPMロットマスタ  ロットID
    lot_no      ic_lots_mst.lot_no%TYPE,               -- OPMロットマスタ  ロットNo
    lot_ctl     xxcmn_item_mst_v.lot_ctl%TYPE,         -- OPM品目マスタ  ロット管理区分
    loct_onhand NUMBER);                               -- OPM手持数量  手持数量
  --レコード型生成
  TYPE D_6_tab IS TABLE OF D_6_rec;
   lr_pre_cargo_rec D_6_tab;
--
  -- *** グローバル・カーソル ***
  TYPE cursor_D2rec IS REF CURSOR;--棚卸データインターフェーステーブルの対象データ取得用
  TYPE cursor_D6rec IS REF CURSOR;--棚卸データインターフェーステーブルの対象データ取得用
-- 2008/09/16 v1.5 Y.Yamamoto ADD End
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
  -- *** 削除・登録エラーハンドラ ***
  global_del_ins_expt       EXCEPTION;
--
--################################  固定部 END   ##################################
--
--add start 1.3
  PROCEDURE add_del_info(
    iv_whse_code  IN VARCHAR2
   ,in_item_id    IN VARCHAR2
   ,iv_invent_ym  IN VARCHAR2
  )
  IS
    n      NUMBER;
    lb_add BOOLEAN;
  BEGIN
    n := del_info.first;
--
    --配列に1件以上存在する場合
    IF del_info.EXISTS(n) THEN
      WHILE n IS NOT NULL LOOP
        IF (del_info(n).whse_code = iv_whse_code AND
            del_info(n).item_id   = in_item_id   AND
            del_info(n).invent_ym = iv_invent_ym) THEN
          lb_add := FALSE;
          EXIT;
        END IF;
        n := del_info.next(n);
      END LOOP;
      --配列の中に一致する情報が存在しない場合
      lb_add := TRUE;
      n := del_info.last + 1; --添え字=最終行+1
--
    --配列に1件も存在しない場合
    ELSE
      lb_add := TRUE;
      n := 1; --添え字=1
    END IF;
--
    IF (lb_add) THEN
      del_info(n).whse_code := iv_whse_code;
      del_info(n).item_id   := in_item_id;
      del_info(n).invent_ym := iv_invent_ym;
    END IF;
--
  END add_del_info;
--add end 1.3
   /**********************************************************************************
   * Function Name    : create_snapshot
   * Description      : 棚卸スナップショット作成関数
   ***********************************************************************************/
  FUNCTION create_snapshot(
    iv_invent_ym        IN  VARCHAR2,               -- 対象年月(YYYYMM)
    iv_whse_code1       IN  VARCHAR2 DEFAULT NULL,  -- 倉庫コード１
    iv_whse_code2       IN  VARCHAR2 DEFAULT NULL,  -- 倉庫コード２
    iv_whse_code3       IN  VARCHAR2 DEFAULT NULL,  -- 倉庫コード３
    iv_whse_department1 IN  VARCHAR2 DEFAULT NULL,  -- 倉庫管理部署１
    iv_whse_department2 IN  VARCHAR2 DEFAULT NULL,  -- 倉庫管理部署２
    iv_whse_department3 IN  VARCHAR2 DEFAULT NULL,  -- 倉庫管理部署３
    iv_block1           IN  VARCHAR2 DEFAULT NULL,  -- ブロック１
    iv_block2           IN  VARCHAR2 DEFAULT NULL,  -- ブロック２
    iv_block3           IN  VARCHAR2 DEFAULT NULL,  -- ブロック３
    iv_arti_div_code    IN  VARCHAR2,               -- 商品区分
    iv_item_class_code  IN  VARCHAR2)               -- 品目区分
    RETURN NUMBER
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_snapshot'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
-- 2009/03/30 H.Iida ADD START 本番障害#1346
    -- *** ローカル定数 ***
    cv_prf_org_id CONSTANT VARCHAR2(100) := 'ORG_ID';          -- プロファイル：ORG_ID
-- 2009/03/30 H.Iida ADD END
--
    -- *** ローカル変数 ***
--    
    lv_pre_invent_ym           VARCHAR2(6);-- 起動パラメータの対象年月の前月
    ld_invent_begin_ymd        DATE;       -- 月初日
    ld_invent_end_ymd          DATE;       -- 月末日
    ld_pre_invent_begin_ymd    DATE;       -- 前月の月初日
    ld_pre_invent_end_ymd      DATE;       -- 前月の月末日
--
    ln_whse_code_nullflg       NUMBER;     -- 倉庫コードNULLチェックフラグ
    ln_whse_department_nullflg NUMBER;     -- 倉庫管理部署NULLチェックフラグ
    ln_block_nullflg           NUMBER;     -- ブロックNULLチェックフラグ
--
    TYPE ary_quantity IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;-- 数量配列
--
    ln_d3_itp_trans_qty ary_quantity;      -- D-3 OPM保留在庫トランザクション 数量
    ln_d3_itc_trans_qty ary_quantity;      -- D-3 OPM完了在庫トランザクション 数量
    ln_d4_quantity ary_quantity;           -- D-4. 移動積送分情報抽出 数量
    ln_d5_quantity ary_quantity;           -- D-5. 出荷・有償積送分情報抽出 数量
    ln_d7_quantity ary_quantity;           -- D-7. 移動積送分情報抽出（前月分） 数量
    ln_d8_quantity ary_quantity;           -- D-8. 出荷・有償積送分情報抽出（前月分） 数量
-- 2008/12/12 v1.9 Y.Yamamoto add start
    ln_d12_quantity ary_quantity;          -- D-12.移動積送分情報抽出 数量
    ln_d13_quantity ary_quantity;          -- D-13.出荷・有償積送分情報抽出 数量
    ln_d14_quantity ary_quantity;          -- D-14.移動積送分情報抽出（前月分） 数量
    ln_d15_quantity ary_quantity;          -- D-15.出荷・有償積送分情報抽出（前月分） 数量
-- 2008/12/12 v1.9 Y.Yamamoto add end
--
    ln_user_id          NUMBER;            -- ログインしているユーザー
    ln_login_id         NUMBER;            -- 最終更新ログイン
    ln_conc_request_id  NUMBER;            -- 要求ID
    ln_prog_appl_id     NUMBER;            -- コンカレント・プログラム・アプリケーションID
    ln_conc_program_id  NUMBER;            -- コンカレント・プログラムID
--
    lv_item_div     VARCHAR2(100);         -- プロファイル'商品区分'
    lv_article_div  VARCHAR2(100);         -- プロファイル'品目区分'
    lv_orgid_div    NUMBER;                -- プロファイル'マスタ組織ID'
--
    lv_item_cd      VARCHAR2(40);          -- 品目マスタ形式置換え用品目コード
--
    ln_invent_monthly_stock_id NUMBER;     -- 棚卸月末在庫ID
--
    lv_sysdate_ym   VARCHAR2(6);           -- 現在日付
--
-- 2009/03/30 H.Iida ADD START 本番障害#1346
    lv_org_id       VARCHAR2(1000);        -- ORG_ID
-- 2009/03/30 H.Iida ADD END
-- 2008/09/16 v1.5 Y.Yamamoto ADD Start
    lv_D2sql            VARCHAR2(15000) DEFAULT NULL; -- 動的SQL文字列 D-2. 手持数量情報
    lv_D6sql            VARCHAR2(15000) DEFAULT NULL; -- 動的SQL文字列 D-6. 手持数量情報（前月分）
    lv_where_whsecode   VARCHAR2(100)   DEFAULT NULL; -- 動的SQL文字列 入力パラメータ：倉庫コード
    lv_where_block      VARCHAR2(100)   DEFAULT NULL; -- 動的SQL文字列 入力パラメータ：ブロック
    lv_where_department VARCHAR2(100)   DEFAULT NULL; -- 動的SQL文字列 入力パラメータ：倉庫管理部署
    lv_loc_where        VARCHAR2(300)   DEFAULT NULL; -- 動的SQL文字列 入力パラメータ
--
    lrec_D2data cursor_D2rec;  -- 棚卸データインタフェースカーソル
    lrec_D6data cursor_D6rec;  -- 棚卸データインタフェースカーソル
-- 2008/09/16 v1.5 Y.Yamamoto ADD End
--
--add start 1.3
    TYPE refcursor IS REF CURSOR;
    cur_del refcursor;
--add end 1.3
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
    -- D-2. 手持数量情報抽出カーソル
/*    CURSOR current_cargo_cur IS
    SELECT iiim.whse_code whse_code,               -- OPM手持数量  倉庫コード (※D-6と違う)
           iiim.item_id   item_id,                 -- OPM品目マスタ  品目ID
           iiim.item_no   item_no,                 -- OPM品目マスタ  品目コード
           iiim.lot_id    lot_id,                  -- OPMロットマスタ  ロットID
           iiim.lot_no    lot_no,                  -- OPMロットマスタ  ロットNo
           iiim.lot_ctl   lot_ctl,                 -- OPM品目マスタ  ロット管理区分
           SUM(NVL(ili.loct_onhand,0)) loct_onhand -- OPM手持数量  手持数量
    FROM   ic_loct_inv ili,                        -- OPM手持数量 (※D-6と違う)
           (SELECT xilv.whse_code,
                   xilv.segment1,                  -- add 2008/05/07 #47対応
                   ximv.item_id,
                   ximv.item_no, 
                   ilm.lot_id, 
                   ximv.lot_ctl,
                   ilm.lot_no
            FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                   ic_lots_mst ilm,               -- OPMロットマスタ
                   xxcmn_item_locations_v xilv,   -- OPM保管場所情報VIEW
                   xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                   xxcmn_item_categories_v xicv2  -- OPM品目カテゴリ割当情報VIEW2
                   --org_acct_periods oap         -- 在庫会計期間  -- del 2008/5/8 #47対応
            WHERE  ximv.item_id = ilm.item_id     -- OPM品目マスタ.品目ID   = OPMロットマスタ.品目ID
            AND   (
                    (((0 = ln_whse_code_nullflg) AND (1 = ln_block_nullflg))  -- フラグが0なら倉庫コード１-３を行う
                       AND (xilv.whse_code IN (iv_whse_code1, iv_whse_code2, iv_whse_code3))
                    )
                  OR
                    (((1 = ln_whse_code_nullflg) AND (0 = ln_block_nullflg))  -- フラグが0ならブロック１-３を行う
                       AND xilv.distribution_block IN (iv_block1, iv_block2, iv_block3)
                    )
                  OR
                    (((0 = ln_whse_code_nullflg) AND (0 = ln_block_nullflg))  -- 倉庫コード、ブロック両方指定した場合
                       AND
                         (((xilv.whse_code IN (iv_whse_code1, iv_whse_code2, iv_whse_code3))
                         OR
                         (xilv.distribution_block IN (iv_block1, iv_block2, iv_block3))))
                    )
                  OR 
                     ((1 = ln_whse_code_nullflg) AND (1 = ln_block_nullflg))  -- 指定しない場合
                  )
            AND
                  (
                   ((0 = ln_whse_department_nullflg) -- フラグが0なら倉庫管理部署１-３を行う
                     AND (xilv.whse_department IN (iv_whse_department1, iv_whse_department2, iv_whse_department3)))
                   OR
                    (1 = ln_whse_department_nullflg)
                  )
            AND    xicv1.category_set_name = lv_item_div    -- 商品区分
            AND    xicv1.segment1          = iv_arti_div_code
            AND    xicv1.item_id           = ximv.item_id
            AND    xicv2.item_id           = ximv.item_id
            AND    xicv2.category_set_name = lv_article_div -- 品目区分
            AND    xicv2.segment1          = iv_item_class_code
            -- AND    xilv.mtl_organization_id= oap.organization_id  -- #47対応
           ) iiim
    WHERE  iiim.item_id            = ili.item_id(+)
    AND    iiim.whse_code          = ili.whse_code(+)
    AND    iiim.lot_id             = ili.lot_id(+)
    AND    iiim.segment1           = ili.location(+)   -- add 2008/05/07 #47対応
    -- mod start 2008/05/07 #47対応
    -- GROUP BY iiim.whse_code, iiim.item_no, iiim.lot_no, iiim.item_id, iiim.lot_id, iiim.lot_ctl,ili.loct_onhand;
    GROUP BY 
       iiim.whse_code
      ,iiim.item_id
      ,iiim.item_no
      ,iiim.lot_id
      ,iiim.lot_no
      ,iiim.lot_ctl
      ;*/
    -- mod end 2008/05/07 #47対応
--
--
    -- D-6. 手持数量情報抽出（前月分）カーソル
/*    CURSOR  pre_cargo_cur (ld_cur_pre_invent_begin_ymd DATE) IS
    SELECT iiim.whse_code whse_code,               -- OPM手持数量  倉庫コード (※D-6と違う)
           iiim.item_id item_id,                   -- OPM品目マスタ  品目ID
           iiim.item_no item_no,                   -- OPM品目マスタ  品目コード
           iiim.lot_id   lot_id,                   -- OPMロットマスタ  ロットID
           iiim.lot_no   lot_no,                   -- OPMロットマスタ  ロットNo
           iiim.lot_ctl lot_ctl,                   -- OPM品目マスタ  ロット管理区分
           SUM(NVL(ipb.loct_onhand,0)) loct_onhand -- OPMロット別月次在庫  手持数量
    FROM   ic_perd_bal ipb,                        -- OPMロット別月次在庫 (※D-2と違う)
           (SELECT xilv.whse_code,
                   xilv.segment1,                  -- add 2008/05/07 #47対応
                   ximv.item_id,
                   ximv.item_no, 
                   ilm.lot_id, 
                   ximv.lot_ctl,
                   ilm.lot_no,
                   oap.period_year,
                   oap.period_num
            FROM   xxcmn_item_mst_v ximv,         -- OPM品目マスタ情報VIEW
                   ic_lots_mst ilm,               -- OPMロットマスタ
                   xxcmn_item_locations_v xilv,   -- OPM保管場所情報VIEW
                   xxcmn_item_categories_v xicv1, -- OPM品目カテゴリ割当情報VIEW1
                   xxcmn_item_categories_v xicv2, -- OPM品目カテゴリ割当情報VIEW2
                   org_acct_periods oap           -- 在庫会計期間
            WHERE  ximv.item_id = ilm.item_id     -- OPM品目マスタ.品目ID   = OPMロットマスタ.品目ID
            AND   (
                    (((0 = ln_whse_code_nullflg) AND (1 = ln_block_nullflg))  -- フラグが0なら倉庫コード１-３を行う
                       AND (xilv.whse_code IN (iv_whse_code1, iv_whse_code2, iv_whse_code3))
                    )
                  OR
                    (((1 = ln_whse_code_nullflg) AND (0 = ln_block_nullflg))  -- フラグが0ならブロック１-３を行う
                       AND xilv.distribution_block IN (iv_block1, iv_block2, iv_block3)
                    )
                  OR
                    (((0 = ln_whse_code_nullflg) AND (0 = ln_block_nullflg))  -- 倉庫コード、ブロック両方指定した場合
                       AND
                         (((xilv.whse_code IN (iv_whse_code1, iv_whse_code2, iv_whse_code3))
                         OR
                         (xilv.distribution_block IN (iv_block1, iv_block2, iv_block3))))
                    )
                  OR 
                     ((1 = ln_whse_code_nullflg) AND (1 = ln_block_nullflg))  -- 指定しない場合
                  )
            AND
                  (
                   ((0 = ln_whse_department_nullflg) -- フラグが0なら倉庫管理部署１-３を行う
                     AND (xilv.whse_department IN (iv_whse_department1, iv_whse_department2, iv_whse_department3)))
                   OR
                    (1 = ln_whse_department_nullflg)
                  )
            AND    xicv1.category_set_name = lv_item_div    -- 商品区分
            AND    xicv1.segment1          = iv_arti_div_code
            AND    xicv1.item_id           = ximv.item_id
            AND    xicv2.item_id           = ximv.item_id
            AND    xicv2.category_set_name = lv_article_div -- 品目区分
            AND    xicv2.segment1          = iv_item_class_code
            AND    oap.period_start_date   = ld_cur_pre_invent_begin_ymd -- OPMロット別月次在庫.在庫期間= 起動パラメータの対象年月の前月
            AND    xilv.mtl_organization_id= oap.organization_id
           ) iiim
    WHERE  iiim.item_id               = ipb.item_id(+)
    AND    iiim.whse_code             = ipb.whse_code(+)
    AND    iiim.lot_id                = ipb.lot_id(+)
    -- AND    iiim.period_year           = TO_NUMBER(ipb.fiscal_year(+)) -- mod 2008/05/07 #62対応
    AND    to_char(iiim.period_year)  = ipb.fiscal_year(+)               -- mod 2008/05/07 #62対応
    AND    iiim.period_num            = ipb.period(+)
    AND    iiim.segment1              = ipb.location(+)                  -- add 2008/05/07 #47対応
    --mod start 2008/05/07 #47対応
    -- GROUP BY iiim.whse_code, iiim.item_no, iiim.lot_no, iiim.item_id, iiim.lot_id, iiim.lot_ctl,ipb.loct_onhand;--#47対応
    GROUP BY 
      iiim.whse_code
     ,iiim.item_id
     ,iiim.item_no
     ,iiim.lot_id
     ,iiim.lot_no
     ,iiim.lot_ctl
     ;*/
    --mod end 2008/05/07 #47対応
--
    -- *** ローカル・レコード ***
--    lr_curr_cargo_rec   current_cargo_cur%ROWTYPE;
--    lr_pre_cargo_rec    pre_cargo_cur%ROWTYPE;
-- 2008/09/16 v1.5 Y.Yamamoto Delete End

  BEGIN
--
-- 2009/03/30 H.Iida ADD START 本番障害#1346
    --==========================
    -- ORG_ID取得
    --==========================
    lv_org_id := FND_PROFILE.VALUE(cv_prf_org_id);
-- 2009/03/30 H.Iida ADD END
--
--add start 2008/05/12 #47対応
    curr_invent_monthly_stock_id.delete;   -- 棚卸月末在庫ID
    curr_whse_code_tbl.delete;             -- OPM手持数量  倉庫コード
    curr_item_id_tbl.delete;               -- OPM品目マスタ  品目ID
    curr_item_no_tbl.delete;               -- OPM品目マスタ  品目コード
    curr_lot_id_tbl.delete;                -- OPMロットマスタ  ロットID
    curr_lot_no_tbl.delete;                -- OPMロットマスタ  ロットNo
    curr_lot_ctl_tbl.delete;               -- OPM品目マスタ  ロット管理区分
    curr_loct_onhand_tbl.delete;           -- OPM手持数量  手持数量
    pre_invent_monthly_stock_id.delete;    -- 棚卸月末在庫ID
    pre_whse_code_tbl.delete;              -- OPM手持数量  倉庫コード
    pre_item_id_tbl.delete;                -- OPM品目マスタ  品目ID
    pre_item_no_tbl.delete;                -- OPM品目マスタ  品目コード
    pre_lot_id_tbl.delete;                 -- OPMロットマスタ  ロットID
    pre_lot_no_tbl.delete;                 -- OPMロットマスタ  ロットNo
    pre_lot_ctl_tbl.delete;                -- OPM品目マスタ  ロット管理区分
    pre_loct_onhand_tbl.delete;            -- OPM手持数量  手持数量
--add end 2008/05/12 #47対応
--add start 1.3
    del_info.delete;                       -- 削除情報
--add end 1.3
--
    lv_sysdate_ym := TO_CHAR(SYSDATE,'YYYYMM');
--
    -- 共通更新情報の取得
    ln_user_id         := FND_GLOBAL.USER_ID;         -- ログインしているユーザーのID取得
    ln_login_id        := FND_GLOBAL.LOGIN_ID;        -- 最終更新ログイン
    ln_conc_request_id := FND_GLOBAL.CONC_REQUEST_ID; -- 要求ID
    ln_prog_appl_id    := FND_GLOBAL.PROG_APPL_ID;    -- コンカレント・プログラム・アプリケーションID
    ln_conc_program_id := FND_GLOBAL.CONC_PROGRAM_ID; -- コンカレント・プログラムID
--
    -- プロファイル値の取得 (商品区分)
    lv_item_div := FND_PROFILE.VALUE('XXCMN_ITEM_DIV');
--
    -- 取得できなかった場合はエラー
    IF (lv_item_div IS NULL) THEN
      RETURN gn_ret_other_error;
    END IF;
--
    -- プロファイル値の取得 (品目区分)
    lv_article_div := FND_PROFILE.VALUE('XXCMN_ARTICLE_DIV');
--
    -- 取得できなかった場合はエラー
    IF (lv_article_div IS NULL) THEN
      RETURN gn_ret_other_error;
    END IF;
--
    -- プロファイル値の取得 (マスタ組織ID)
    lv_orgid_div := FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID');
--
    -- 取得できなかった場合はエラー
    IF (lv_orgid_div IS NULL) THEN
      RETURN gn_ret_other_error;
    END IF;
--
    -- D-1.初期処理
    -- 必須入力パラメータ、日付型チェック
    IF ((iv_invent_ym IS NULL) OR (iv_arti_div_code IS NULL) OR (iv_item_class_code IS NULL)) THEN 
      -- 対象年月、商品区分、品目区分が指定されてない場合、エラーを返す
      RETURN gn_ret_error;
    ELSIF (gn_ret_error = xxcmn_common_pkg.check_param_date_yyyymm(iv_invent_ym)) THEN
      -- 対象年月がYYYYMMでない場合、エラーを返す
      RETURN gn_ret_error;
    END IF;
--
    -- 起動パラメータの対象年月の前月を取得
    lv_pre_invent_ym := TO_CHAR(ADD_MONTHS(FND_DATE.STRING_TO_DATE(iv_invent_ym,'YYYY/MM'),-1),'YYYYMM');
--
    -- パラメータ倉庫コードNULLチェック
    IF  (iv_whse_code1 IS NULL)
    AND (iv_whse_code2 IS NULL)
    AND (iv_whse_code3 IS NULL) THEN
      -- 倉庫コード１～３がすべてNULLの場合
      ln_whse_code_nullflg := 1;
    ELSE
      ln_whse_code_nullflg := 0;
    END IF;
--
    -- パラメータ倉庫管理部署NULLチェック
    IF  (iv_whse_department1 IS NULL)
    AND (iv_whse_department2 IS NULL)
    AND (iv_whse_department3 IS NULL) THEN
      -- 倉庫管理部署１～３がすべてNULLの場合
      ln_whse_department_nullflg := 1;
    ELSE
      ln_whse_department_nullflg := 0;
    END IF;
--
    -- パラメータブロックNULLチェック
    IF  (iv_block1 IS NULL)
    AND (iv_block2 IS NULL)
    AND (iv_block3 IS NULL) THEN
      -- ブロック１～３がすべてNULLの場合
      ln_block_nullflg := 1;
    ELSE
      ln_block_nullflg := 0;
    END IF;
--
    ld_invent_begin_ymd := FND_DATE.STRING_TO_DATE(iv_invent_ym || '01','YYYY/MM/DD'); -- 月初日の取得
    ld_invent_end_ymd   := ADD_MONTHS(ld_invent_begin_ymd,1) - 1;                      -- 月末日の取得
--
    ld_pre_invent_begin_ymd := FND_DATE.STRING_TO_DATE(lv_pre_invent_ym || '01','YYYY/MM/DD'); -- 前月の月初日の取得
    ld_pre_invent_end_ymd   := ADD_MONTHS(ld_pre_invent_begin_ymd,1) - 1;                      -- 前月の月末日の取得
--
    -- 当月分始まり
    -- 手持数量情報が取得できている場合
    -- D-2を実行
--
-- 2008/09/16 v1.5 Y.Yamamoto ADD Start
    -- 入力パラメータ：倉庫コード編集
    IF (iv_whse_code1 IS NOT NULL) AND
       (iv_whse_code2 IS NOT NULL) AND
       (iv_whse_code3 IS NOT NULL) THEN
      lv_where_whsecode :=
        'xilv.whse_code IN (''' || iv_whse_code1 || ''', ''' || iv_whse_code2 || ''', ''' || iv_whse_code3 || ''')';
    ELSIF (iv_whse_code1 IS NOT NULL) AND
          (iv_whse_code2 IS NOT NULL) AND
          (iv_whse_code3 IS NULL)     THEN
      lv_where_whsecode :=
        'xilv.whse_code IN (''' || iv_whse_code1 || ''', ''' || iv_whse_code2 || ''')';
    ELSIF (iv_whse_code1 IS NOT NULL) AND
          (iv_whse_code2 IS NULL)     AND
          (iv_whse_code3 IS NOT NULL) THEN
      lv_where_whsecode :=
        'xilv.whse_code IN (''' || iv_whse_code1 || ''', ''' || iv_whse_code3 || ''')';
    ELSIF (iv_whse_code1 IS NULL)     AND
          (iv_whse_code2 IS NOT NULL) AND
          (iv_whse_code3 IS NOT NULL) THEN
      lv_where_whsecode :=
        'xilv.whse_code IN (''' || iv_whse_code2 || ''', ''' || iv_whse_code3 || ''')';
    ELSIF (iv_whse_code1 IS NOT NULL) AND
          (iv_whse_code2 IS NULL)     AND
          (iv_whse_code3 IS NULL)     THEN
      lv_where_whsecode :=
        'xilv.whse_code = ''' || iv_whse_code1 || '''';
    ELSIF (iv_whse_code1 IS NULL)     AND
          (iv_whse_code2 IS NOT NULL) AND
          (iv_whse_code3 IS NULL)     THEN
      lv_where_whsecode :=
        'xilv.whse_code = ''' || iv_whse_code2 || '''';
    ELSIF (iv_whse_code1 IS NULL)     AND
          (iv_whse_code2 IS NULL)     AND
          (iv_whse_code3 IS NOT NULL) THEN
      lv_where_whsecode :=
        'xilv.whse_code = ''' || iv_whse_code3 || '''';
    ELSE
      lv_where_whsecode := NULL;
    END IF;
--
    -- 入力パラメータ：ブロック編集
    IF    (iv_block1 IS NOT NULL) AND
          (iv_block2 IS NOT NULL) AND
          (iv_block3 IS NOT NULL) THEN
      lv_where_block :=
        'xilv.distribution_block IN (''' || iv_block1 || ''', ''' || iv_block2 || ''', ''' || iv_block3 || ''')';
    ELSIF (iv_block1 IS NOT NULL) AND
          (iv_block2 IS NOT NULL) AND
          (iv_block3 IS NULL)     THEN
      lv_where_block :=
        'xilv.distribution_block IN (''' || iv_block1 || ''', ''' || iv_block2 || ''')';
    ELSIF (iv_block1 IS NOT NULL) AND
          (iv_block2 IS NULL)     AND
          (iv_block3 IS NOT NULL) THEN
      lv_where_block :=
        'xilv.distribution_block IN (''' || iv_block1 || ''', ''' || iv_block3 || ''')';
    ELSIF (iv_block1 IS NULL)     AND
          (iv_block2 IS NOT NULL) AND
          (iv_block3 IS NOT NULL) THEN
      lv_where_block :=
        'xilv.distribution_block IN (''' || iv_block2 || ''', ''' || iv_block3 || ''')';
    ELSIF (iv_block1 IS NOT NULL) AND
          (iv_block2 IS NULL)     AND
          (iv_block3 IS NULL)     THEN
      lv_where_block :=
        'xilv.distribution_block = ''' || iv_block1 || '''';
    ELSIF (iv_block1 IS NULL)     AND
          (iv_block2 IS NOT NULL) AND
          (iv_block3 IS NULL)     THEN
      lv_where_block :=
        'xilv.distribution_block = ''' || iv_block2 || '''';
    ELSIF (iv_block1 IS NULL)     AND
          (iv_block2 IS NULL)     AND
          (iv_block3 IS NOT NULL) THEN
      lv_where_block :=
        'xilv.distribution_block = ''' || iv_block3 || '''';
    ELSE
      lv_where_block := NULL;
    END IF;
--
    -- 入力パラメータ：倉庫管理部署編集
    IF    (iv_whse_department1 IS NOT NULL) AND
          (iv_whse_department2 IS NOT NULL) AND
          (iv_whse_department3 IS NOT NULL) THEN
      lv_where_department :=
        'xilv.whse_department IN (''' || iv_whse_department1 || ''', ''' || iv_whse_department2 || ''', ''' || iv_whse_department3 || ''')' ;
    ELSIF (iv_whse_department1 IS NOT NULL) AND
          (iv_whse_department2 IS NOT NULL) AND
          (iv_whse_department3 IS NULL)     THEN
      lv_where_department :=
        'xilv.whse_department IN (''' || iv_whse_department1 || ''', ''' || iv_whse_department2 || ''')';
    ELSIF (iv_whse_department1 IS NOT NULL) AND
          (iv_whse_department2 IS NULL)     AND
          (iv_whse_department3 IS NOT NULL) THEN
      lv_where_department :=
        'xilv.whse_department IN (''' || iv_whse_department1 || ''', ''' || iv_whse_department3 || ''')';
    ELSIF (iv_whse_department1 IS NULL)     AND
          (iv_whse_department2 IS NOT NULL) AND
          (iv_whse_department3 IS NOT NULL) THEN
      lv_where_department :=
        'xilv.whse_department IN (''' || iv_whse_department2 || ''', ''' || iv_whse_department3 || ''')';
    ELSIF (iv_whse_department1 IS NOT NULL) AND
          (iv_whse_department2 IS NULL)     AND
          (iv_whse_department3 IS NULL)     THEN
      lv_where_department :=
        'xilv.whse_department = ''' || iv_whse_department1 || '''';
    ELSIF (iv_whse_department1 IS NULL)     AND
          (iv_whse_department2 IS NOT NULL) AND
          (iv_whse_department3 IS NULL)     THEN
      lv_where_department :=
        'xilv.whse_department = ''' || iv_whse_department2 || '''';
    ELSIF (iv_whse_department1 IS NULL)     AND
          (iv_whse_department2 IS NULL)     AND
          (iv_whse_department3 IS NOT NULL) THEN
      lv_where_department :=
        'xilv.whse_department = ''' || iv_whse_department3 || '''';
    ELSE
      lv_where_department := NULL;
    END IF;
--
    -- パラメータ編集
    IF    (ln_whse_code_nullflg = 0) AND
          (ln_block_nullflg     = 1) THEN   -- 倉庫コードを指定した場合
      lv_loc_where := lv_where_whsecode;
    ELSIF (ln_whse_code_nullflg = 1) AND
          (ln_block_nullflg     = 0) THEN   -- ブロックを指定した場合
      lv_loc_where := lv_where_block;
    ELSIF (ln_whse_code_nullflg = 0) AND
          (ln_block_nullflg     = 0) THEN   -- 倉庫コード、ブロック両方指定した場合
      lv_loc_where := lv_where_whsecode
        || '       OR '
        || lv_where_block;
    ELSE                                    -- 指定しない場合
      lv_loc_where := NULL;
    END IF;
--
    -- 倉庫管理部署編集
    IF (ln_whse_department_nullflg = 0) THEN
      IF (lv_loc_where IS NOT NULL) THEN
        -- すでに編集済
        lv_loc_where := lv_loc_where
          || '       AND '
          || lv_where_department;
      ELSE
        -- 未編集
        lv_loc_where := lv_where_department;
      END IF;
    END IF;
-- 2008/09/16 v1.5 Y.Yamamoto ADD End
--
    BEGIN
--
-- 2008/09/16 v1.5 Y.Yamamoto Update Start
      --SQL作成開始
      lv_D2sql := 
           'SELECT xilv.whse_code              whse_code '   -- OPM手持数量  倉庫コード (※D-6と違う)
        || '      ,iimb.item_id                item_id '     -- OPM品目マスタ  品目ID
        || '      ,iimb.item_no                item_no '     -- OPM品目マスタ  品目コード
        || '      ,ilm.lot_id                  lot_id '      -- OPMロットマスタ  ロットID
        || '      ,ilm.lot_no                  lot_no '      -- OPMロットマスタ  ロットNo
        || '      ,iimb.lot_ctl                lot_ctl '     -- OPM品目マスタ  ロット管理区分
        || '      ,SUM(NVL(ili.loct_onhand,0)) loct_onhand ' -- OPM手持数量  手持数量
        || 'FROM   ic_loct_inv              ili '            -- OPM手持数量 (※D-6と違う)
        || '      ,xxcmn_item_locations_v   xilv '           -- OPM保管場所情報VIEW
        || '      ,ic_item_mst_b            iimb '           -- OPM品目マスタ
        || '      ,xxcmn_item_mst_b         ximb '           -- OPM品目アドオンマスタ
-- *----------* 2009/09/10 Ver.1.11 本番#1607対応 start *----------*
        || '      ,ic_lots_mst              ilm '            -- OPMロットマスタ
        || '      ,xxinv_lots_notzero_mst_v xlmv '           -- 手持取引ロットVIEW
-- *----------* 2009/09/10 Ver.1.11 本番#1607対応 end   *----------*
        || '      ,xxcmn_item_categories5_v xicv '           -- OPM品目カテゴリ割当情報VIEW1
        || 'WHERE xicv.prod_class_code    = :arti_div_code '
        || 'AND   xicv.item_class_code    = :item_class_code '
        || 'AND   iimb.item_id            = ximb.item_id '
        || 'AND   iimb.inactive_ind      <> ''1'' '
        || 'AND   ximb.obsolete_class    <> ''1'' '
        || 'AND   ximb.start_date_active <= TRUNC(SYSDATE) '
        || 'AND   ximb.end_date_active   >= TRUNC(SYSDATE) '
        || 'AND   iimb.item_id            = xicv.item_id '
        || 'AND   ilm.item_id             = iimb.item_id ';    -- OPMロットマスタ.品目ID   = OPM品目マスタ.品目ID
--
      -- SQL本体とパラメータを合流
      IF (lv_loc_where IS NOT NULL) THEN
        -- 倉庫コード、ブロック、倉庫管理部署が指定された
        lv_D2sql := lv_D2sql
          || 'AND '
          || lv_loc_where;
      END IF;
      -- 指定されなかったらWHERE句は作成しない
--
      lv_D2sql := lv_D2sql
        || 'AND   ili.item_id   = iimb.item_id '
        || 'AND   ili.lot_id    = ilm.lot_id '
        || 'AND   ili.whse_code = xilv.whse_code '
        || 'AND   ili.location  = xilv.segment1 '   -- add 2008/05/07 #47対応
-- *----------* 2009/09/10 Ver.1.11 本番#1607対応 start *----------*
        || 'AND   ili.item_id   = xlmv.item_id '
        || 'AND   ili.lot_id    = xlmv.lot_id '
        || 'AND   ili.whse_code = xlmv.whse_code '
        || 'AND   ili.location  = xlmv.location '
-- *----------* 2009/09/10 Ver.1.11 本番#1607対応 end   *----------*
        || 'GROUP BY '
        || '      xilv.whse_code '
        || '     ,iimb.item_id '
        || '     ,iimb.item_no '
        || '     ,ilm.lot_id '
        || '     ,ilm.lot_no '
        || '     ,iimb.lot_ctl ';
--
--      OPEN current_cargo_cur;-- カーソルオープン
        OPEN  lrec_D2data FOR lv_D2sql
        USING iv_arti_div_code
             ,iv_item_class_code;
        FETCH lrec_D2data BULK COLLECT INTO lr_curr_cargo_rec;
        CLOSE lrec_D2data;
--
--        i := 0;
--        LOOP
          -- レコード読込
--          FETCH current_cargo_cur INTO lr_curr_cargo_rec;
--          EXIT WHEN current_cargo_cur%NOTFOUND;
        <<D2_loop>>
        FOR i IN 1 .. lr_curr_cargo_rec.COUNT LOOP
--
--          i := i + 1;
-- 2008/09/16 v1.5 Y.Yamamoto Update End
          curr_whse_code_tbl(i)   := lr_curr_cargo_rec(i).whse_code;   -- OPM手持数量  倉庫コード
          curr_item_id_tbl(i)     := lr_curr_cargo_rec(i).item_id;     -- OPM品目マスタ  品目ID
          curr_item_no_tbl(i)     := lr_curr_cargo_rec(i).item_no;     -- OPM品目マスタ  品目コード
          curr_lot_id_tbl(i)      := lr_curr_cargo_rec(i).lot_id;      -- OPMロットマスタ  ロットID
          curr_lot_no_tbl(i)      := lr_curr_cargo_rec(i).lot_no;      -- OPMロットマスタ  ロットNo
          curr_lot_ctl_tbl(i)     := lr_curr_cargo_rec(i).lot_ctl;     -- OPM品目マスタ  ロット管理区分
          curr_loct_onhand_tbl(i) := lr_curr_cargo_rec(i).loct_onhand; -- OPM手持数量  手持数量
--
--add start 1.3
          add_del_info(
            lr_curr_cargo_rec(i).whse_code
           ,lr_curr_cargo_rec(i).item_id
           ,iv_invent_ym
          );
--add end 1.3
          ln_d3_itp_trans_qty(i):=0;
          ln_d3_itc_trans_qty(i):=0;
          ln_d4_quantity(i):=0;
-- 2008/12/12 v1.9 Y.Yamamoto add start
          ln_d12_quantity(i) := 0;
          ln_d13_quantity(i) := 0;
-- 2008/12/12 v1.9 Y.Yamamoto add end
--
          -- 月跨ぎの確認
          IF (iv_invent_ym < lv_sysdate_ym) THEN
--
            BEGIN
              -- 実行日が対象年月の翌月以降である場合、D-2. 手持数量情報抽出
              -- D-3.月次取引情報抽出処理
              -- OPM保留在庫トランザクション
              SELECT SUM(NVL(itp.trans_qty,0) * -1)                   -- 数量（数値を反転させる）
              INTO   ln_d3_itp_trans_qty(i)
              FROM   ic_tran_pnd itp                                  -- OPM保留在庫トランザクション
              WHERE  itp.whse_code = curr_whse_code_tbl(i)            -- 倉庫コード
              AND    itp.item_id = curr_item_id_tbl(i)                -- 品目ID
-- Ver1.12 M.Hokkanji UPD START
--              AND    (0 = curr_lot_ctl_tbl(i)                         -- ロット管理品目の場合(0:なし、1:あり)
--                      OR (itp.lot_id = curr_lot_id_tbl(i))            -- OPM品目マスタ  ロットID
--                     )
              AND    itp.lot_id  = curr_lot_id_tbl(i)
-- Ver1.12 M.Hokkanji UPD END
              --AND itp.trans_date > ld_invent_end_ymd                  -- 取引日の年月
-- Ver1.12 M.Hokkanji UPD START
--              AND TRUNC(itp.trans_date) > TRUNC(ld_invent_end_ymd)      -- 取引日の年月   -- 2008/05/07 mod
              AND itp.trans_date >= TRUNC(ADD_MONTHS(ld_invent_begin_ymd,1))      -- 取引日の年月   -- 2008/05/07 mod
-- Ver1.12 M.Hokkanji UPD END
              AND itp.completed_ind = 1                               -- 完了フラグ
              GROUP BY itp.whse_code, itp.item_id, itp.lot_id;
--
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                ln_d3_itp_trans_qty(i) := 0;
            END;
--
            BEGIN
              -- OPM完了在庫トランザクション
              SELECT SUM(NVL(itc.trans_qty,0) * -1)                       -- 数量（数値を反転させる）
              INTO   ln_d3_itc_trans_qty(i)
              FROM   ic_tran_cmp itc                                  -- OPM完了在庫トランザクション
              WHERE  itc.whse_code = curr_whse_code_tbl(i)            -- 倉庫コード
              AND    itc.item_id = curr_item_id_tbl(i)                -- 品目ID
-- Ver1.12 M.Hokkanji UPD START
--              AND    (0 = curr_lot_ctl_tbl(i)                         -- ロット管理品目の場合(0:なし、1:あり)
--                       OR (itc.lot_id = curr_lot_id_tbl(i))           -- OPM品目マスタ  ロットID
--                     )
              AND    itc.lot_id = curr_lot_id_tbl(i)                  -- OPM品目マスタ  ロットID
-- Ver1.12 M.Hokkanji UPD END
              --AND itc.trans_date > ld_invent_end_ymd                  -- 取引日の年月
-- Ver1.12 M.Hokkanji UPD START
--              AND TRUNC(itc.trans_date) > TRUNC(ld_invent_end_ymd)      -- 取引日の年月    -- 2008/05/07 mod
              AND itc.trans_date >= TRUNC(ADD_MONTHS(ld_invent_begin_ymd,1))      -- 取引日の年月    -- 2008/05/07 mod
-- Ver1.12 M.Hokkanji UPD END
              GROUP BY itc.whse_code, itc.item_id, itc.lot_id;
--
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                ln_d3_itc_trans_qty(i) := 0;
            END;
--
          --ELSE   -- 2008/05/07 mod
          END IF;  -- 2008/05/07 mod 
--
            BEGIN
              -- D-4. 移動積送分情報抽出
              IF (1 = curr_lot_ctl_tbl(i)) THEN
--
                -- ロット管理品目の場合
                SELECT SUM(NVL(xmld.actual_quantity,0))                           --③移動ロット詳細(アドオン)の実績数量
                INTO   ln_d4_quantity(i)
                FROM   xxinv_mov_req_instr_headers xmrih,                         --①移動依頼/指示ヘッダ(アドオン)
                       xxinv_mov_req_instr_lines xmril,                           --②移動依頼/指示明細(アドオン)
                       xxinv_mov_lot_details xmld,                                --③移動ロット詳細(アドオン)
                       xxcmn_item_locations_v xilv                                --④⑤OPM保管場所情報VIEW
                WHERE  xmrih.mov_hdr_id          = xmril.mov_hdr_id               --①の移動ヘッダid =②の移動ヘッダid
                AND    xmril.mov_line_id         = xmld.mov_line_id               --②の移動明細id=③の明細id
                AND    xmrih.shipped_locat_id    = xilv.inventory_location_id     --①の出庫元id=⑤の保管倉庫id
                AND    xilv.whse_code             = curr_whse_code_tbl(i)         --④の倉庫コード= d-2で取得した倉庫コード
                AND    xmril.item_id             = curr_item_id_tbl(i)            --②の品目id= d-2で取得した品目id
-- 2008/11/11 Y.Kawano MOD Start
--                AND    xmrih.status              IN ('04','05')                   --①のステータス=  "出庫報告有"または"入出庫報告有"
                AND    xmrih.status              IN ('04','06')                   --①のステータス=  "出庫報告有"または"入出庫報告有"
-- 2008/11/11 Y.Kawano MOD End
                AND    xmril.delete_flg          = 'N'                            --②の取消フラグ= "off"
                AND    xmld.document_type_code   = '20'                           --③の文書タイプ= "移動"
                AND    xmld.record_type_code     = '20'                           --③のレコードタイプ= "出庫実績"
                -- 2008/05/07 mod 日付TRUNC対応 start
                --AND    xmrih.actual_ship_date    BETWEEN ld_invent_begin_ymd
                --                                 AND     ld_invent_end_ymd        --①の出庫実績日の年月=起動パラメータの対象年月
                --AND   (xmrih.actual_arrival_date > ld_invent_end_ymd              --①の入庫実績日の年月＞起動パラメータの対象年月
                --           OR xmrih.actual_arrival_date IS NULL                   --①の入庫実績日= 指定なし  
                --      )
                AND    TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_invent_begin_ymd)
                                                     AND TRUNC(ld_invent_end_ymd)     --①の出庫実績日の年月=起動パラメータの対象年月
                AND   (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_invent_end_ymd)    --①の入庫実績日の年月＞起動パラメータの対象年月
                           OR xmrih.actual_arrival_date IS NULL                   --①の入庫実績日= 指定なし  
                      )
                -- 2008/05/07 mod 日付TRUNC対応 end
                AND    xmld.lot_id               = curr_lot_id_tbl(i)             --③のロットid = d-2で取得したロットid
                GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
              ELSE
--
                -- ロット管理品目以外の場合
                SELECT SUM(NVL(xmril.shipped_quantity,0))                         --②移動依頼/指示明細(アドオン)の出庫実績数量
                INTO   ln_d4_quantity(i)
                FROM   xxinv_mov_req_instr_headers xmrih,                         --①移動依頼/指示ヘッダ(アドオン)
                       xxinv_mov_req_instr_lines xmril,                           --②移動依頼/指示明細(アドオン)
                       xxcmn_item_locations_v xilv                                --④⑤OPM保管場所情報VIEW
                WHERE  xmrih.mov_hdr_id          = xmril.mov_hdr_id               --①の移動ヘッダid =②の移動ヘッダid
                AND    xmrih.shipped_locat_id    = xilv.inventory_location_id     --①の出庫元id=⑤の保管倉庫id
                AND    xilv.whse_code             = curr_whse_code_tbl(i)         --④の倉庫コード= d-2で取得した倉庫コード
                AND    xmril.item_id             = curr_item_id_tbl(i)            --②の品目id= d-2で取得した品目id
-- 2008/11/11 Y.Kawano MOD Start
--                AND    xmrih.status              IN ('04','05')                   --①のステータス=  "出庫報告有"または"入出庫報告有"
                AND    xmrih.status              IN ('04','06')                   --①のステータス=  "出庫報告有"または"入出庫報告有"
-- 2008/11/11 Y.Kawano MOD End
                AND    xmril.delete_flg          = 'N'                            --②の取消フラグ= "off"
                -- 2008/05/07 mod 日付TRUNC対応 start
                --AND    xmrih.actual_ship_date    BETWEEN ld_invent_begin_ymd
                --                                 AND     ld_invent_end_ymd        --①の出庫実績日の年月=起動パラメータの対象年月
                --AND   (xmrih.actual_arrival_date > ld_invent_end_ymd              --①の入庫実績日の年月＞起動パラメータの対象年月
                --       OR xmrih.actual_arrival_date IS NULL                       --①の入庫実績日= 指定なし
                --      )
                AND    TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_invent_begin_ymd)
                                                 AND TRUNC(ld_invent_end_ymd)      --①の出庫実績日の年月=起動パラメータの対象年月
                AND   (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_invent_end_ymd)              --①の入庫実績日の年月＞起動パラメータの対象年月
                       OR xmrih.actual_arrival_date IS NULL                        --①の入庫実績日= 指定なし
                      )
                -- 2008/05/07 mod 日付TRUNC対応 end
                GROUP BY xilv.whse_code, xmril.item_code;
--
              END IF;
--
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                ln_d4_quantity(i):=0;
            END;
--
--          END IF;  -- 2008/05/07 mod
--
          BEGIN
--              
            -- D-5. 出荷・有償積送分情報抽出
            lv_item_cd := TO_CHAR(curr_item_no_tbl(i));
--
            IF (1 = curr_lot_ctl_tbl(i)) THEN
--
              -- ロット管理品目の場合
              SELECT SUM(NVL(xmld.actual_quantity,0))                             -- ③移動ロット詳細(アドオン)の実績数量
              INTO  ln_d5_quantity(i)
              FROM  xxwsh_order_headers_all xoha,                                 -- ①受注ヘッダアドオン
                    xxwsh_order_lines_all xola,                                   -- ②受注明細アドオン
                    xxinv_mov_lot_details xmld,                                   -- ③移動ロット詳細(アドオン)
                    xxcmn_item_locations_v xilv,                                  -- ④⑤OPM保管場所情報VIEW
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--                    mtl_system_items_b msib                                       -- ⑥品目マスタ
                    ic_item_mst_b iimb                                            -- ⑥品目マスタ
-- 2008/10/02 v1.7 Y.Yamamoto Update End
              WHERE xoha.order_header_id         = xola.order_header_id           -- ①の受注ヘッダアドオンID= ②の受注ヘッダアドオンID
              AND   xola.order_line_id           = xmld.mov_line_id               -- ②の受注明細アドオンID    = ③の明細ID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- ①の出荷元ID= ⑤の保管倉庫ID
              AND   xilv.whse_code                = curr_whse_code_tbl(i)         -- ④の倉庫コード= D-2で取得した倉庫コード
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--              AND   xola.shipping_inventory_item_id = msib.inventory_item_id      -- ②の出荷品目ID= ⑥の品目ID
--              AND   msib.segment1                = lv_item_cd                     -- ⑥の品目コード= D-2で取得した品目コード
              AND   iimb.item_no                 = lv_item_cd                     -- ⑥の品目コード= D-2で取得した品目コード
              AND   xola.shipping_item_code      = iimb.item_no                   -- ②の出荷品目ID= ⑥の品目ID
              AND   iimb.item_id                 = xmld.item_id                   -- ⑥の品目ID    = D-2で取得した品目ID
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
              AND   xoha.req_status              IN ('04','08')                   -- ①のステータス= "出荷実績計上済"
              AND   xoha.latest_external_flag    = 'Y'                            -- ①の最新フラグ= "ON"
              AND   xola.delete_flag             = 'N'                            -- ②の削除フラグ= "OFF"
              AND   xmld.document_type_code      IN ('10','30')                   -- ③の文書タイプ= "出荷依頼" または "支給指示"
              AND   xmld.record_type_code        = '20'                           -- ③のレコードタイプ = "出庫実績"
              -- 2008/05/07 mod 日付TRUNC対応 start
              --AND   xoha.shipped_date            BETWEEN ld_invent_begin_ymd
              --                                   AND     ld_invent_end_ymd        -- ①の出庫実績日の年月=起動パラメータの対象年月
              --AND  (xoha.arrival_date            > ld_invent_end_ymd              -- ①の入庫実績日の年月＞起動パラメータの対象年月
              --      OR xoha.arrival_date IS NULL                                  -- ①の着荷日=指定なし
              --     )
-- 2008/08/28 Mod
--              AND   TRUNC(xoha.shipped_date) BETWEEN TRUNC(ld_invent_begin_ymd)
              AND   xoha.shipped_date BETWEEN TRUNC(ld_invent_begin_ymd)
                                             AND     TRUNC(ld_invent_end_ymd)     -- ①の出庫実績日の年月=起動パラメータの対象年月
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_invent_end_ymd)           -- ①の入庫実績日の年月＞起動パラメータの対象年月
                    OR xoha.arrival_date IS NULL                                  -- ①の着荷日=指定なし
                   )
              -- 2008/05/07 mod 日付TRUNC対応 end
              AND   xmld.lot_id = curr_lot_id_tbl(i)                              -- ③のロットid = d-2で取得したロットid
-- 2008/10/02 v1.7 Y.Yamamoto Delete Start
--              AND   msib.organization_id         = lv_orgid_div                   -- ⑥組織ID = プロファイル：マスタ組織ID
-- 2008/10/02 v1.7 Y.Yamamoto Delete End
              GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
            ELSE
--
              -- ロット管理品目以外の場合
              SELECT SUM(NVL(xola.shipped_quantity,0))                            -- ②受注明細アドオン(アドオン)の出庫実績数量
              INTO  ln_d5_quantity(i)
              FROM  xxwsh_order_headers_all xoha,                                 -- ①受注ヘッダアドオン
                    xxwsh_order_lines_all xola,                                   -- ②受注明細アドオン
                    xxcmn_item_locations_v xilv,                                  -- ④⑤OPM保管場所情報VIEW      
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--                    mtl_system_items_b msib,                                      -- ⑥品目マスタ
                    ic_item_mst_b iimb,                                           -- ⑥品目マスタ
-- 2008/10/02 v1.7 Y.Yamamoto Update End
	                  xxcmn_item_mst_v ximv                                         -- OPM品目情報VIEW
              WHERE xoha.order_header_id         = xola.order_header_id           -- ①の受注ヘッダアドオンID= ②の受注ヘッダアドオンID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- ①の出荷元ID= ⑤の保管倉庫ID
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--              AND   msib.segment1                = ximv.item_no
              AND   iimb.item_no                 = ximv.item_no
-- 2008/10/02 v1.7 Y.Yamamoto Update End
              AND   xilv.whse_code               = curr_whse_code_tbl(i)          -- ④の倉庫コード= D-2で取得した倉庫コード
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--              AND   xola.shipping_inventory_item_id = msib.inventory_item_id      -- ②の出荷品目ID= ⑥の品目ID
--              AND   msib.segment1                = lv_item_cd                     -- ⑥の品目コード= D-2で取得した品目コード
              AND   iimb.item_no                 = lv_item_cd                     -- ⑥の品目コード= D-2で取得した品目コード
              AND   xola.shipping_item_code      = iimb.item_no                   -- ②の出荷品目ID= ⑥の品目ID
-- 2008/10/02 v1.7 Y.Yamamoto Update End
              AND   xoha.req_status              IN ('04','08')                   -- ①のステータス= "出荷実績計上済"
              AND   xoha.latest_external_flag    = 'Y'                            -- ①の最新フラグ= "ON"
              AND   xola.delete_flag             = 'N'                            -- ②の削除フラグ= "OFF"
              -- 2008/05/07 mod 日付TRUNC対応 start
              --AND   xoha.shipped_date            BETWEEN ld_invent_begin_ymd
              --                                   AND     ld_invent_end_ymd        -- ①の出庫実績日の年月=起動パラメータの対象年月
              --AND  (xoha.arrival_date            > ld_invent_end_ymd              -- ①の入庫実績日の年月＞起動パラメータの対象年月
              --      OR xoha.arrival_date IS NULL                                  -- ①の着荷日=指定なし
              --     )
-- 2008/08/28 Mod
--              AND   TRUNC(xoha.shipped_date) BETWEEN TRUNC(ld_invent_begin_ymd)
              AND   xoha.shipped_date BETWEEN TRUNC(ld_invent_begin_ymd)
                                                 AND TRUNC(ld_invent_end_ymd)        -- ①の出庫実績日の年月=起動パラメータの対象年月
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_invent_end_ymd)           -- ①の入庫実績日の年月＞起動パラメータの対象年月
                    OR xoha.arrival_date IS NULL                                  -- ①の着荷日=指定なし
                   )
              -- 2008/05/07 mod 日付TRUNC対応 end
-- 2008/10/02 v1.7 Y.Yamamoto Delete Start
--              AND   msib.organization_id         = lv_orgid_div                   -- ⑥組織ID = プロファイル：マスタ組織ID
-- 2008/10/02 v1.7 Y.Yamamoto Delete End
              GROUP BY xilv.whse_code, ximv.item_id;
--
            END IF;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_d5_quantity(i):=0;
          END;
--
-- 2008/12/12 v1.9 Y.Yamamoto add start
          BEGIN
            -- D-12. 移動積送分情報抽出 数量
            lv_item_cd := TO_CHAR(curr_item_no_tbl(i));
--
            IF (1 = curr_lot_ctl_tbl(i)) THEN
              -- ロット管理品目の場合
              SELECT SUM(NVL(xmld.actual_quantity,0))                             -- ③移動ロット詳細(アドオン)の実績数量
              INTO   ln_d12_quantity(i)
              FROM   xxinv_mov_req_instr_headers xmrih
                    ,xxinv_mov_req_instr_lines xmril
                    ,xxinv_mov_lot_details xmld                                   --③移動ロット詳細(アドオン)
                    ,xxcmn_item_locations_v xilv                                   --④⑤OPM保管場所情報VIEW 
              WHERE xmrih.mov_hdr_id        = xmril.mov_hdr_id
              AND   xmril.mov_line_id       = xmld.mov_line_id               --②の移動明細id=③の明細id
              AND   xmrih.shipped_locat_id  = xilv.inventory_location_id     --①の出庫元id=⑤の保管倉庫id
              AND   xilv.whse_code          = curr_whse_code_tbl(i)         --④の倉庫コード= d-2で取得した倉庫コード
              AND   xmril.item_id           = curr_item_id_tbl(i)            --②の品目id= d-2で取得した品目id
              AND   xmrih.status           IN ('04','06')                    --①のステータス=  "出庫報告有"または"入出庫報告有"
              AND   xmrih.comp_actual_flg   = 'N'
              AND   xmril.delete_flg        = 'N'
              AND   xmld.document_type_code = '20'                           --③の文書タイプ= "移動"
              AND   xmld.record_type_code   = '20'                           --③のレコードタイプ= "出庫実績"
              AND   TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_invent_begin_ymd)
                                                  AND TRUNC(ld_invent_end_ymd)     --①の出庫実績日の年月=起動パラメータの対象年月
              AND  (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_invent_end_ymd)    --①の入庫実績日の年月＞起動パラメータの対象年月
                       OR xmrih.actual_arrival_date IS NULL                   --①の入庫実績日= 指定なし  
                   )
              AND  xmld.lot_id = curr_lot_id_tbl(i)                               --③のロットid = d-6で取得したロットid
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_xfer_mst ixm
                                     ,ic_tran_pnd itp
                               WHERE  itp.doc_type      = 'XFER'
                               AND    itp.completed_ind = 1
                               AND    itp.reason_code   = 'X122'
                               AND    itp.doc_id        = ixm.transfer_id
                               AND    ixm.attribute1    = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM            = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'TRNI'
                               AND    itc.reason_code = 'X122'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'ADJI'
                               AND    itc.reason_code = 'X123'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
            ELSE
--
              -- ロット管理品目以外の場合
              SELECT SUM(NVL(xmril.shipped_quantity,0))                           --②移動依頼/指示明細(アドオン)の出庫実績数量
              INTO   ln_d12_quantity(i)
              FROM   xxinv_mov_req_instr_headers xmrih
                    ,xxinv_mov_req_instr_lines xmril
                    ,xxcmn_item_locations_v xilv                                   --④⑤OPM保管場所情報VIEW 
              WHERE xmrih.mov_hdr_id        = xmril.mov_hdr_id
              AND   xmrih.shipped_locat_id  = xilv.inventory_location_id     --①の出庫元id=⑤の保管倉庫id
              AND   xilv.whse_code          = curr_whse_code_tbl(i)         --④の倉庫コード= d-2で取得した倉庫コード
              AND   xmril.item_id           = curr_item_id_tbl(i)            --②の品目id= d-2で取得した品目id
              AND   xmrih.status           IN ('04','06')                   --①のステータス=  "出庫報告有"または"入出庫報告有"
              AND   xmrih.comp_actual_flg   = 'N'
              AND   xmril.delete_flg        = 'N'
              AND   TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_invent_begin_ymd)
                                                  AND TRUNC(ld_invent_end_ymd)     --①の出庫実績日の年月=起動パラメータの対象年月
              AND  (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_invent_end_ymd)    --①の入庫実績日の年月＞起動パラメータの対象年月
                       OR xmrih.actual_arrival_date IS NULL                   --①の入庫実績日= 指定なし  
                   )
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_xfer_mst ixm
                                     ,ic_tran_pnd itp
                               WHERE  itp.doc_type      = 'XFER'
                               AND    itp.completed_ind = 1
                               AND    itp.reason_code   = 'X122'
                               AND    itp.doc_id        = ixm.transfer_id
                               AND    ixm.attribute1    = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM            = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'TRNI'
                               AND    itc.reason_code = 'X122'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'ADJI'
                               AND    itc.reason_code = 'X123'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              GROUP BY xilv.whse_code, xmril.item_code;
--
            END IF;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_d12_quantity(i):=0;
          END;
--
          BEGIN
            -- D-13.出荷・有償積送分情報抽出
            lv_item_cd := TO_CHAR(curr_item_no_tbl(i));
--
            IF (1 = curr_lot_ctl_tbl(i)) THEN
--
              -- ロット管理品目の場合
              SELECT SUM(NVL(xmld.actual_quantity,0))                             -- ③移動ロット詳細(アドオン)の実績数量
              INTO  ln_d13_quantity(i)
              FROM  xxwsh_order_headers_all xoha
                   ,xxwsh_order_lines_all xola
                   ,xxinv_mov_lot_details xmld                                   -- ③移動ロット詳細(アドオン)
                   ,xxcmn_item_locations_v xilv                                  -- ④⑤OPM保管場所情報VIEW   
                   ,ic_item_mst_b iimb                                            -- ⑥品目マスタ
              WHERE xoha.order_header_id         = xola.order_header_id           -- ①の受注ヘッダアドオンID= ②の受注ヘッダアドオンID
              AND   xola.order_line_id           = xmld.mov_line_id               -- ②の受注明細アドオンID    = ③の明細ID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- ①の出荷元ID= ⑤の保管倉庫ID
              AND   xilv.whse_code               = curr_whse_code_tbl(i)         -- ④の倉庫コード= D-2で取得した倉庫コード
              AND   iimb.item_no                 = lv_item_cd                     -- ⑥の品目コード= D-2で取得した品目コード
              AND   xola.shipping_item_code      = iimb.item_no                   -- ②の出荷品目ID= ⑥の品目ID
              AND   iimb.item_id                 = xmld.item_id                   -- ⑥の品目ID    = D-2で取得した品目ID
              AND   xoha.req_status             IN ('04','08')
              AND   xoha.actual_confirm_class    = 'N'
              AND   xoha.latest_external_flag    = 'Y'                            -- ①の最新フラグ= "ON"
              AND   xola.delete_flag             = 'N'                            -- ②の削除フラグ= "OFF"
              AND   xmld.document_type_code     IN ('10','30')                   -- ③の文書タイプ= "出荷依頼" または "支給指示"
              AND   xmld.record_type_code        = '20'                           -- ③のレコードタイプ = "出庫実績"
              AND   xoha.shipped_date BETWEEN TRUNC(ld_invent_begin_ymd)
                                      AND     TRUNC(ld_invent_end_ymd)     -- ①の出庫実績日の年月=起動パラメータの対象年月
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_invent_end_ymd)           -- ①の入庫実績日の年月＞起動パラメータの対象年月
                    OR xoha.arrival_date IS NULL                                  -- ①の着荷日=指定なし
                   )
              AND   xmld.lot_id = curr_lot_id_tbl(i)                              -- ③のロットid = d-2で取得したロットid
              AND NOT EXISTS (SELECT 'X'
                              FROM   oe_order_headers_all ooha
                              WHERE  ooha.attribute1 = xoha.request_no
-- 2009/03/30 H.Iida ADD START 本番障害#1346
                              AND    ooha.org_id     = TO_NUMBER(lv_org_id))
-- 2009/03/30 H.Iida ADD END
              GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
            ELSE
--
              -- ロット管理品目以外の場合
              SELECT SUM(NVL(xola.shipped_quantity,0))                            -- ②受注明細アドオンの出庫実績数量
              INTO  ln_d13_quantity(i)
              FROM  xxwsh_order_headers_all xoha
                   ,xxwsh_order_lines_all xola
                   ,xxcmn_item_locations_v xilv                                  -- ④⑤OPM保管場所情報VIEW   
                   ,ic_item_mst_b iimb                                            -- ⑥品目マスタ
                   ,xxcmn_item_mst_v ximv                                       -- OPM品目情報VIEW
              WHERE xoha.order_header_id         = xola.order_header_id           -- ①の受注ヘッダアドオンID= ②の受注ヘッダアドオンID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- ①の出荷元ID= ⑤の保管倉庫ID
              AND   xilv.whse_code               = curr_whse_code_tbl(i)         -- ④の倉庫コード= D-2で取得した倉庫コード
              AND   iimb.item_no                 = lv_item_cd                     -- ⑥の品目コード= D-2で取得した品目コード
              AND   iimb.item_no                 = ximv.item_no
              AND   xola.shipping_item_code      = iimb.item_no                   -- ②の出荷品目ID= ⑥の品目ID
              AND   xoha.req_status             IN ('04','08')
              AND   xoha.actual_confirm_class    = 'N'
              AND   xoha.latest_external_flag    = 'Y'                            -- ①の最新フラグ= "ON"
              AND   xola.delete_flag             = 'N'                            -- ②の削除フラグ= "OFF"
              AND   xoha.shipped_date BETWEEN TRUNC(ld_invent_begin_ymd)
                                      AND     TRUNC(ld_invent_end_ymd)     -- ①の出庫実績日の年月=起動パラメータの対象年月
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_invent_end_ymd)           -- ①の入庫実績日の年月＞起動パラメータの対象年月
                    OR xoha.arrival_date IS NULL                                  -- ①の着荷日=指定なし
                   )
              AND NOT EXISTS (SELECT 'X'
                              FROM   oe_order_headers_all ooha
                              WHERE  ooha.attribute1 = xoha.request_no
-- 2009/03/30 H.Iida ADD START 本番障害#1346
                              AND    ooha.org_id     = TO_NUMBER(lv_org_id))
-- 2009/03/30 H.Iida ADD END
              GROUP BY xilv.whse_code, ximv.item_id;
--
            END IF;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_d13_quantity(i):=0;
          END;
--
-- 2008/12/12 v1.9 Y.Yamamoto add end
-- 2008/09/16 v1.5 Y.Yamamoto Update Start
--        END LOOP current_cargo_cur;
        END LOOP D2_loop;
--
--        CLOSE current_cargo_cur; -- カーソルのクローズ
-- 2008/09/16 v1.5 Y.Yamamoto Update End
--
      EXCEPTION
        -- *** 複数行返戻ハンドラ ***
        WHEN TOO_MANY_ROWS THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE current_cargo_cur; -- カーソルのクローズ
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--           RAISE global_process_expt;
             RAISE;
--mod end 1.2
        -- *** 値エラーハンドラ ***
        WHEN VALUE_ERROR THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE current_cargo_cur; -- カーソルのクローズ
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--           RAISE global_process_expt;
             RAISE;
--mod end 1.2
        -- *** ゼロ除算エラーハンドラ ***
        WHEN ZERO_DIVIDE THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE current_cargo_cur; -- カーソルのクローズ
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--           RAISE global_process_expt;
             RAISE;
--mod end 1.2
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE current_cargo_cur; -- カーソルのクローズ
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--           RAISE global_process_expt;
             RAISE;
--mod end 1.2
    END;
    -- 当月分終わり
--
    -- 前月始まり
    -- 手持数量情報（前月分）が取得できている場合
    -- D-6を実行
--
    BEGIN
--
-- 2008/09/16 v1.5 Y.Yamamoto Update Start
      <<D6_loop>>
      lv_D6sql := 
           'SELECT xilv.whse_code              whse_code '   -- OPM手持数量  倉庫コード
        || '      ,iimb.item_id                item_id '     -- OPM品目マスタ  品目ID
        || '      ,iimb.item_no                item_no '     -- OPM品目マスタ  品目コード
        || '      ,ilm.lot_id                  lot_id '      -- OPMロットマスタ  ロットID
        || '      ,ilm.lot_no                  lot_no '      -- OPMロットマスタ  ロットNo
        || '      ,iimb.lot_ctl                lot_ctl '     -- OPM品目マスタ  ロット管理区分
        || '      ,SUM(NVL(ipb.loct_onhand,0)) loct_onhand ' -- OPM手持数量  手持数量
        || 'FROM   ic_perd_bal ipb '                         -- OPMロット別月次在庫 (※D-2と違う)
        || '      ,xxcmn_item_locations_v   xilv '           -- OPM保管場所情報VIEW
--2008/09/24 Y.Kawano Mod Start
--        || '      ,org_acct_periods         oap '            -- 在庫会計期間
        || '      ,ic_cldr_dtl                 icd '         -- OPM在庫カレンダ詳細
        || '      ,ic_whse_sts                 iws '         -- OPM倉庫別カレンダ
--2008/09/24 Y.Kawano Mod End
        || '      ,ic_item_mst_b            iimb '           -- OPM品目マスタ
        || '      ,xxcmn_item_mst_b         ximb '           -- OPM品目アドオンマスタ
-- *----------* 2009/09/10 Ver.1.11 本番#1607対応 start *----------*
        || '      ,ic_lots_mst              ilm '            -- OPMロットマスタ
        || '      ,xxinv_lots_notzero_mst_v xlmv '           -- 手持取引ロットVIEW
-- *----------* 2009/09/10 Ver.1.11 本番#1607対応 end   *----------*
        || '      ,xxcmn_item_categories5_v xicv '           -- OPM品目カテゴリ割当情報VIEW1
        || 'WHERE  xicv.prod_class_code     = :arti_div_code '
        || 'AND    xicv.item_class_code     = :item_class_code '
        || 'AND    iimb.item_id             = xicv.item_id '
        || 'AND    iimb.item_id             = ximb.item_id '
        || 'AND    iimb.inactive_ind       <> ''1'' '
        || 'AND    ximb.obsolete_class     <> ''1'' '
        || 'AND    ximb.start_date_active  <= TRUNC(SYSDATE) '
        || 'AND    ximb.end_date_active    >= TRUNC(SYSDATE) '
        || 'AND    ilm.item_id              = iimb.item_id '    -- OPMロットマスタ.品目ID   = OPM品目マスタ.品目ID
--2008/09/24 Y.Kawano Mod Start
--        || 'AND    oap.period_start_date    = to_date(''' || ld_pre_invent_begin_ymd || ''',''YYYY/MM/DD HH24:MI:SS'')'
--        || 'AND    xilv.mtl_organization_id = oap.organization_id ';
        || 'AND    SUBSTRB( TO_CHAR(icd.period_end_date,''YYYYMM''),1,6) = ''' || lv_pre_invent_ym || ''''
        || 'AND    icd.period_id            = iws.period_id '
        || 'AND    xilv.whse_code           = iws.whse_code ';
--2008/09/24 Y.Kawano Mod End
--
      -- SQL本体とパラメータを合流
      IF (lv_loc_where IS NOT NULL) THEN
        -- 倉庫コード、ブロック、倉庫管理部署が指定された
        lv_D6sql := lv_D6sql
          || ' AND '
          || lv_loc_where;
      END IF;
      -- 指定されなかったらWHERE句は作成しない
--
      lv_D6sql := lv_D6sql
        || 'AND    ipb.item_id     = iimb.item_id '
        || 'AND    ipb.whse_code   = xilv.whse_code '
        || 'AND    ipb.lot_id      = ilm.lot_id '
        || 'AND    ipb.location    = xilv.segment1 '            -- add 2008/05/07 #47対応
-- *----------* 2009/09/10 Ver.1.11 本番#1607対応 start *----------*
        || 'AND    ipb.item_id     = xlmv.item_id '
        || 'AND    ipb.lot_id      = xlmv.lot_id '
        || 'AND    ipb.whse_code   = xlmv.whse_code '
        || 'AND    ipb.location    = xlmv.location '
-- *----------* 2009/09/10 Ver.1.11 本番#1607対応 end   *----------*
--2008/09/24 Y.Kawano Mod Start
--        || 'AND    ipb.fiscal_year = to_char(oap.period_year) ' -- mod 2008/05/07 #62対応
--        || 'AND    ipb.period      = oap.period_num '
        || 'AND    ipb.fiscal_year = icd.fiscal_year '
        || 'AND    ipb.period      = icd.period '
--2008/09/24 Y.Kawano Mod End
        || 'GROUP BY '
        || '      xilv.whse_code '
        || '     ,iimb.item_id '
        || '     ,iimb.item_no '
        || '     ,ilm.lot_id '
        || '     ,ilm.lot_no '
        || '     ,iimb.lot_ctl ';
--
--      OPEN pre_cargo_cur(ld_pre_invent_begin_ymd);-- カーソルオープン
        OPEN  lrec_D6data FOR lv_D6sql
        USING iv_arti_div_code
             ,iv_item_class_code;
        FETCH lrec_D6data BULK COLLECT INTO lr_pre_cargo_rec;
        CLOSE lrec_D6data;
--
--        i := 0;
--        LOOP
         -- レコード読込
--          FETCH pre_cargo_cur INTO lr_pre_cargo_rec;
--          EXIT WHEN pre_cargo_cur%NOTFOUND;
        <<D2_loop>>
        FOR i IN 1 .. lr_pre_cargo_rec.COUNT LOOP
--
--          i := i + 1;
-- 2008/09/16 v1.5 Y.Yamamoto Update End
          pre_whse_code_tbl(i)   := lr_pre_cargo_rec(i).whse_code;    -- OPM手持数量  倉庫コード
          pre_item_id_tbl(i)     := lr_pre_cargo_rec(i).item_id;      -- OPM品目マスタ  品目ID
          pre_item_no_tbl(i)     := lr_pre_cargo_rec(i).item_no;      -- OPM品目マスタ  品目コード
          pre_lot_id_tbl(i)      := lr_pre_cargo_rec(i).lot_id;       -- OPMロットマスタ  ロットID
          pre_lot_no_tbl(i)      := lr_pre_cargo_rec(i).lot_no;       -- OPMロットマスタ  ロットNo
          pre_lot_ctl_tbl(i)     := lr_pre_cargo_rec(i).lot_ctl;      -- OPM品目マスタ  ロット管理区分
          pre_loct_onhand_tbl(i)  := lr_pre_cargo_rec(i).loct_onhand; -- OPM手持数量  手持数量
--
--add start 1.3
          add_del_info(
            lr_pre_cargo_rec(i).whse_code
           ,lr_pre_cargo_rec(i).item_id
           ,lv_pre_invent_ym
          );
--add end 1.3
          ln_d7_quantity(i):=0;
          ln_d8_quantity(i):=0;
-- 2008/12/12 v1.9 Y.Yamamoto add start
          ln_d14_quantity(i) := 0;
          ln_d15_quantity(i) := 0;
-- 2008/12/12 v1.9 Y.Yamamoto add end
--
          BEGIN
            -- D-7. 移動積送分情報抽出（前月分）
            IF (1 = pre_lot_ctl_tbl(i)) THEN
--
              -- ロット管理品目の場合
              SELECT SUM(NVL(xmld.actual_quantity,0))                             --③移動ロット詳細(アドオン)の実績数量
              INTO  ln_d7_quantity(i)
              FROM  xxinv_mov_req_instr_headers xmrih,                            --①移動依頼/指示ヘッダ(アドオン)
                    xxinv_mov_req_instr_lines xmril,                              --②移動依頼/指示明細(アドオン)
                    xxinv_mov_lot_details xmld,                                   --③移動ロット詳細(アドオン)
                    xxcmn_item_locations_v xilv                                   --④⑤OPM保管場所情報VIEW 
              WHERE xmrih.mov_hdr_id             = xmril.mov_hdr_id               --①の移動ヘッダid =②の移動ヘッダid
              AND   xmril.mov_line_id            = xmld.mov_line_id               --②の移動明細id=③の明細id
              AND   xmrih.shipped_locat_id       = xilv.inventory_location_id     --①の出庫元id=⑤の保管倉庫id
              AND   xilv.whse_code               = pre_whse_code_tbl(i)           --④の倉庫コード= d-6で取得した倉庫コード
              AND   xmril.item_id                = pre_item_id_tbl(i)             --②の品目id= d-6で取得した品目id
-- 2008/11/11 Y.Kawano MOD Start
--              AND   xmrih.status                 IN ('04','05')                   --①のステータス=  "出庫報告有"または"入出庫報告有"
              AND    xmrih.status              IN ('04','06')                   --①のステータス=  "出庫報告有"または"入出庫報告有"
-- 2008/11/11 Y.Kawano MOD End
              AND   xmril.delete_flg             = 'N'                            --②の取消フラグ= "off"
              AND   xmld.document_type_code      = '20'                           --③の文書タイプ= "移動"
              AND   xmld.record_type_code        = '20'                           --③のレコードタイプ= "出庫実績"
              -- 2008/05/07 mod 日付TRUNC対応 start
              --AND   xmrih.actual_ship_date       BETWEEN ld_pre_invent_begin_ymd
              --                                   AND     ld_pre_invent_end_ymd    --①の出庫実績日の年月=起動パラメータの対象年月の前月
              --AND  (xmrih.actual_arrival_date    > ld_pre_invent_end_ymd          --①の入庫実績日の年月＞起動パラメータの対象年月の前月
              --      OR xmrih.actual_arrival_date IS NULL                          --①の入庫実績日= 指定なし  
              --     )
              AND   TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                  AND     TRUNC(ld_pre_invent_end_ymd)  --①の出庫実績日の年月=起動パラメータの対象年月の前月
              AND  (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_pre_invent_end_ymd)     --①の入庫実績日の年月＞起動パラメータの対象年月の前月
                    OR xmrih.actual_arrival_date IS NULL                          --①の入庫実績日= 指定なし  
                   )
              -- 2008/05/07 mod 日付TRUNC対応 end
              AND   xmld.lot_id = pre_lot_id_tbl(i)                               --③のロットid = d-6で取得したロットid
              GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
            ELSE
--
              -- ロット管理品目以外の場合
              SELECT SUM(NVL(xmril.shipped_quantity,0))                           --②移動依頼/指示明細(アドオン)の出庫実績数量
              INTO ln_d7_quantity(i)
              FROM  xxinv_mov_req_instr_headers xmrih,                            --①移動依頼/指示ヘッダ(アドオン)
                    xxinv_mov_req_instr_lines xmril,                              --②移動依頼/指示明細(アドオン)
                    xxcmn_item_locations_v xilv                                   --④⑤OPM保管場所情報VIEW 
              WHERE xmrih.mov_hdr_id             = xmril.mov_hdr_id               --①の移動ヘッダid =②の移動ヘッダid
              AND   xmrih.shipped_locat_id       = xilv.inventory_location_id     --①の出庫元id=⑤の保管倉庫id
              AND   xilv.whse_code               = pre_whse_code_tbl(i)           --④の倉庫コード= d-6で取得した倉庫コード
              AND   xmril.item_id                = pre_item_id_tbl(i)             --②の品目id= d-6で取得した品目id
-- 2008/11/11 Y.Kawano MOD Start
--              AND   xmrih.status                 IN ('04','05')                   --①のステータス=  "出庫報告有"または"入出庫報告有"
              AND    xmrih.status              IN ('04','06')                   --①のステータス=  "出庫報告有"または"入出庫報告有"
-- 2008/11/11 Y.Kawano MOD End
              AND   xmril.delete_flg             = 'N'                            --②の取消フラグ= "off"
              -- 2008/05/07 mod 日付TRUNC対応 start
              --AND   xmrih.actual_ship_date       BETWEEN ld_pre_invent_begin_ymd
              --                                   AND     ld_pre_invent_end_ymd    --①の出庫実績日の年月=起動パラメータの対象年月の前月
              --AND  (xmrih.actual_arrival_date    > ld_pre_invent_end_ymd          --①の入庫実績日の年月＞起動パラメータの対象年月の前月
              --      OR xmrih.actual_arrival_date IS NULL                          --①の入庫実績日= 指定なし
              --     )
              AND   TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                  AND TRUNC(ld_pre_invent_end_ymd)    --①の出庫実績日の年月=起動パラメータの対象年月の前月
              AND  (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_pre_invent_end_ymd)   --①の入庫実績日の年月＞起動パラメータの対象年月の前月
                    OR xmrih.actual_arrival_date IS NULL                              --①の入庫実績日= 指定なし
                   )
              -- 2008/05/07 mod 日付TRUNC対応 end
              GROUP BY xilv.whse_code, xmril.item_code;
--
            END IF;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_d7_quantity(i):=0;
          END;
--
          BEGIN
--
            -- D-8. 出荷・有償積送分情報抽出（前月分）
            lv_item_cd := TO_CHAR(pre_item_no_tbl(i));
--
            IF (1 = pre_lot_ctl_tbl(i)) THEN
--
              -- ロット管理品目の場合
              SELECT SUM(NVL(xmld.actual_quantity,0))                             -- ③移動ロット詳細(アドオン)の実績数量
              INTO  ln_d8_quantity(i)
              FROM  xxwsh_order_headers_all xoha,                                 -- ①受注ヘッダアドオン
                    xxwsh_order_lines_all xola,                                   -- ②受注明細アドオン
                    xxinv_mov_lot_details xmld,                                   -- ③移動ロット詳細(アドオン)
                    xxcmn_item_locations_v xilv,                                  -- ④⑤OPM保管場所情報VIEW   
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--                    mtl_system_items_b msib                                       -- ⑥品目マスタ
                    ic_item_mst_b iimb                                            -- ⑥品目マスタ
-- 2008/10/02 v1.7 Y.Yamamoto Update End
              WHERE xoha.order_header_id         = xola.order_header_id           -- ①の受注ヘッダアドオンID= ②の受注ヘッダアドオンID
              AND   xola.order_line_id           = xmld.mov_line_id               -- ②の受注明細アドオンID    = ③の明細ID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- ①の出荷元ID= ⑤の保管倉庫ID
              AND   xilv.whse_code                = pre_whse_code_tbl(i)          -- ④の倉庫コード= D-2で取得した倉庫コード
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--              AND   xola.shipping_inventory_item_id = msib.inventory_item_id      -- ②の出荷品目ID= ⑥の品目ID
--              AND   msib.segment1                = lv_item_cd                     -- ⑥の品目コード= D-2で取得した品目コード
              AND   iimb.item_no                 = lv_item_cd                     -- ⑥の品目コード= D-2で取得した品目コード
              AND   xola.shipping_item_code      = iimb.item_no                   -- ②の出荷品目ID= ⑥の品目ID
              AND   iimb.item_id                 = xmld.item_id                   -- ⑥の品目ID    = D-2で取得した品目ID
-- 2008/10/02 v1.7 Y.Yamamoto Update End
              AND   xoha.req_status              IN ('04','08')                   -- ①のステータス= "出荷実績計上済"
              AND   xoha.latest_external_flag    = 'Y'                            -- ①の最新フラグ= "ON"
              AND   xola.delete_flag             = 'N'                            -- ②の削除フラグ= "OFF"
              AND   xmld.document_type_code      IN ('10','30')                   -- ③の文書タイプ= "出荷依頼" または "支給指示"
              AND   xmld.record_type_code        = '20'                           -- ③のレコードタイプ = "出庫実績"
              -- 2008/05/07 mod 日付TRUNC対応 start
              --AND   xoha.shipped_date            BETWEEN ld_pre_invent_begin_ymd 
              --                                   AND     ld_pre_invent_end_ymd    -- ①の出荷日の年月=起動パラメータの対象年月の前月
              --AND  (xoha.arrival_date            > ld_pre_invent_end_ymd          -- ①の着荷日の年月＞起動パラメータの対象年月の前月
              --      OR xoha.arrival_date IS NULL                                  -- ①の着荷日=指定なし
              --     )
-- 2008/08/28 Mod
--              AND   TRUNC(xoha.shipped_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
              AND   TRUNC(xoha.shipped_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                 AND TRUNC(ld_pre_invent_end_ymd)   -- ①の出荷日の年月=起動パラメータの対象年月の前月
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_pre_invent_end_ymd)         -- ①の着荷日の年月＞起動パラメータの対象年月の前月
                    OR xoha.arrival_date IS NULL                                    -- ①の着荷日=指定なし
                   )
              -- 2008/05/07 mod 日付TRUNC対応 end
              AND   xmld.lot_id = pre_lot_id_tbl(i)                               -- ③のロットid = d-2で取得したロットid
-- 2008/10/02 v1.7 Y.Yamamoto Delete Start
--              AND   msib.organization_id         = lv_orgid_div                   -- ⑥組織ID = プロファイル：マスタ組織ID
-- 2008/10/02 v1.7 Y.Yamamoto Delete End
              GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
            ELSE
--
              -- ロット管理品目以外の場合
              SELECT SUM(NVL(xola.shipped_quantity,0))                            -- ②受注明細アドオンの出庫実績数量
              INTO  ln_d8_quantity(i)
              FROM  xxwsh_order_headers_all xoha,                                 -- ①受注ヘッダアドオン
                    xxwsh_order_lines_all xola,                                   -- ②受注明細アドオン
                    xxcmn_item_locations_v xilv,                                  -- ④⑤OPM保管場所情報VIEW   
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--                    mtl_system_items_b msib,                                      -- ⑥品目マスタ
                    ic_item_mst_b iimb,                                           -- ⑥品目マスタ
-- 2008/10/02 v1.7 Y.Yamamoto Update End
	                  xxcmn_item_mst_v ximv                                       -- OPM品目情報VIEW
              WHERE xoha.order_header_id         = xola.order_header_id           -- ①の受注ヘッダアドオンID= ②の受注ヘッダアドオンID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- ①の出荷元ID= ⑤の保管倉庫ID
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--              AND   msib.segment1                = ximv.item_no
              AND   iimb.item_no                 = ximv.item_no
-- 2008/10/02 v1.7 Y.Yamamoto Update End
              AND   xilv.whse_code                = pre_whse_code_tbl(i)          -- ④の倉庫コード= D-2で取得した倉庫コード
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--              AND   xola.shipping_inventory_item_id = msib.inventory_item_id      -- ②の出荷品目ID= ⑥の品目ID
--              AND   msib.segment1                = lv_item_cd                     -- ⑥の品目コード= D-2で取得した品目コード
              AND   iimb.item_no                 = lv_item_cd                     -- ⑥の品目コード= D-2で取得した品目コード
              AND   xola.shipping_item_code      = iimb.item_no                   -- ②の出荷品目ID= ⑥の品目ID
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
              AND   xoha.req_status              IN ('04','08')                   -- ①のステータス= "出荷実績計上済"
              AND   xoha.latest_external_flag    = 'Y'                            -- ①の最新フラグ= "ON"
              AND   xola.delete_flag             = 'N'                            -- ②の削除フラグ= "OFF"
              -- 2008/05/07 mod 日付TRUNC対応 start
              --AND   xoha.shipped_date            BETWEEN ld_pre_invent_begin_ymd 
              --                                   AND     ld_pre_invent_end_ymd    -- ①の出荷日の年月=起動パラメータの対象年月の前月
              --AND  (xoha.arrival_date            > ld_pre_invent_end_ymd          -- ①の着荷日の年月＞起動パラメータの対象年月の前月
              --      OR xoha.arrival_date IS NULL                                  -- ①の着荷日=指定なし
              --     )
-- 2008/08/28 Mod
--              AND   TRUNC(xoha.shipped_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
              AND   xoha.shipped_date BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                 AND TRUNC(ld_pre_invent_end_ymd)    -- ①の出荷日の年月=起動パラメータの対象年月の前月
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_pre_invent_end_ymd)       -- ①の着荷日の年月＞起動パラメータの対象年月の前月
                    OR xoha.arrival_date IS NULL                                  -- ①の着荷日=指定なし
                   )
              -- 2008/05/07 mod 日付TRUNC対応 start
-- 2008/10/02 v1.7 Y.Yamamoto Delete Start
--              AND   msib.organization_id         = lv_orgid_div                   -- ⑥組織ID = プロファイル：マスタ組織ID
-- 2008/10/02 v1.7 Y.Yamamoto Delete End
              GROUP BY xilv.whse_code, ximv.item_id;
--
            END IF;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_d8_quantity(i):=0;
          END;
-- 2008/12/12 v1.9 Y.Yamamoto add start
          BEGIN
            -- D-14. 移動積送分情報抽出 数量前月分
            lv_item_cd := TO_CHAR(pre_item_no_tbl(i));
--
            IF (1 = pre_lot_ctl_tbl(i)) THEN
              -- ロット管理品目の場合
              SELECT SUM(NVL(xmld.actual_quantity,0))                             -- ③移動ロット詳細(アドオン)の実績数量
              INTO   ln_d14_quantity(i)
              FROM   xxinv_mov_req_instr_headers xmrih
                    ,xxinv_mov_req_instr_lines xmril
                    ,xxinv_mov_lot_details xmld                                   --③移動ロット詳細(アドオン)
                    ,xxcmn_item_locations_v xilv                                   --④⑤OPM保管場所情報VIEW 
              WHERE xmrih.mov_hdr_id        = xmril.mov_hdr_id
              AND   xmril.mov_line_id       = xmld.mov_line_id               --②の移動明細id=③の明細id
              AND   xmrih.shipped_locat_id  = xilv.inventory_location_id     --①の出庫元id=⑤の保管倉庫id
              AND   xilv.whse_code          = pre_whse_code_tbl(i)         --④の倉庫コード= d-2で取得した倉庫コード
              AND   xmril.item_id           = pre_item_id_tbl(i)            --②の品目id= d-2で取得した品目id
              AND   xmrih.status           IN ('04','06')                    --①のステータス=  "出庫報告有"または"入出庫報告有"
              AND   xmrih.comp_actual_flg   = 'N'
              AND   xmril.delete_flg        = 'N'
              AND   xmld.document_type_code = '20'                           --③の文書タイプ= "移動"
              AND   xmld.record_type_code   = '20'                           --③のレコードタイプ= "出庫実績"
              AND   TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                  AND TRUNC(ld_pre_invent_end_ymd)    --①の出庫実績日の年月=起動パラメータの対象年月の前月
              AND  (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_pre_invent_end_ymd)   --①の入庫実績日の年月＞起動パラメータの対象年月の前月
                    OR xmrih.actual_arrival_date IS NULL                              --①の入庫実績日= 指定なし
                   )
              AND  xmld.lot_id = pre_lot_id_tbl(i)                               --③のロットid = d-6で取得したロットid
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_xfer_mst ixm
                                     ,ic_tran_pnd itp
                               WHERE  itp.doc_type      = 'XFER'
                               AND    itp.completed_ind = 1
                               AND    itp.reason_code   = 'X122'
                               AND    itp.doc_id        = ixm.transfer_id
                               AND    ixm.attribute1    = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM            = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'TRNI'
                               AND    itc.reason_code = 'X122'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'ADJI'
                               AND    itc.reason_code = 'X123'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
            ELSE
--
              -- ロット管理品目以外の場合
              SELECT SUM(NVL(xmril.shipped_quantity,0))                           --②移動依頼/指示明細(アドオン)の出庫実績数量
              INTO   ln_d14_quantity(i)
              FROM   xxinv_mov_req_instr_headers xmrih
                    ,xxinv_mov_req_instr_lines xmril
                    ,xxcmn_item_locations_v xilv                                   --④⑤OPM保管場所情報VIEW 
              WHERE xmrih.mov_hdr_id        = xmril.mov_hdr_id
              AND   xmrih.shipped_locat_id  = xilv.inventory_location_id     --①の出庫元id=⑤の保管倉庫id
              AND   xilv.whse_code          = pre_whse_code_tbl(i)         --④の倉庫コード= d-2で取得した倉庫コード
              AND   xmril.item_id           = pre_item_id_tbl(i)            --②の品目id= d-2で取得した品目id
              AND   xmrih.status           IN ('04','06')                   --①のステータス=  "出庫報告有"または"入出庫報告有"
              AND   xmrih.comp_actual_flg   = 'N'
              AND   xmril.delete_flg        = 'N'
              AND   TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                  AND TRUNC(ld_pre_invent_end_ymd)    --①の出庫実績日の年月=起動パラメータの対象年月の前月
              AND  (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_pre_invent_end_ymd)   --①の入庫実績日の年月＞起動パラメータの対象年月の前月
                    OR xmrih.actual_arrival_date IS NULL                              --①の入庫実績日= 指定なし
                   )
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_xfer_mst ixm
                                     ,ic_tran_pnd itp
                               WHERE  itp.doc_type      = 'XFER'
                               AND    itp.completed_ind = 1
                               AND    itp.reason_code   = 'X122'
                               AND    itp.doc_id        = ixm.transfer_id
                               AND    ixm.attribute1    = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM            = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'TRNI'
                               AND    itc.reason_code = 'X122'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'ADJI'
                               AND    itc.reason_code = 'X123'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              GROUP BY xilv.whse_code, xmril.item_code;
--
            END IF;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_d14_quantity(i):=0;
          END;
--
          BEGIN
            -- D-15.出荷・有償積送分情報抽出前月分
            lv_item_cd := TO_CHAR(pre_item_no_tbl(i));
--
            IF (1 = pre_lot_ctl_tbl(i)) THEN
--
              -- ロット管理品目の場合
              SELECT SUM(NVL(xmld.actual_quantity,0))                             -- ③移動ロット詳細(アドオン)の実績数量
              INTO  ln_d15_quantity(i)
              FROM  xxwsh_order_headers_all xoha
                   ,xxwsh_order_lines_all xola
                   ,xxinv_mov_lot_details xmld                                   -- ③移動ロット詳細(アドオン)
                   ,xxcmn_item_locations_v xilv                                  -- ④⑤OPM保管場所情報VIEW   
                   ,ic_item_mst_b iimb                                            -- ⑥品目マスタ
              WHERE xoha.order_header_id         = xola.order_header_id           -- ①の受注ヘッダアドオンID= ②の受注ヘッダアドオンID
              AND   xola.order_line_id           = xmld.mov_line_id               -- ②の受注明細アドオンID    = ③の明細ID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- ①の出荷元ID= ⑤の保管倉庫ID
              AND   xilv.whse_code               = pre_whse_code_tbl(i)         -- ④の倉庫コード= D-2で取得した倉庫コード
              AND   iimb.item_no                 = lv_item_cd                     -- ⑥の品目コード= D-2で取得した品目コード
              AND   xola.shipping_item_code      = iimb.item_no                   -- ②の出荷品目ID= ⑥の品目ID
              AND   iimb.item_id                 = xmld.item_id                   -- ⑥の品目ID    = D-2で取得した品目ID
              AND   xoha.req_status             IN ('04','08')
              AND   xoha.actual_confirm_class    = 'N'
              AND   xoha.latest_external_flag    = 'Y'                            -- ①の最新フラグ= "ON"
              AND   xola.delete_flag             = 'N'                            -- ②の削除フラグ= "OFF"
              AND   xmld.document_type_code     IN ('10','30')                   -- ③の文書タイプ= "出荷依頼" または "支給指示"
              AND   xmld.record_type_code        = '20'                           -- ③のレコードタイプ = "出庫実績"
              AND   TRUNC(xoha.shipped_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                 AND TRUNC(ld_pre_invent_end_ymd)   -- ①の出荷日の年月=起動パラメータの対象年月の前月
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_pre_invent_end_ymd)         -- ①の着荷日の年月＞起動パラメータの対象年月の前月
                    OR xoha.arrival_date IS NULL                                    -- ①の着荷日=指定なし
                   )
              AND   xmld.lot_id = pre_lot_id_tbl(i)                              -- ③のロットid = d-2で取得したロットid
              AND NOT EXISTS (SELECT 'X'
                              FROM   oe_order_headers_all ooha
                              WHERE  ooha.attribute1 = xoha.request_no
-- 2009/03/30 H.Iida ADD START 本番障害#1346
                              AND    ooha.org_id     = TO_NUMBER(lv_org_id))
-- 2009/03/30 H.Iida ADD END
              GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
            ELSE
--
              -- ロット管理品目以外の場合
              SELECT SUM(NVL(xola.shipped_quantity,0))                            -- ②受注明細アドオンの出庫実績数量
              INTO  ln_d15_quantity(i)
              FROM  xxwsh_order_headers_all xoha
                   ,xxwsh_order_lines_all xola
                   ,xxcmn_item_locations_v xilv                                  -- ④⑤OPM保管場所情報VIEW   
                   ,ic_item_mst_b iimb                                            -- ⑥品目マスタ
                   ,xxcmn_item_mst_v ximv                                       -- OPM品目情報VIEW
              WHERE xoha.order_header_id         = xola.order_header_id           -- ①の受注ヘッダアドオンID= ②の受注ヘッダアドオンID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- ①の出荷元ID= ⑤の保管倉庫ID
              AND   xilv.whse_code               = pre_whse_code_tbl(i)         -- ④の倉庫コード= D-2で取得した倉庫コード
              AND   iimb.item_no                 = lv_item_cd                     -- ⑥の品目コード= D-2で取得した品目コード
              AND   iimb.item_no                 = ximv.item_no
              AND   xola.shipping_item_code      = iimb.item_no                   -- ②の出荷品目ID= ⑥の品目ID
              AND   xoha.req_status             IN ('04','08')
              AND   xoha.actual_confirm_class    = 'N'
              AND   xoha.latest_external_flag    = 'Y'                            -- ①の最新フラグ= "ON"
              AND   xola.delete_flag             = 'N'                            -- ②の削除フラグ= "OFF"
              AND   TRUNC(xoha.shipped_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                 AND TRUNC(ld_pre_invent_end_ymd)   -- ①の出荷日の年月=起動パラメータの対象年月の前月
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_pre_invent_end_ymd)         -- ①の着荷日の年月＞起動パラメータの対象年月の前月
                    OR xoha.arrival_date IS NULL                                    -- ①の着荷日=指定なし
                   )
              AND NOT EXISTS (SELECT 'X'
                              FROM   oe_order_headers_all ooha
                              WHERE  ooha.attribute1 = xoha.request_no
-- 2009/03/30 H.Iida ADD START 本番障害#1346
                              AND    ooha.org_id     = TO_NUMBER(lv_org_id))
-- 2009/03/30 H.Iida ADD END
              GROUP BY xilv.whse_code, ximv.item_id;
--
            END IF;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_d15_quantity(i):=0;
          END;
--
-- 2008/12/12 v1.9 Y.Yamamoto add end
--
-- 2008/09/16 v1.5 Y.Yamamoto Update Start
--        END LOOP pre_cargo_cur;
        END LOOP D6_loop;
--      
--      CLOSE pre_cargo_cur; -- カーソルのクローズ
-- 2008/09/16 v1.5 Y.Yamamoto Update End
--
    EXCEPTION
      -- *** 複数行返戻ハンドラ ***
      WHEN TOO_MANY_ROWS THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE pre_cargo_cur; -- カーソルのクローズ
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--         RAISE global_process_expt;
           RAISE;
--mod end 1.2
      -- *** 値エラーハンドラ ***
      WHEN VALUE_ERROR THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE pre_cargo_cur; -- カーソルのクローズ
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--         RAISE global_process_expt;
           RAISE;
--mod end 1.2
      -- *** ゼロ除算エラーハンドラ ***
      WHEN ZERO_DIVIDE THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE pre_cargo_cur; -- カーソルのクローズ
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--         RAISE global_process_expt;
           RAISE;
--mod end 1.2
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE pre_cargo_cur; -- カーソルのクローズ
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--         RAISE global_process_expt;
           RAISE;
--mod end 1.2
    END;
    -- 前月分終わり
--
--del start 1.3
--    -- D-9. 棚卸月末在庫テーブルロック処理
--    -- テーブルロック関数呼び出し
--    IF NOT (xxcmn_common_pkg.get_tbl_lock('XXINV','XXINV_STC_INVENTORY_MONTH_STCK')) THEN
--      -- リターン・コードにFALSEが返された場合はエラー
--      RAISE global_api_expt;
--    END IF;
--del end 1.3
--
    BEGIN
      -- D-10. 棚卸月末在庫情報出力（削除）
--
--mod start 1.3
--      -- D-2を実行
--      FORALL i IN 1 .. curr_whse_code_tbl.COUNT
--        DELETE FROM xxinv_stc_inventory_month_stck
--        WHERE whse_code = curr_whse_code_tbl(i) -- OPM手持数量  倉庫コード
--        AND   item_id   = curr_item_id_tbl(i)   -- 品目ID
--        AND   invent_ym = iv_invent_ym;         --  起動パラメータの対象年月
----
--      -- D-6を実行
--      FORALL i IN 1 .. pre_whse_code_tbl.COUNT
--        DELETE FROM xxinv_stc_inventory_month_stck
--        WHERE whse_code = pre_whse_code_tbl(i) -- OPM手持数量  倉庫コード
--        AND   item_id   = pre_item_id_tbl(i)   -- 品目ID
--        AND   invent_ym = lv_pre_invent_ym;    -- 起動パラメータの対象年月の前年
--
      FOR i IN 1..del_info.COUNT LOOP
        OPEN cur_del FOR
          SELECT ROWID 
          FROM xxinv_stc_inventory_month_stck
          WHERE whse_code = del_info(i).whse_code
          AND   item_id = del_info(i).item_id
          AND   invent_ym = del_info(i).invent_ym
          FOR UPDATE NOWAIT
          ;
--
        DELETE FROM xxinv_stc_inventory_month_stck
        WHERE whse_code = del_info(i).whse_code
        AND   item_id = del_info(i).item_id
        AND   invent_ym = del_info(i).invent_ym
        ;
      END LOOP;
--mod end 1.3
      -- 棚卸月末在庫IDの取得
      FOR i IN 1..curr_whse_code_tbl.COUNT LOOP
        SELECT xxinv_stc_invt_most_s1.NEXTVAL      -- シーケンス
        INTO   curr_invent_monthly_stock_id(i)
        FROM   dual;
      END LOOP;
--
      -- D-11. 棚卸月末在庫情報出力（登録）
      -- D-2を実行
      FORALL i IN 1 .. curr_whse_code_tbl.COUNT
        INSERT INTO xxinv_stc_inventory_month_stck
          (invent_monthly_stock_id
          ,whse_code
          ,item_id
          ,item_code
          ,lot_id
          ,lot_no
          ,monthly_stock
          ,cargo_stock
          ,invent_ym
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
-- 2008/12/12 v1.9 Y.Yamamoto update start
--          ,program_update_date)
          ,program_update_date
          ,cargo_stock_not_stn)
-- 2008/12/12 v1.9 Y.Yamamoto update end
        VALUES (
           curr_invent_monthly_stock_id(i)       -- 棚卸月末在庫ID
          ,curr_whse_code_tbl(i)                 -- OPM手持数量  倉庫コード
          ,curr_item_id_tbl(i)                   -- OPM品目マスタ 品目ID
          ,curr_item_no_tbl(i)                   -- OPM品目マスタ  品目コード
          ,curr_lot_id_tbl(i)                    -- OPMロットマスタ  ロットID
          ,curr_lot_no_tbl(i)                    -- OPMロットマスタ  ロットNo
          ,NVL(curr_loct_onhand_tbl(i),0) 
           + NVL(ln_d3_itp_trans_qty(i),0) 
           + NVL(ln_d3_itc_trans_qty(i),0)       -- 月末在庫数  計（OPM手持数量  手持数量＋D-3. 数量）
          ,ln_d4_quantity(i) + ln_d5_quantity(i) -- 積送中在庫数（D-4の数量＋D-5の数量）
          ,iv_invent_ym                          -- パラメータの対象年月
          ,ln_user_id
          ,SYSDATE
          ,ln_user_id
          ,SYSDATE
          ,ln_login_id
          ,ln_conc_request_id
          ,ln_prog_appl_id
          ,ln_conc_program_id
-- 2008/12/12 v1.9 Y.Yamamoto update start
--          ,SYSDATE);
          ,SYSDATE
          ,ln_d12_quantity(i) + ln_d13_quantity(i)); -- 標準にない積送中在庫数（D-12の数量＋D-13の数量）
-- 2008/12/12 v1.9 Y.Yamamoto update end
--
      -- 棚卸月末在庫IDの取得
      FOR i IN 1..pre_whse_code_tbl.COUNT LOOP
        SELECT xxinv_stc_invt_most_s1.NEXTVAL      -- シーケンス
        INTO   pre_invent_monthly_stock_id(i)
        FROM   dual;
      END LOOP;
--
      -- D-6を実行
      FORALL i IN 1 .. pre_whse_code_tbl.COUNT
        INSERT INTO xxinv_stc_inventory_month_stck
          (invent_monthly_stock_id
          ,whse_code
          ,item_id
          ,item_code
          ,lot_id
          ,lot_no
          ,monthly_stock
          ,cargo_stock
          ,invent_ym
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
-- 2008/12/12 v1.9 Y.Yamamoto update start
--          ,program_update_date)
          ,program_update_date
          ,cargo_stock_not_stn)
-- 2008/12/12 v1.9 Y.Yamamoto update end
        VALUES (
           pre_invent_monthly_stock_id(i)        -- 棚卸月末在庫ID
          ,pre_whse_code_tbl(i)                  -- OPM手持数量  倉庫コード
          ,pre_item_id_tbl(i)                    -- OPM品目マスタ 品目ID
          ,pre_item_no_tbl(i)                    -- OPM品目マスタ  品目コード
          ,pre_lot_id_tbl(i)                     -- OPMロットマスタ  ロットID
          ,pre_lot_no_tbl(i)                     -- OPMロットマスタ  ロットNo
          ,pre_loct_onhand_tbl(i)                -- 月末在庫数  計（OPM手持数量  手持数量）
          ,NVL(ln_d7_quantity(i),0) 
           + NVL(ln_d8_quantity(i),0)            -- 積送中在庫数（D-7の数量＋D-8の数量）
          ,lv_pre_invent_ym                      -- パラメータの対象年月の前月
          ,ln_user_id
          ,SYSDATE
          ,ln_user_id
          ,SYSDATE
          ,ln_login_id
          ,ln_conc_request_id
          ,ln_prog_appl_id
          ,ln_conc_program_id
-- 2008/12/12 v1.9 Y.Yamamoto update start
--          ,SYSDATE);
          ,SYSDATE
          ,ln_d14_quantity(i) + ln_d15_quantity(i)); -- 標準にない積送中在庫数（D-14の数量＋D-15の数量）
-- 2008/12/12 v1.9 Y.Yamamoto update end
--
        COMMIT; -- コミット
--
    EXCEPTION
      -- *** 重複エラーハンドラ ***
      WHEN DUP_VAL_ON_INDEX THEN
--mod start 1.2
--         RAISE global_process_expt;
           RAISE;
--mod end 1.2
      -- *** 値エラーハンドラ ***
      WHEN VALUE_ERROR THEN
--mod start 1.2
--         RAISE global_process_expt;
           RAISE;
--mod end 1.2
      -- *** 数値変換エラーハンドラ ***
      WHEN INVALID_NUMBER THEN
--mod start 1.2
--         RAISE global_process_expt;
           RAISE;
--mod end 1.2
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
--add start 1.2
        ROLLBACK;
--add end 1.2
--mod start 1.2
--         RAISE global_del_ins_expt;
           RAISE;
--mod end 1.2
    END;
--
    RETURN gn_ret_nomal;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
--del start 1.2
/*
    WHEN global_process_expt THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN gn_ret_other_error;
     -- *** 削除・登録エラーハンドラ ***
    WHEN global_del_ins_expt THEN
      ROLLBACK;-- ロールバック
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN gn_ret_other_error;
    -- *** 共通api関数例外ハンドラ ***
*/
--del end 1.2
    WHEN global_api_expt THEN
      RAISE_APPLICATION_ERROR
--mod start 1.2
--        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||'棚卸月末在庫テーブルロック処理に失敗しました。',1,5000),TRUE);
      RETURN gn_ret_lock_error;
--mod end 1.2
--del start 1.2
/*
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN gn_ret_other_error;
*/
--del end 1.2
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
--mod start 1.2
--        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--mod end 1.2
      RETURN gn_ret_other_error;
   END create_snapshot;
--
--#####################################  固定部 END   ##########################################
--
END xxinv550004c;
/
