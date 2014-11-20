CREATE OR REPLACE PACKAGE BODY xxcmn800009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn800009c(body)
 * Description      : 物流構成マスタインターフェース(Outbound)
 * MD.050           : マスタインタフェース T_MD050_BPO_800
 * MD.070           : 物流構成マスタインタフェース T_MD070_BPO_80I
 * Version          : 1.4
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  get_logi_mst           物流構成マスタ取得プロシージャ (I-1)
 *  output_csv             CSVファイル出力プロシージャ (I-2)
 *  upd_last_update        最終更新日時ファイル更新プロシージャ (I-3)
 *  wf_notif               Workflow通知プロシージャ (I-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/15    1.0  Oracle 椎名 昭圭  初回作成
 *  2008/05/01    1.1  Oracle 椎名 昭圭  変更要求#11対応
 *  2008/05/15    1.2  Oracle 椎名 昭圭  内部変更要求#62対応
 *  2008/06/12    1.3  Oracle 丸下       日付項目書式変更
 *  2008/09/18    1.4  Oracle 大橋 孝郎  T_S_460,T_S_575対応
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
  gn_target_cnt    NUMBER;        -- 対象件数
  gn_normal_cnt    NUMBER;        -- 正常件数
  gn_error_cnt     NUMBER;        -- エラー件数
  gn_warn_cnt      NUMBER;        -- スキップ件数
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
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcmn800009c';      -- パッケージ名
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
  -- 物流構成マスタ情報を格納するレコード
  TYPE logi_mst_rec IS RECORD(
    item_id               ic_item_mst_b.item_id%TYPE,                     -- 品目ID
    item_code             xxcmn_sourcing_rules.item_code%TYPE,            -- 品目コード
    base_code             xxcmn_sourcing_rules.base_code%TYPE,            -- 拠点コード
    ship_to_code          xxcmn_sourcing_rules.ship_to_code%TYPE,         -- 配送先コード
    delivery_whse_code    xxcmn_sourcing_rules.delivery_whse_code%TYPE,   -- 出荷倉庫
    move_from_whse_code1  xxcmn_sourcing_rules.move_from_whse_code1%TYPE, -- 移動元倉庫1
    move_from_whse_code2  xxcmn_sourcing_rules.move_from_whse_code2%TYPE, -- 移動元倉庫2
    vendor_site_code1     xxcmn_sourcing_rules.vendor_site_code1%TYPE,    -- 仕入先サイト1
    vendor_site_code2     xxcmn_sourcing_rules.vendor_site_code2%TYPE,    -- 仕入先サイト2
    start_date_active     xxcmn_sourcing_rules.start_date_active%TYPE,    -- 適用開始日
    last_update_date      xxcmn_sourcing_rules.last_update_date%TYPE      -- 最終更新日時
  );
--
  -- 物流構成マスタ情報を格納するテーブル型の定義
  TYPE logi_mst_tbl IS TABLE OF logi_mst_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_logi_mst_tbl    logi_mst_tbl;                          -- 結合配列の定義
  gr_outbound_rec    xxcmn_common_pkg.outbound_rec;         -- ファイル情報のレコードの定義
  gd_sysdate         DATE;                                  -- システム現在日付
--
  /**********************************************************************************
   * Procedure Name   : get_logi_mst
   * Description      : 物流構成マスタ取得(I-1)
   ***********************************************************************************/
  PROCEDURE get_logi_mst(
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_logi_mst'; -- プログラム名
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
    cv_item_code    CONSTANT VARCHAR2(100) := 'ZZZZZZZ';    -- 品目コード
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
    SELECT xsr1.item_id,                   -- 品目ID
           xsr1.item_code,                 -- 品目コード
           xsr1.base_code,                 -- 拠点コード
           xsr1.ship_to_code,              -- 配送先コード
           xsr1.delivery_whse_code,        -- 出荷倉庫
           xsr1.move_from_whse_code1,      -- 移動元倉庫1
           xsr1.move_from_whse_code2,      -- 移動元倉庫2
           xsr1.vendor_site_code1,         -- 仕入先サイト1
           xsr1.vendor_site_code2,         -- 仕入先サイト2
           xsr1.start_date_active,         -- 適用開始日
           xsr1.last_update_date           -- 最終更新日時
    BULK COLLECT INTO gt_logi_mst_tbl
    FROM   (SELECT iimb.item_id,                  -- 品目ID
                   xsr.item_code,                 -- 品目コード
                   xsr.base_code,                 -- 拠点コード
                   xsr.ship_to_code,              -- 配送先コード
                   xsr.delivery_whse_code,        -- 出荷倉庫
                   xsr.move_from_whse_code1,      -- 移動元倉庫1
                   xsr.move_from_whse_code2,      -- 移動元倉庫2
                   xsr.vendor_site_code1,         -- 仕入先サイト1
                   xsr.vendor_site_code2,         -- 仕入先サイト2
                   xsr.start_date_active,         -- 適用開始日
                   xsr.last_update_date           -- 最終更新日時
           FROM    xxcmn_sourcing_rules    xsr,   -- 物流構成アドオンマスタ
                   ic_item_mst_b           iimb,  -- OPM品目マスタ
                   xxcmn_item_categories_v xicv,  -- OPM品目カテゴリ割当情報VIEW
                   xxcmn_item_categories_v xicv1
           -- 商品区分
           WHERE   ((xicv.category_set_name = lv_item_div) AND
                     (xicv.segment1 = NVL(iv_syohin, xicv.segment1)))
           -- 品目区分
           AND     ((xicv1.category_set_name = lv_article_div) AND
                     (xicv1.segment1 = NVL(iv_item, xicv1.segment1)))
           AND     ((xsr.last_update_date >= ld_last_update) AND
                     (xsr.last_update_date < gd_sysdate))
           AND     iimb.item_no        = xsr.item_code
           AND     iimb.item_id        = xicv.item_id
           AND     iimb.item_id        = xicv1.item_id
           UNION
           SELECT NULL,                          -- 品目ID
                  xsr.item_code,                 -- 品目コード
                  xsr.base_code,                 -- 拠点コード
                  xsr.ship_to_code,              -- 配送先コード
                  xsr.delivery_whse_code,        -- 出荷倉庫
                  xsr.move_from_whse_code1,      -- 移動元倉庫1
                  xsr.move_from_whse_code2,      -- 移動元倉庫2
                  xsr.vendor_site_code1,         -- 仕入先サイト1
                  xsr.vendor_site_code2,         -- 仕入先サイト2
                  xsr.start_date_active,         -- 適用開始日
                  xsr.last_update_date           -- 最終更新日時
           FROM   xxcmn_sourcing_rules    xsr    -- 物流構成アドオンマスタ
           WHERE  xsr.item_code = cv_item_code
           AND    ((xsr.last_update_date >= ld_last_update) AND
                    (xsr.last_update_date < gd_sysdate))) xsr1
    ORDER BY xsr1.item_code, xsr1.base_code, xsr1.ship_to_code, xsr1.start_date_active;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
--
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
  END get_logi_mst;
--
  /**********************************************************************************
   * Procedure Name   : output_csv（ループ部）
   * Description      : CSVファイル出力(I-2)
   ***********************************************************************************/
  PROCEDURE output_csv(
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
    cv_itoen        CONSTANT VARCHAR2(5)  := 'ITOEN';
    cv_xxcmn_d17    CONSTANT VARCHAR2(3)  := '900';
    cv_b_num        CONSTANT VARCHAR2(2)  := '00';
    cv_sep_com      CONSTANT VARCHAR2(1)  := ',';
-- add start ver1.4
    cv_crlf         CONSTANT VARCHAR2(1)  := CHR(13); -- 改行コード
-- add end ver1.4
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
      -- 物流構成マスタ情報が取得できている場合
      IF (gt_logi_mst_tbl.COUNT <> 0) THEN
        <<gt_logi_mst_tbl_loop>>
        FOR i IN gt_logi_mst_tbl.FIRST .. gt_logi_mst_tbl.LAST LOOP
          lv_csv_file   := cv_itoen                                 || cv_sep_com   -- 会社名
                        || cv_xxcmn_d17                             || cv_sep_com   -- EOSデータ種別
                        || cv_b_num                                 || cv_sep_com   -- 伝票用枝番
                        || gt_logi_mst_tbl(i).item_code             || cv_sep_com   -- コード1
                        || gt_logi_mst_tbl(i).base_code             || cv_sep_com   -- コード2
                        || gt_logi_mst_tbl(i).ship_to_code          || cv_sep_com   -- コード3
                                                                    || cv_sep_com   -- 名称1
                                                                    || cv_sep_com   -- 名称2
                                                                    || cv_sep_com   -- 名称3
                                                                    || cv_sep_com   -- 情報1
                                                                    || cv_sep_com   -- 情報2
                                                                    || cv_sep_com   -- 情報3
                                                                    || cv_sep_com   -- 情報4
                                                                    || cv_sep_com   -- 情報5
                                                                    || cv_sep_com   -- 情報6
                                                                    || cv_sep_com   -- 情報7
                                                                    || cv_sep_com   -- 情報8
                                                                    || cv_sep_com   -- 情報9
                        || gt_logi_mst_tbl(i).vendor_site_code1     || cv_sep_com   -- 情報10
                        || gt_logi_mst_tbl(i).vendor_site_code2     || cv_sep_com   -- 情報11
                        || gt_logi_mst_tbl(i).move_from_whse_code1  || cv_sep_com   -- 情報12
                        || gt_logi_mst_tbl(i).move_from_whse_code2  || cv_sep_com   -- 情報13
                        || gt_logi_mst_tbl(i).delivery_whse_code    || cv_sep_com   -- 情報14
                                                                    || cv_sep_com   -- 情報15
                                                                    || cv_sep_com   -- 情報16
                                                                    || cv_sep_com   -- 情報17
                                                                    || cv_sep_com   -- 情報18
                                                                    || cv_sep_com   -- 情報19
                                                                    || cv_sep_com   -- 情報20
                                                                    || cv_sep_com   -- 区分1
                                                                    || cv_sep_com   -- 区分2
                                                                    || cv_sep_com   -- 区分3
                                                                    || cv_sep_com   -- 区分4
                                                                    || cv_sep_com   -- 区分5
                                                                    || cv_sep_com   -- 区分6
                                                                    || cv_sep_com   -- 区分7
                                                                    || cv_sep_com   -- 区分8
                                                                    || cv_sep_com   -- 区分9
                                                                    || cv_sep_com   -- 区分10
                                                                    || cv_sep_com   -- 区分11
                                                                    || cv_sep_com   -- 区分12
                                                                    || cv_sep_com   -- 区分13
                                                                    || cv_sep_com   -- 区分14
                                                                    || cv_sep_com   -- 区分15
                                                                    || cv_sep_com   -- 区分16
                                                                    || cv_sep_com   -- 区分17
                                                                    || cv_sep_com   -- 区分18
                                                                    || cv_sep_com   -- 区分19
                                                                    || cv_sep_com   -- 区分20
                        || TO_CHAR(gt_logi_mst_tbl(i).start_date_active, 'YYYY/MM/DD')
                                                                    || cv_sep_com   -- 適用開始日
                        || TO_CHAR(gt_logi_mst_tbl(i).last_update_date, 'YYYY/MM/DD HH24:MI:SS')
-- mod start ver1.4
--                        ;                                                           -- 更新日時
                        || cv_crlf;                                                 -- 更新日時
-- mod end ver1.4
--
          -- CSVファイルへ出力する場合
          IF (iv_file_type = gv_csv_file) THEN
            UTL_FILE.PUT_LINE(lf_file_hand,lv_csv_file);
          -- 処理結果レポートへ出力する場合
          ELSE
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_csv_file);
          END IF;
--
        END LOOP gt_logi_mst_tbl_loop;
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
   * Description      : 最終更新日時ファイル更新(I-3)
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
   * Description      : Workflow通知(I-4)
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
    -- 物流構成マスタ取得 (I-1)
    -- ===============================
    get_logi_mst(
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
      gv_rep_file,       -- 処理結果レポート
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    gn_target_cnt := gt_logi_mst_tbl.COUNT;
--
    -- ===============================
    -- CSVファイル出力 (I-2)
    -- ===============================
    output_csv(
      gv_csv_file,       -- CSVファイル
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    gn_normal_cnt := gt_logi_mst_tbl.COUNT;
--
    -- ===============================
    -- 最終更新日時ファイル更新 (I-3)
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
-- add start ver1.4
    IF (gn_normal_cnt > 0) THEN
-- add end ver1.4
      -- ===============================
      -- Workflow通知 (I-4)
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
-- add start ver1.4
    END IF;
-- add end ver1.4
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
    errbuf              OUT NOCOPY VARCHAR2,     -- エラー・メッセージ  --# 固定 #
    retcode             OUT NOCOPY VARCHAR2,     -- リターン・コード    --# 固定 #
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
END xxcmn800009c;
/
