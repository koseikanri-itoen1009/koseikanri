CREATE OR REPLACE PACKAGE BODY xxcmn800004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn800004c(body)
 * Description      : 品目マスタインターフェース(Outbound)
 * MD.050           : マスタインタフェース T_MD050_BPO_800
 * MD.070           : 品目マスタインタフェース T_MD070_BPO_80D
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_item_mst           品目マスタ取得プロシージャ (D-1)
 *  output_csv             CSVファイル出力プロシージャ (D-2)
 *  upd_last_update        最終更新日時ファイル更新プロシージャ (D-3)
 *  wf_notif               Workflow通知プロシージャ (D-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/11/26    1.0  Oracle 椎名 昭圭  初回作成
 *  2008/05/08    1.1  Oracle 椎名 昭圭  変更要求#11対応
 *  2008/06/12    1.2  Oracle 丸下       日付項目書式変更
 *  2008/07/11    1.3  Oracle 椎名 昭圭  仕様不備障害#I_S_001.2対応
 *                                       仕様不備障害#I_S_192.1.2対応
 *  2008/09/18    1.4  Oracle 山根 一浩  T_S_460,T_S_453,T_S_575,T_S_559,変更#232対応
 *  2008/10/08    1.5  Oracle 椎名 昭圭  I_S_328対応
 *  2018/02/20    1.6  SCSK佐々木        E_本稼動_14862
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
  get_prof_expt       EXCEPTION;      -- プロファイル取得エラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcmn800004c';      -- パッケージ名
  gv_xxcmn            CONSTANT VARCHAR2(100) := 'XXCMN';             -- アプリケーション短縮名
  gv_prof_err         CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';   -- プロファイル取得エラー
  gv_get_date_err     CONSTANT VARCHAR2(100) := 'APP-XXCMN-10036';   -- データ取得エラー
  gv_file_pass_err    CONSTANT VARCHAR2(100) := 'APP-XXCMN-10113';   -- ファイルパス不正エラー
  gv_file_pass_no_err CONSTANT VARCHAR2(100) := 'APP-XXCMN-10119';   -- ファイルパスNULLエラー
  gv_file_name_err    CONSTANT VARCHAR2(100) := 'APP-XXCMN-10114';   -- ファイル名不正エラー
  gv_file_name_no_err CONSTANT VARCHAR2(100) := 'APP-XXCMN-10120';   -- ファイル名NULLエラー
  gv_file_priv_err    CONSTANT VARCHAR2(100) := 'APP-XXCMN-10115';   -- ファイルアクセス権限エラー
  gv_last_update_err  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10116';   -- 最終更新日時更新エラー
  gv_wf_start_err     CONSTANT VARCHAR2(100) := 'APP-XXCMN-10117';   -- Workflow起動エラー
  gv_wf_ope_div_note  CONSTANT VARCHAR2(100) := 'APP-XXCMN-00013';   -- 処理区分
  gv_object_note      CONSTANT VARCHAR2(100) := 'APP-XXCMN-00014';   -- 対象
  gv_address_note     CONSTANT VARCHAR2(100) := 'APP-XXCMN-00015';   -- 宛先
  gv_last_update_note CONSTANT VARCHAR2(100) := 'APP-XXCMN-00016';   -- 最終更新日時
  gv_syohin_note      CONSTANT VARCHAR2(100) := 'APP-XXCMN-00017';   -- 商品区分
  gv_item_note        CONSTANT VARCHAR2(100) := 'APP-XXCMN-00018';   -- 品目区分
  gv_par_date_err     CONSTANT VARCHAR2(100) := 'APP-XXCMN-10083';   -- パラメータ日付型チェック
  gv_prof_token       CONSTANT VARCHAR2(100) := 'NG_PROFILE';        -- プロファイル取得トークン
  gv_rep_file         CONSTANT VARCHAR2(1)   := '0';                 -- 処理結果レポート
  gv_csv_file         CONSTANT VARCHAR2(1)   := '1';                 -- CSVファイル
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 品目マスタ情報を格納するレコード
  TYPE item_mst_rec IS RECORD(
    item_id               ic_item_mst_b.item_id%TYPE,                       -- 品目ID
    item_no               ic_item_mst_b.item_no%TYPE,                       -- 品目
    parent_item_no        xxcmn_item_mst_v.item_no%TYPE,                    -- 品目(親品目)
    item_name             xxcmn_item_mst_b.item_name%TYPE,                  -- 正式名
    item_short_name       xxcmn_item_mst_b.item_short_name%TYPE,            -- 略称
    attribute22           ic_item_mst_b.attribute22%TYPE,                   -- ITFコード
    attribute21           ic_item_mst_b.attribute21%TYPE,                   -- JANコード
    attribute11           ic_item_mst_b.attribute11%TYPE,                   -- ケース入数
    attribute25           ic_item_mst_b.attribute25%TYPE,                   -- 重量
    attribute16           ic_item_mst_b.attribute16%TYPE,                   -- 容積
    attribute12           ic_item_mst_b.attribute12%TYPE,                   -- NET
    price                 VARCHAR2(240),                                    -- 定価
--2008/09/18 Mod ↓
/*
    shelf_life            xxcmn_item_mst_b.shelf_life%TYPE,                 -- 賞味期間
*/
    expiration_day        xxcmn_item_mst_b.expiration_day%TYPE,             -- 賞味期間
--2008/09/18 Mod ↑
    palette_max_cs_qty    VARCHAR2(2),                                      -- 配数
    palette_max_step_qty  VARCHAR2(2),                                      -- パレット当り最大段数
    palette_step_qty      VARCHAR2(2),                                      -- パレット段
    shelf_life_class      xxcmn_item_mst_b.shelf_life_class%TYPE,           -- 賞味期間区分
    bottle_class          xxcmn_item_mst_b.bottle_class%TYPE,               -- 容器区分
    uom_class             xxcmn_item_mst_b.uom_class%TYPE,                  -- 単位区分
    inventory_chk_class   xxcmn_item_mst_b.inventory_chk_class%TYPE,        -- 棚卸区分
    trace_class           xxcmn_item_mst_b.trace_class%TYPE,                -- トレース区分
    start_date_active     xxcmn_item_mst_b.start_date_active%TYPE,          -- 適用開始日
    last_update_date      DATE,                                             -- 最終更新日時
    cs_weigth_or_capacity xxcmn_item_mst_b.cs_weigth_or_capacity%TYPE,      -- ケース重量容積
    category_set_name     xxcmn_item_categories_v.category_set_name%TYPE,   -- カテゴリセット名
    segment1              xxcmn_item_categories_v.segment1%TYPE,            -- カテゴリコード
    item_class_code       xxcmn_item_categories3_v.item_class_code%TYPE,    -- 品目区分
    in_out_class_code     xxcmn_item_categories3_v.in_out_class_code%TYPE,  -- 内外区分
    obsolete_class        xxcmn_item_mst_b.obsolete_class%TYPE              -- 廃止区分
--  2018/02/20 V1.6 Added START
  , expiration_type       xxcmn_item_mst_b.expiration_type%TYPE             --  表示区分
  , expiration_month      xxcmn_item_mst_b.expiration_month%TYPE            --  賞味期間（月）
--  2018/02/20 V1.6 Added END
  );
--
  -- 品目マスタ情報を格納するテーブル型の定義
  TYPE item_mst_tbl IS TABLE OF item_mst_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_item_mst_tbl    item_mst_tbl;                          -- 結合配列の定義
  gr_outbound_rec    xxcmn_common_pkg.outbound_rec;         -- ファイル情報のレコードの定義
  gd_sysdate         DATE;                                  -- システム現在日付
--
  /**********************************************************************************
   * Procedure Name   : get_item_mst
   * Description      : 品目マスタ取得(D-1)
   ***********************************************************************************/
  PROCEDURE get_item_mst(
    iv_wf_ope_div         IN  VARCHAR2,            -- 処理区分
    iv_wf_class           IN  VARCHAR2,            -- 対象
    iv_wf_notification    IN  VARCHAR2,            -- 宛先
    iv_last_update        IN  VARCHAR2,            -- 最終更新日時
    iv_syohin             IN  VARCHAR2,            -- 商品区分
    iv_item               IN  VARCHAR2,            -- 品目区分
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_mst'; -- プログラム名
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
    cv_item_div     CONSTANT VARCHAR2(100) := '商品区分'; -- プロファイル商品区分
    cv_article_div  CONSTANT VARCHAR2(100) := '品目区分'; -- プロファイル品目区分
--
    -- *** ローカル変数 ***
    lv_item_div     VARCHAR2(100);      -- プロファイル'商品区分'
    lv_article_div  VARCHAR2(100);      -- プロファイル'品目区分'
    ld_last_update  DATE;               -- 最終更新日時
--
    -- *** ローカル・カーソル ***
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
    -- ファイル出力情報取得関数呼び出し
    xxcmn_common_pkg.get_outbound_info(iv_wf_ope_div,     -- 処理区分
                                       iv_wf_class,       -- 対象
                                       iv_wf_notification,-- 宛先
                                       gr_outbound_rec,   -- ファイル情報のレコード型変数
                                       lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                                       lv_retcode,        -- リターン・コード             --# 固定 #
                                       lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- リターン・コードにエラーが返された場合はエラー
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_get_date_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイル値の取得
    lv_item_div := FND_PROFILE.VALUE('XXCMN_ITEM_DIV');
--
    -- 取得できなかった場合はエラー
    IF (lv_item_div IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_prof_err,
                                            gv_prof_token,
                                            cv_item_div);
      lv_errbuf := lv_errmsg;
      RAISE get_prof_expt;
    END IF;
--
    -- プロファイル値の取得
    lv_article_div := FND_PROFILE.VALUE('XXCMN_ARTICLE_DIV');
--
    -- 取得できなかった場合はエラー
    IF (lv_article_div IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_prof_err,
                                            gv_prof_token,
                                            cv_article_div);
      lv_errbuf := lv_errmsg;
      RAISE get_prof_expt;
    END IF;
--
    -- パラメータ'最終更新日時'がNULLの場合
    IF (iv_last_update IS NULL) THEN
      ld_last_update := gr_outbound_rec.file_last_update_date;
      
    -- パラメータ'最終更新日時'がNULLでない場合
    ELSE
      ld_last_update := FND_DATE.STRING_TO_DATE(iv_last_update, 'YYYY/MM/DD HH24:MI:SS');
    END IF;
--
    SELECT  iimb.item_id,                                 -- 品目ID
            iimb.item_no,                                 -- 品目
            (SELECT  ximv.item_no
--2008/10/08 Mod ↓
--            FROM     xxcmn_item_mst_v  ximv
            FROM     ic_item_mst_b  ximv
--2008/10/08 Mod ↑
            WHERE    ximv.item_id = ximb.parent_item_id), -- 品目(親品目)
            ximb.item_name,                               -- 正式名
            ximb.item_short_name,                         -- 略称
            iimb.attribute22,                             -- ITFコード
            iimb.attribute21,                             -- JANコード
            iimb.attribute11,                             -- ケース入数
            iimb.attribute25,                             -- 重量
            iimb.attribute16,                             -- 容積
            iimb.attribute12,                             -- NET
            CASE
              WHEN (iimb.attribute6 <= TO_CHAR(gd_sysdate, 'YYYYMMDD')) THEN
                iimb.attribute5                           -- 新・定価
              ELSE
                iimb.attribute4                           -- 旧・定価
            END,
--2008/09/18 Mod ↓
/*
            ximb.shelf_life,                              -- 賞味期間
*/
            ximb.expiration_day,                          -- 賞味期間
--2008/09/18 Mod ↑
            TO_CHAR(LPAD(ximb.palette_max_cs_qty,2,0)),   -- 配数
            TO_CHAR(LPAD(ximb.palette_max_step_qty,2,0)), -- パレット当り最大段数
            TO_CHAR(LPAD(ximb.palette_step_qty,2,0)),     -- パレット段
            ximb.shelf_life_class,                        -- 賞味期間区分
            ximb.bottle_class,                            -- 容器区分
            ximb.uom_class,                               -- 単位区分
            ximb.inventory_chk_class,                     -- 棚卸区分
            ximb.trace_class,                             -- トレース区分
            ximb.start_date_active,                       -- 適用開始日
            CASE
              -- 最終更新日時がOPM品目アドオンマスタよりOPM品目マスタの方が新しい場合
              WHEN (iimb.last_update_date >= ximb.last_update_date) THEN
                iimb.last_update_date                     -- OPM品目マスタ最終更新日時
              ELSE
                ximb.last_update_date                     -- OPM品目アドオンマスタ最終更新日時
            END,
            ximb.cs_weigth_or_capacity,                   -- ケース重量容積
            xicv.category_set_name,                       -- カテゴリセット名
            xicv.segment1,                                -- カテゴリコード
            xicv3.item_class_code,                        -- 品目区分
            xicv3.in_out_class_code,                      -- 内外区分
            ximb.obsolete_class                           -- 廃止区分
--  2018/02/20 V1.6 Added START
          , ximb.expiration_type      expiration_type     --  表示区分
          , ximb.expiration_month     expiration_month    --  賞味期間（月）
--  2018/02/20 V1.6 Added END
    BULK COLLECT INTO gt_item_mst_tbl
    FROM  xxcmn_item_categories_v   xicv,
          xxcmn_item_categories_v   xicv2,
          ic_item_mst_b             iimb,
          xxcmn_item_mst_b          ximb,
          xxcmn_item_categories3_v  xicv3,
          ((SELECT iimb1.item_id
          FROM     ic_item_mst_b    iimb1
          WHERE    ((iimb1.last_update_date >= ld_last_update) AND
                     (iimb1.last_update_date < gd_sysdate)))
          UNION
          (SELECT  ximb1.item_id
          FROM     xxcmn_item_mst_b ximb1
          WHERE    ((ximb1.last_update_date >= ld_last_update) AND
                     (ximb1.last_update_date < gd_sysdate))))  iimb2
    -- 商品区分
    WHERE ((xicv.category_set_name = lv_item_div) AND
            ((iv_syohin IS NULL) OR
            (xicv.segment1 = iv_syohin)))
    -- 品目区分
    AND   ((xicv2.category_set_name = lv_article_div) AND
            ((iv_item IS NULL) OR
            (xicv2.segment1 = iv_item)))
    AND   iimb.item_id             =  xicv.item_id
    AND   iimb.item_id             =  xicv2.item_id
    AND   iimb.item_id             =  ximb.item_id
    AND   iimb.item_id             =  iimb2.item_id
    AND   iimb.item_id             =  xicv3.item_id
    ORDER BY iimb.item_no, ximb.start_date_active;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
    WHEN get_prof_expt THEN                   --*** プロファイル取得エラー ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
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
  END get_item_mst;
--
  /**********************************************************************************
   * Procedure Name   : output_csv（ループ部）
   * Description      : CSVファイル出力(D-2)
   ***********************************************************************************/
  PROCEDURE output_csv(
    iv_syohin     IN  VARCHAR2,            -- 商品区分
    iv_file_type  IN  VARCHAR2,            -- ファイル種別
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード                    --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- プログラム名
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
    cv_itoen        CONSTANT VARCHAR2(5)   := 'ITOEN';
    cv_xxcmn_d17    CONSTANT VARCHAR2(3)   := '900';
    cv_b_num        CONSTANT NUMBER        :=  92;
    cv_sep_com      CONSTANT VARCHAR2(1)   := ',';
    cv_drink        CONSTANT VARCHAR2(1)   := '2';
    cv_leaf         CONSTANT VARCHAR2(1)   := '1';
    cv_item         CONSTANT VARCHAR2(100) := '商品区分';
--2008/09/18 Add ↓
    lv_crlf           CONSTANT VARCHAR2(1)  := CHR(13); -- 改行コード
--2008/09/18 Add ↑
--
    -- *** ローカル変数 ***
    lf_file_hand    UTL_FILE.FILE_TYPE;    -- ファイル・ハンドルの宣言
    lv_csv_file     VARCHAR2(5000);        -- 出力情報
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
    BEGIN
      -- ファイルパスが指定されていない場合
      IF (gr_outbound_rec.directory IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_file_pass_no_err);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- ファイル名が指定されていない場合
      ELSIF (gr_outbound_rec.file_name IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_file_name_no_err);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- CSVファイルへ出力する場合
      IF (iv_file_type = gv_csv_file) THEN
        lf_file_hand := UTL_FILE.FOPEN(gr_outbound_rec.directory,
                                       gr_outbound_rec.file_name,
                                       'w');
      END IF;
      -- 品目マスタ情報が取得できている場合
      IF (gt_item_mst_tbl.COUNT <> 0) THEN
        <<gt_item_mst_tbl_loop>>
        FOR i IN gt_item_mst_tbl.FIRST .. gt_item_mst_tbl.LAST LOOP
          lv_csv_file   := cv_itoen                                 || cv_sep_com   -- 会社名
                        || cv_xxcmn_d17                             || cv_sep_com   -- EOSデータ種別
                        || cv_b_num                                 || cv_sep_com   -- 伝票用枝番
                        || gt_item_mst_tbl(i).item_no               || cv_sep_com   -- コード1
                        || gt_item_mst_tbl(i).parent_item_no        || cv_sep_com   -- コード2
                                                                    || cv_sep_com   -- コード3
                        || REPLACE(gt_item_mst_tbl(i).item_name, cv_sep_com)
                                                                    || cv_sep_com   -- 名称1
                        || REPLACE(gt_item_mst_tbl(i).item_short_name, cv_sep_com)
                                                                    || cv_sep_com   -- 名称2
                                                                    || cv_sep_com   -- 名称3
                                                                    || cv_sep_com   -- 情報1
                                                                    || cv_sep_com   -- 情報2
                        || gt_item_mst_tbl(i).attribute22           || cv_sep_com   -- 情報3
                                                                    || cv_sep_com   -- 情報4
                                                                    || cv_sep_com   -- 情報5
                                                                    || cv_sep_com   -- 情報6
                                                                    || cv_sep_com   -- 情報7
                        || gt_item_mst_tbl(i).attribute21           || cv_sep_com   -- 情報8
                                                                    || cv_sep_com   -- 情報9
                        || gt_item_mst_tbl(i).attribute11           || cv_sep_com   -- 情報10
                        || gt_item_mst_tbl(i).cs_weigth_or_capacity || cv_sep_com   -- 情報11
                        || CASE
                             -- 商品区分=ドリンクの場合
                             WHEN (gt_item_mst_tbl(i).category_set_name = cv_item)
                             AND  (gt_item_mst_tbl(i).segment1          = cv_drink) THEN
                               gt_item_mst_tbl(i).attribute25
                             -- 商品区分=リーフの場合
                             WHEN (gt_item_mst_tbl(i).category_set_name = cv_item)
                             AND  (gt_item_mst_tbl(i).segment1          = cv_leaf) THEN
                               gt_item_mst_tbl(i).attribute16
                           END                                      || cv_sep_com   -- 情報12
                        || gt_item_mst_tbl(i).attribute12           || cv_sep_com   -- 情報13
                        || gt_item_mst_tbl(i).price                 || cv_sep_com   -- 情報14
--2008/09/18 Mod ↓
/*
                        || gt_item_mst_tbl(i).shelf_life            || cv_sep_com   -- 情報15
*/
                        || gt_item_mst_tbl(i).expiration_day        || cv_sep_com   -- 情報15
--2008/09/18 Mod ↑
--  2018/02/20 V1.6 Modified START
--                                                                    || cv_sep_com   -- 情報16
--                                                                    || cv_sep_com   -- 情報17
                        || gt_item_mst_tbl(i).expiration_type       || cv_sep_com   -- 情報16
                        || gt_item_mst_tbl(i).expiration_month      || cv_sep_com   -- 情報17
--  2018/02/20 V1.6 Modified END
                                                                    || cv_sep_com   -- 情報18
                                                                    || cv_sep_com   -- 情報19
                                                                    || cv_sep_com   -- 情報20
                        || gt_item_mst_tbl(i).palette_max_cs_qty    || cv_sep_com   -- 区分1
                        || gt_item_mst_tbl(i).palette_max_step_qty  || cv_sep_com   -- 区分2
                        || gt_item_mst_tbl(i).palette_step_qty      || cv_sep_com   -- 区分3
                        || gt_item_mst_tbl(i).shelf_life_class      || cv_sep_com   -- 区分4
                        || gt_item_mst_tbl(i).bottle_class          || cv_sep_com   -- 区分5
                        || gt_item_mst_tbl(i).uom_class             || cv_sep_com   -- 区分6
                        || gt_item_mst_tbl(i).inventory_chk_class   || cv_sep_com   -- 区分7
                        || gt_item_mst_tbl(i).trace_class           || cv_sep_com   -- 区分8
                        || gt_item_mst_tbl(i).item_class_code       || cv_sep_com   -- 区分9
                        || gt_item_mst_tbl(i).in_out_class_code     || cv_sep_com   -- 区分10
                        || gt_item_mst_tbl(i).obsolete_class        || cv_sep_com   -- 区分11
                                                                    || cv_sep_com   -- 区分12
                                                                    || cv_sep_com   -- 区分13
                                                                    || cv_sep_com   -- 区分14
                                                                    || cv_sep_com   -- 区分15
                                                                    || cv_sep_com   -- 区分16
                                                                    || cv_sep_com   -- 区分17
                                                                    || cv_sep_com   -- 区分18
                                                                    || cv_sep_com   -- 区分19
                                                                    || cv_sep_com   -- 区分20
                        || TO_CHAR(gt_item_mst_tbl(i).start_date_active, 'YYYY/MM/DD')
                                                                    || cv_sep_com   -- 適用開始日
                        || TO_CHAR(gt_item_mst_tbl(i).last_update_date, 'YYYY/MM/DD HH24:MI:SS')
--2008/09/18 Add ↓
                        || lv_crlf                                                  -- 更新日時
--2008/09/18 Add ↑
                        ;
--
          -- CSVファイルへ出力する場合
          IF (iv_file_type = gv_csv_file) THEN
            UTL_FILE.PUT_LINE(lf_file_hand,lv_csv_file);
          -- 処理結果レポートへ出力する場合
          ELSE
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_csv_file);
          END IF;
--
        END LOOP gt_item_mst_tbl_loop;
      END IF;
      -- CSVファイルへ出力する場合
      IF (iv_file_type = gv_csv_file) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
--
    EXCEPTION
--
      WHEN UTL_FILE.INVALID_PATH THEN       -- ファイルパス不正エラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_file_pass_err);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      WHEN UTL_FILE.INVALID_FILENAME THEN   -- ファイル名不正エラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_file_name_err);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      WHEN UTL_FILE.ACCESS_DENIED THEN      -- ファイルアクセス権限エラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_file_priv_err);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
    END;
--
  --==============================================================
  --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
  --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : upd_last_update
   * Description      : 最終更新日時ファイル更新(D-3)
   ***********************************************************************************/
  PROCEDURE upd_last_update(
    iv_wf_ope_div       IN  VARCHAR2,            -- 処理区分
    iv_wf_class         IN  VARCHAR2,            -- 対象
    iv_wf_notification  IN  VARCHAR2,            -- 宛先
    ov_errbuf           OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_last_update'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ファイル出力情報更新関数呼び出し
    xxcmn_common_pkg.upd_outbound_info(iv_wf_ope_div,     -- 処理区分
                                       iv_wf_class,       -- 対象
                                       iv_wf_notification,-- 宛先
                                       gd_sysdate,        -- システム現在日付
                                       lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                                       lv_retcode,        -- リターン・コード             --# 固定 #
                                       lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- リターン・コードにエラーが返された場合はエラー
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_last_update_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END upd_last_update;
--
  /**********************************************************************************
   * Procedure Name   : wf_notif
   * Description      : Workflow通知(D-4)
   ***********************************************************************************/
  PROCEDURE wf_notif(
    iv_wf_ope_div       IN  VARCHAR2,           -- 処理区分
    iv_wf_class         IN  VARCHAR2,           -- 対象
    iv_wf_notification  IN  VARCHAR2,           -- 宛先
    ov_errbuf           OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wf_notif'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- ワークフロー起動関数呼び出し
    xxcmn_common_pkg.wf_start(iv_wf_ope_div,     -- 処理区分
                              iv_wf_class,       -- 対象
                              iv_wf_notification,-- 宛先
                              lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                              lv_retcode,        -- リターン・コード             --# 固定 #
                              lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- リターン・コードにエラーが返された場合はエラー
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_wf_start_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END wf_notif;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_wf_ope_div        IN  VARCHAR2,        -- 処理区分
    iv_wf_class          IN  VARCHAR2,        -- 対象
    iv_wf_notification   IN  VARCHAR2,        -- 宛先
    iv_last_update       IN  VARCHAR2,        -- 最終更新日時
    iv_syohin            IN  VARCHAR2,        -- 商品区分
    iv_item              IN  VARCHAR2,        -- 品目区分
    ov_errbuf            OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
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
    lc_out_par    VARCHAR2(1000);   -- 入力パラメータ出力
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
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
    -- 初期処理
    -- ===============================
--
    -- 開始時のシステム現在日付を代入
    gd_sysdate := SYSDATE;
--
    -- 入力パラメータの処理結果レポート出力
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_wf_ope_div_note,
                                          'PAR',iv_wf_ope_div);       -- 処理区分
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_object_note,
                                          'PAR',iv_wf_class);         -- 対象
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_address_note,
                                          'PAR',iv_wf_notification);  -- 宛先
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_last_update_note,
                                          'PAR',iv_last_update);      -- 最終更新日時
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_syohin_note,
                                          'PAR',iv_syohin);           -- 商品区分
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_item_note,
                                          'PAR',iv_item);             -- 品目区分
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
    -- パラメータチェック共通関数呼び出し
    IF ((iv_last_update IS NOT NULL) AND
       (xxcmn_common_pkg.check_param_date_yyyymmdd(iv_last_update) = 1)) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_par_date_err);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 品目マスタ取得 (D-1)
    -- ===============================
    get_item_mst(
      iv_wf_ope_div,        -- 処理区分
      iv_wf_class,          -- 対象
      iv_wf_notification,   -- 宛先
      iv_last_update,       -- 最終更新日時
      iv_syohin,            -- 商品区分
      iv_item,              -- 品目区分
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 抽出データの出力
    -- ===============================
    output_csv(
      iv_syohin,         -- 商品区分
      gv_rep_file,       -- 処理結果レポート
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    gn_target_cnt := gt_item_mst_tbl.COUNT;
--
    -- ===============================
    -- CSVファイル出力 (D-2)
    -- ===============================
    output_csv(
      iv_syohin,         -- 商品区分
      gv_csv_file,       -- CSVファイル
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    gn_normal_cnt := gt_item_mst_tbl.COUNT;
--
    -- ===============================
    -- 最終更新日時ファイル更新 (D-3)
    -- ===============================
    upd_last_update(
      iv_wf_ope_div,     -- 処理区分
      iv_wf_class,       -- 対象
      iv_wf_notification,-- 宛先
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--2008/09/18 Add ↓
    IF (gn_target_cnt > 0) THEN
--2008/09/18 Add ↑
--
      -- ===============================
      -- Workflow通知 (D-4)
      -- ===============================
      wf_notif(
        iv_wf_ope_div,     -- 処理区分
        iv_wf_class,       -- 対象
        iv_wf_notification,-- 宛先
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--2008/09/18 Add ↓
    END IF;
--2008/09/18 Add ↑
--
  EXCEPTION
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
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2,     --   エラー・メッセージ  --# 固定 #
    retcode             OUT NOCOPY VARCHAR2,     --   リターン・コード    --# 固定 #
    iv_wf_ope_div       IN  VARCHAR2,            -- 処理区分
    iv_wf_class         IN  VARCHAR2,            -- 対象
    iv_wf_notification  IN  VARCHAR2,            -- 宛先
    iv_last_update      IN  VARCHAR2,            -- 最終更新日時
    iv_syohin           IN  VARCHAR2,            -- 商品区分
    iv_item             IN  VARCHAR2             -- 品目区分
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

    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);

    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);

    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_wf_ope_div,         -- 処理区分
      iv_wf_class,           -- 対象
      iv_wf_notification,    -- 宛先
      iv_last_update,        -- 最終更新日時
      iv_syohin,             -- 商品区分
      iv_item,               -- 品目区分
      lv_errbuf,             -- エラー・メッセージ           --# 固定 #
      lv_retcode,            -- リターン・コード             --# 固定 #
      lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
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
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
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
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
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
END xxcmn800004c;
/
