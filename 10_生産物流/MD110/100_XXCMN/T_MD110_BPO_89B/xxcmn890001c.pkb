CREATE OR REPLACE PACKAGE BODY xxcmn890001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn890001c(body)
 * Description      : 物流構成アドオンインポート
 * MD.050           : 物流構成マスタ T_MD050_BPO_890
 * MD.070           : 物流構成アドオンインポート T_MD070_BPO_89B
 * Version          : 1.10
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  disp_report            レポート用データ出力プロシージャ
 *  delete_sr_lines_if     物流構成アドオンインタフェーステーブル削除(B-10)プロシージャ
 *  insert_sr_rules        物流構成アドオンマスタ挿入(B-9)プロシージャ
 *  check_whse_data        倉庫重複チェック(B-8)プロシージャ  
 *  check_whse_data2       倉庫重複チェック2(B-11)プロシージャ  
 *  modify_end_date        適用終了日編集(B-7)ファンクション
 *  delete_sourcing_rules  物流構成アドオンマスタ削除(B-6)プロシージャ
 *  set_table_data         登録対象レコード編集(B-5)プロシージャ
 *  check_data             項目チェック(B-2)(B-3)(B-4)プロシージャ
 *  get_profile            MAX日付取得プロシージャ
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ----------------- -------------------------------------------------
 *  Date          Ver.  Editor            Description
 * ------------- ----- ----------------- -------------------------------------------------
 *  2007/12/10    1.0   ORACLE 青木祐介   main新規作成
 *  2008/04/17    1.1   ORACLE 丸下博宣   拠点、配送先が指定なしの場合存在チェックを実施しない
 *  2008/05/23    1.2   ORACLE 椎名昭圭   内部変更要求#110対応
 *  2008/06/09    1.3   ORACLE 椎名昭圭   仕入先配送先チェックの不具合修正
 *  2008/10/29    1.4   ORACLE 吉元強樹   統合指摘#251対応
 *  2008/11/11    1.5   ORACLE 伊藤ひとみ 仕入先サイト参照先不正対応
 *  2008/11/17    1.6   ORACLE 伊藤ひとみ 統合テスト指摘491対応
 *  2009/06/10    1.7   SCS 丸下          本番障害1204、1439対応
 *  2009/06/29    1.8   SCS 丸下          本番障害1552対応
 *  2009/10/02    1.9   SCS 丸下          本番障害1648
 *  2010/02/12    1.10  SCS 宮川          E_本稼動_01497
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
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  check_sub_main_expt         EXCEPTION;     -- サブメインのエラー
  check_data_expt             EXCEPTION;     -- チェック処理エラー
  check_lock_expt             EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'xxcmn890001c'; -- パッケージ名
  gv_msg_kbn           CONSTANT VARCHAR2(5)   := 'XXCMN';
  -- 処理状況をあらわすステータス
  gn_data_status_normal CONSTANT NUMBER := 0; -- 正常
  gn_data_status_error CONSTANT NUMBER := 1; -- 失敗
  gn_data_status_warn  CONSTANT NUMBER := 2; -- 警告
  --プロファイル
  gv_prf_max_date      CONSTANT VARCHAR2(15) := 'XXCMN_MAX_DATE';
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
  gv_prf_mgr_type2_base_code CONSTANT VARCHAR2(30) := 'XXCMN_MGR_TYPE2_BASE_CODE'; -- XXCMN:物流構成マスタ管理タイプ２拠点コード
-- 2008/11/17 H.Itou Add End
  --トークン
  gv_tkn_ng_profile           CONSTANT VARCHAR2(15) := 'NG_PROFILE';
  gv_tkn_table                CONSTANT VARCHAR2(15) := 'TABLE';
  gv_tkn_ng_item_code         CONSTANT VARCHAR2(15) := 'NG_ITEM_CODE';
  gv_tkn_ng_base_code         CONSTANT VARCHAR2(15) := 'NG_BASE_CODE';
  gv_tkn_ng_ship_to_code      CONSTANT VARCHAR2(15) := 'NG_SHIP_TO_CODE';
  gv_tkn_ng_whse_code         CONSTANT VARCHAR2(15) := 'NG_WHSE_CODE';
  gv_tkn_ng_whse_code1        CONSTANT VARCHAR2(15) := 'NG_WHSE_CODE1';
  gv_tkn_ng_whse_code2        CONSTANT VARCHAR2(15) := 'NG_WHSE_CODE2';
  gv_tkn_ng_whse1             CONSTANT VARCHAR2(15) := 'NG_WHSE_1';
  gv_tkn_ng_whse2             CONSTANT VARCHAR2(15) := 'NG_WHSE_2';
  gv_tkn_ng_vendor_site_code1 CONSTANT VARCHAR2(20) := 'NG_VENDOR_SITE_CODE1';
  gv_tkn_ng_vendor_site_code2 CONSTANT VARCHAR2(20) := 'NG_VENDOR_SITE_CODE2';
  gv_tkn_s_date_act           CONSTANT VARCHAR2(15) := 'S_DATE_ACT';
  gv_tkn_e_date_act           CONSTANT VARCHAR2(15) := 'E_DATE_ACT';
  gv_tkn_ng_table_name        CONSTANT VARCHAR2(15) := 'NG_TABLE_NAME';
-- 2008/10/29 v1.4 T.Yoshimoto Add Start 統合#251
  gv_tkn_object1              CONSTANT VARCHAR2(15) := 'OBJECT1';
  gv_tkn_object2              CONSTANT VARCHAR2(15) := 'OBJECT2';
-- 2008/10/29 v1.4 T.Yoshimoto Add End 統合#251
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
  gv_tkn_item                 CONSTANT VARCHAR2(15) := 'ITEM';
-- 2008/11/17 H.Itou Add End
  --メッセージ番号
  gv_msg_data_normal      CONSTANT VARCHAR2(15) := 'APP-XXCMN-00005'; -- 成功データ(見出し)
  gv_msg_data_error       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00006'; -- エラーデータ(見出し)
  gv_msg_data_warn        CONSTANT VARCHAR2(15) := 'APP-XXCMN-00007'; -- スキップデータ(見出し)
  gv_msg_no_profile       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002'; -- プロファイル取得エラー
  gv_msg_ng_lock          CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019'; -- ロックエラー
  gv_msg_ng_item          CONSTANT VARCHAR2(15) := 'APP-XXCMN-10098'; -- 品目存在NG
  gv_msg_ng_d_item        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10124'; -- 品目適用日NG
  gv_msg_ng_base          CONSTANT VARCHAR2(15) := 'APP-XXCMN-10125'; -- 拠点存在NG
  gv_msg_ng_d_base        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10126'; -- 拠点適用日NG
  gv_msg_ng_ship_to       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10085'; -- 配送先存在NG
  gv_msg_ng_d_ship_to     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10127'; -- 配送先適用日NG
  gv_msg_ng_whse          CONSTANT VARCHAR2(15) := 'APP-XXCMN-10079'; -- 出庫倉庫存在NG
  gv_msg_ng_input_whse1   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10131'; -- 移動元倉庫未入力NG
  gv_msg_ng_whse1         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10057'; -- 移動元倉庫1存在NG
  gv_msg_ng_whse2         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10058'; -- 移動元倉庫2存在NG
  gv_msg_ng_vendor_site1  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10077'; -- 仕入サイト1存在NG
  gv_msg_ng_vendor_site2  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10078'; -- 仕入サイト2存在NG
  gv_msg_ng_plan_item_flg CONSTANT VARCHAR2(15) := 'APP-XXCMN-10129'; -- 計画商品フラグ存在NG
  gv_msg_ng_date_act      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10130'; -- 適用日付NG
  gv_msg_rep_key          CONSTANT VARCHAR2(15) := 'APP-XXCMN-10055'; -- 主キー重複NG
  gv_msg_rep_whse         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10128'; -- 倉庫重複NG
-- 2008/10/29 v1.4 T.Yoshimoto Add Start 統合#251
  gv_msg_rep_whse2        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10158'; -- 倉庫重複2NG
-- 2008/10/29 v1.4 T.Yoshimoto Add End 統合#251
  gv_msg_ng_base_ship_to  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10132'; -- 拠点／配送先NG
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
  gv_msg_xxcmn_10606      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10606'; -- 指定不可エラー
  gv_msg_xxcmn_10607      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10607'; -- 移動元保管場所キーチェックエラー
  gv_msg_xxcmn_10608      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10608'; -- 主キー重複NG(管理タイプ2用)
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
--
  -- 対象DB名
  gv_xxcmn_sr_lines_if CONSTANT VARCHAR2(100) := '物流構成アドオンインタフェース';
-- 2008/10/29 v1.4 T.Yoshimoto Add Start 統合#251
  -- 対象カラム名
  gv_colmun1           CONSTANT VARCHAR2(100) := '出庫倉庫';
  gv_colmun2           CONSTANT VARCHAR2(100) := '移動元倉庫1';
  gv_colmun3           CONSTANT VARCHAR2(100) := '移動元倉庫2';
-- 2008/10/29 v1.4 T.Yoshimoto Add End 統合#251
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
  gv_colmun4           CONSTANT VARCHAR2(100) := '仕入先サイト1';
  gv_colmun5           CONSTANT VARCHAR2(100) := '仕入先サイト2';
  gv_colmun6           CONSTANT VARCHAR2(100) := '計画商品フラグ';
-- 2008/11/17 H.Itou Add End
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
  -- ダミーコード
  gv_no_ship_to_code   CONSTANT VARCHAR2(10) := '000000000'; -- 配送先コード（指定なし）
-- 2008/11/17 H.Itou Add End
-- 2009/06/10 ADD START
  gv_xxcmn_sourcing_rules CONSTANT VARCHAR2(100) := '物流構成アドオンマスタ';
-- 2009/06/10 ADD END
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 物理構成アドオンマスタへの反映処理に必要なデータを格納するレコード
  TYPE sr_line_rec IS RECORD(
    -- 物流構成アドオンインタフェース
    sourcing_rules_id    xxcmn_sourcing_rules.sourcing_rules_id%TYPE,    -- 物流構成アドオンID
    item_code            xxcmn_sourcing_rules.item_code%TYPE,            -- 品目コード
    base_code            xxcmn_sourcing_rules.base_code%TYPE,            -- 拠点コード
    ship_to_code         xxcmn_sourcing_rules.ship_to_code%TYPE,         -- 配送先コード
    start_date_active    xxcmn_sourcing_rules.start_date_active%TYPE,    -- 適用開始日
    end_date_active      xxcmn_sourcing_rules.end_date_active%TYPE,      -- 適用終了日
    delivery_whse_code   xxcmn_sourcing_rules.delivery_whse_code%TYPE,   -- 出庫倉庫コード
    move_from_whse_code1 xxcmn_sourcing_rules.move_from_whse_code1%TYPE, -- 移動元倉庫コード1
    move_from_whse_code2 xxcmn_sourcing_rules.move_from_whse_code2%TYPE, -- 移動元倉庫コード2
    vendor_site_code1    xxcmn_sourcing_rules.vendor_site_code1%TYPE,    -- 仕入先サイトコード1
    vendor_site_code2    xxcmn_sourcing_rules.vendor_site_code2%TYPE,    -- 仕入先サイトコード2
    plan_item_flag       xxcmn_sourcing_rules.plan_item_flag%TYPE,       -- 計画商品フラグ
-- 2009/06/10 ADD START
    delete_key           xxcmn_sourcing_rules.sourcing_rules_id%TYPE,    -- 削除キー
-- 2009/06/10 ADD END
--
    row_level_status     NUMBER,                                         -- 0.正常,1.失敗,2.警告
    message              VARCHAR2(1000)                                  -- 表示用メッセージ
--
  );
--
  TYPE sr_line_tbl IS TABLE OF sr_line_rec INDEX BY PLS_INTEGER;
--
  -- 物理構成アドオンインタフェース情報を格納するテーブル型の定義
  TYPE request_id_tbl IS TABLE OF xxcmn_sourcing_rules.request_id%TYPE INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_max_date            VARCHAR2(10); -- 最大日付
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
  gv_dummy_base_code     VARCHAR2(10); -- XXCMN:物流構成マスタ管理タイプ２拠点コード
-- 2008/11/17 H.Itou Add End
  gn_data_status         NUMBER := 0;  -- データチェックステータス
  gn_request_id_cnt      NUMBER := 0;  -- リクエストID数
  gt_sr_line_tbl         sr_line_tbl;
  gt_request_id_tbl      request_id_tbl;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : レポート用データ出力プロシージャ
   ***********************************************************************************/
  PROCEDURE disp_report(
    disp_kbn       IN         NUMBER,       -- 表示対象区分(0:正常,1:異常,2:警告)
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_report'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   ############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_report_rec sr_line_rec;
    ln_disp_cnt   NUMBER;
    lv_dspbuf     VARCHAR2(5000);  -- エラー・メッセージ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ###############################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   ############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- 正常
    IF (disp_kbn = gn_data_status_normal) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_data_normal);
--
    -- エラー
    ELSIF (disp_kbn = gn_data_status_error) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_data_error);
--
    -- 警告
    ELSIF (disp_kbn = gn_data_status_warn) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_data_warn);
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dspbuf);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- 設定されているレポートの出力
    <<disp_report_loop>>
    FOR ln_disp_cnt IN 1..gn_target_cnt LOOP
      lr_report_rec := gt_sr_line_tbl(ln_disp_cnt);
--
      -- 対象
      IF (lr_report_rec.row_level_status = disp_kbn) THEN
--
        --入力データの再構成
        lv_dspbuf := lr_report_rec.item_code||gv_msg_pnt
                    ||lr_report_rec.base_code||gv_msg_pnt
                    ||lr_report_rec.ship_to_code||gv_msg_pnt
                    ||TO_CHAR(lr_report_rec.start_date_active,'YYYY/MM/DD')||gv_msg_pnt
                    ||TO_CHAR(lr_report_rec.end_date_active,'YYYY/MM/DD')||gv_msg_pnt
                    ||lr_report_rec.delivery_whse_code||gv_msg_pnt
                    ||lr_report_rec.move_from_whse_code1||gv_msg_pnt
                    ||lr_report_rec.move_from_whse_code2||gv_msg_pnt
                    ||lr_report_rec.vendor_site_code1||gv_msg_pnt
                    ||lr_report_rec.vendor_site_code2||gv_msg_pnt
-- 2009/06/10 MOD START
--                    ||TO_CHAR(lr_report_rec.plan_item_flag);
                    ||TO_CHAR(lr_report_rec.plan_item_flag)||gv_msg_pnt
                    ||TO_CHAR(lr_report_rec.delete_key);
-- 2009/06/10 MOD END
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
        -- 正常以外
        IF (disp_kbn > gn_data_status_normal) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message);
        END IF;
--
      END IF;
--
    END LOOP disp_report_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ######################################
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
--#####################################  固定部 END   ############################################
--
  END disp_report;
--
  /**********************************************************************************
   * Procedure Name   : delete_sr_lines_if
   * Description      : 物流構成アドオンインタフェーステーブル削除(B-10)プロシージャ
   ***********************************************************************************/
  PROCEDURE delete_sr_lines_if(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY  VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_sr_lines_if'; -- プログラム名
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
    <<request_id_loop>>
    FORALL ln_count IN 1..gn_request_id_cnt
      DELETE xxcmn_sr_lines_if xsli             -- 物流構成アドオンマスタインタフェース
      WHERE  xsli.request_id = gt_request_id_tbl(ln_count)  -- 要求ID
      ;
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
  END delete_sr_lines_if;
--
  /**********************************************************************************
   * Procedure Name   : insert_sr_rules
   * Description      : 物流構成アドオンマスタ挿入(B-9)プロシージャ
   ***********************************************************************************/
  PROCEDURE insert_sr_rules(
    ir_sr_line                IN sr_line_rec,       -- 1.レコード
    in_insert_user_id         IN NUMBER,            -- 2.ユーザーID  
    id_insert_date            IN DATE,              -- 3.更新日
    in_insert_login_id        IN NUMBER,            -- 4.ログインID
    in_insert_request_id      IN NUMBER,            -- 5.要求ID
    in_insert_program_appl_id IN NUMBER,            -- 6.コンカレント・プログラムのアプリケーションID
    in_insert_program_id      IN NUMBER,            -- 7.コンカレント・プログラムID
    ov_errbuf                 OUT NOCOPY VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode                OUT NOCOPY  VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg                 OUT NOCOPY  VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_sr_rules'; -- プログラム名
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
    -- 登録処理
    INSERT INTO xxcmn_sourcing_rules -- 物流構成アドオンマスタ
    (sourcing_rules_id,
     item_code,
     base_code,
     ship_to_code,
     start_date_active,
     end_date_active,
     delivery_whse_code,
     move_from_whse_code1,
     move_from_whse_code2,
     vendor_site_code1,
     vendor_site_code2,
     plan_item_flag,
     created_by,
     creation_date,
     last_updated_by,
     last_update_date,
     last_update_login,
     request_id,
     program_application_id,
     program_id,
     program_update_date
    )
    VALUES (
      ir_sr_line.sourcing_rules_id,
      ir_sr_line.item_code,
      ir_sr_line.base_code,
      ir_sr_line.ship_to_code,
      ir_sr_line.start_date_active,
      ir_sr_line.end_date_active,
      ir_sr_line.delivery_whse_code,
      ir_sr_line.move_from_whse_code1,
      ir_sr_line.move_from_whse_code2,
      ir_sr_line.vendor_site_code1,
      ir_sr_line.vendor_site_code2,
      ir_sr_line.plan_item_flag,
      in_insert_user_id,
      id_insert_date,
      in_insert_user_id,
      id_insert_date,
      in_insert_login_id,
      in_insert_request_id,
      in_insert_program_appl_id,
      in_insert_program_id,
      id_insert_date
    );
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
  END insert_sr_rules;
--
  /**********************************************************************************
   * Procedure Name   : check_whse_data
   * Description      : 倉庫重複チェック(B-8)プロシージャ
   ***********************************************************************************/
  PROCEDURE check_whse_data(
    ir_sr_line    IN OUT NOCOPY sr_line_rec,  -- 1.レコード
    ov_errbuf     OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY  VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_whse_data'; -- プログラム名
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
    ln_count NUMBER := 0;
    ld_max_date DATE ;
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
    ld_max_date := FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD');
--
    -- 物流構成アドオンマスタ倉庫重複チェック
    SELECT COUNT(xsr.sourcing_rules_id)
    INTO ln_count
    FROM xxcmn_sourcing_rules xsr -- 物流構成アドオンマスタ
    WHERE xsr.item_code = ir_sr_line.item_code                       -- 品目コード
      AND xsr.delivery_whse_code = ir_sr_line.delivery_whse_code     -- 出庫倉庫コード
      AND xsr.move_from_whse_code1 = ir_sr_line.move_from_whse_code1 -- 移動元倉庫コード1
      AND xsr.move_from_whse_code2 = ir_sr_line.move_from_whse_code2 -- 移動元倉庫コード2
      AND xsr.vendor_site_code1 = ir_sr_line.vendor_site_code1       -- 仕入先サイトコード1
      AND((
      xsr.start_date_active <= ir_sr_line.start_date_active
      AND NVL(xsr.end_date_active, ld_max_date)  >= NVL(ir_sr_line.end_date_active, ld_max_date)
      )OR(
      xsr.start_date_active >= ir_sr_line.start_date_active
      AND xsr.start_date_active  <= NVL(ir_sr_line.end_date_active, ld_max_date)
      )OR(
      NVL(xsr.end_date_active, ld_max_date) >= ir_sr_line.start_date_active
      AND NVL(xsr.end_date_active, ld_max_date)  <= NVL(ir_sr_line.end_date_active, ld_max_date)
      ))
      AND ROWNUM = 1;
--
    IF (ln_count = 1 ) THEN
      -- 倉庫重複チェックNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_rep_whse,
                              gv_tkn_ng_item_code, ir_sr_line.item_code,
                              gv_tkn_ng_base_code,ir_sr_line.base_code,
                              gv_tkn_ng_ship_to_code,ir_sr_line.ship_to_code,
                              gv_tkn_s_date_act,
                              TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD'),
                              gv_tkn_e_date_act,
                              TO_CHAR(ir_sr_line.end_date_active, 'YYYY/MM/DD'),
                              gv_tkn_ng_whse_code, ir_sr_line.delivery_whse_code,
                              gv_tkn_ng_whse1, ir_sr_line.move_from_whse_code1,
                              gv_tkn_ng_whse2, ir_sr_line.move_from_whse_code2,
                              gv_tkn_ng_vendor_site_code1, ir_sr_line.vendor_site_code1);
      RAISE check_data_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データチェック処理エラー ***
    WHEN check_data_expt THEN
      ir_sr_line.row_level_status := gn_data_status_warn;
      gn_data_status := gn_data_status_warn;
      ov_retcode := gv_status_warn;
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
  END check_whse_data;
  --
-- 2008/10/29 v1.4 T.Yoshimoto Add Start 統合#251
  /**********************************************************************************
   * Procedure Name   : check_whse_data2
   * Description      : 倉庫重複チェック2(B-11)プロシージャ
   ***********************************************************************************/
  PROCEDURE check_whse_data2(
    ir_sr_line    IN OUT NOCOPY sr_line_rec,  -- 1.レコード
    ov_errbuf     OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY  VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_whse_data2'; -- プログラム名
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
    -- 移動元倉庫1が設定されている場合且つ、出庫倉庫と同じ場合
    IF ( ( ir_sr_line.delivery_whse_code IS NOT NULL )
      AND ( ir_sr_line.move_from_whse_code1 IS NOT NULL )
      AND ( ir_sr_line.delivery_whse_code = ir_sr_line.move_from_whse_code1 ) ) THEN
--
      -- 倉庫重複チェックNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_rep_whse2,
                              gv_tkn_ng_item_code, ir_sr_line.item_code,
                              gv_tkn_ng_base_code,ir_sr_line.base_code,
                              gv_tkn_ng_ship_to_code,ir_sr_line.ship_to_code,
                              gv_tkn_s_date_act,
                              TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD'),
                              gv_tkn_e_date_act,
                              TO_CHAR(ir_sr_line.end_date_active, 'YYYY/MM/DD'),
                              gv_tkn_ng_whse_code, ir_sr_line.delivery_whse_code,
                              gv_tkn_ng_whse1, ir_sr_line.move_from_whse_code1,
                              gv_tkn_ng_whse2, ir_sr_line.move_from_whse_code2,
                              gv_tkn_ng_vendor_site_code1, ir_sr_line.vendor_site_code1,
                              gv_tkn_object1, gv_colmun1,
                              gv_tkn_object2, gv_colmun2 );
--
      RAISE check_data_expt;
--
    END IF;
--
--
    -- 移動元倉庫2が設定されている場合且つ、移動元倉庫1と同じ場合
    IF ( ( ir_sr_line.move_from_whse_code1 IS NOT NULL )
      AND ( ir_sr_line.move_from_whse_code2 IS NOT NULL )
      AND ( ir_sr_line.move_from_whse_code1 = ir_sr_line.move_from_whse_code2 ) ) THEN
--
      -- 倉庫重複チェックNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_rep_whse2,
                              gv_tkn_ng_item_code, ir_sr_line.item_code,
                              gv_tkn_ng_base_code,ir_sr_line.base_code,
                              gv_tkn_ng_ship_to_code,ir_sr_line.ship_to_code,
                              gv_tkn_s_date_act,
                              TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD'),
                              gv_tkn_e_date_act,
                              TO_CHAR(ir_sr_line.end_date_active, 'YYYY/MM/DD'),
                              gv_tkn_ng_whse_code, ir_sr_line.delivery_whse_code,
                              gv_tkn_ng_whse1, ir_sr_line.move_from_whse_code1,
                              gv_tkn_ng_whse2, ir_sr_line.move_from_whse_code2,
                              gv_tkn_ng_vendor_site_code1, ir_sr_line.vendor_site_code1,
                              gv_tkn_object1, gv_colmun2,
                              gv_tkn_object2, gv_colmun3 );
--
      RAISE check_data_expt;
--
    END IF;
--
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データチェック処理エラー ***
    WHEN check_data_expt THEN
      ir_sr_line.row_level_status := gn_data_status_warn;
      gn_data_status := gn_data_status_warn;
      ov_retcode := gv_status_warn;
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
  END check_whse_data2;
-- 2008/10/29 v1.4 T.Yoshimoto Add End 統合#251
--
  /**********************************************************************************
   * Function Name    : modify_end_date
   * Description      : 適用終了日編集(B-7)ファンクション
   ***********************************************************************************/
  FUNCTION modify_end_date(
    ir_sr_line_rec            IN sr_line_rec,       -- 1.レコード
    in_insert_user_id         IN NUMBER,            -- 2.ユーザーID  
    id_insert_date            IN DATE,              -- 3.更新日
    in_insert_login_id        IN NUMBER,            -- 4.ログインID
    in_insert_request_id      IN NUMBER,            -- 5.要求ID
    in_insert_program_appl_id IN NUMBER,            -- 6.コンカレント・プログラムのアプリケーションID
    in_insert_program_id      IN NUMBER             -- 7.コンカレント・プログラムID
  )
    RETURN DATE
    IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'modify_end_date'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_sr_id      NUMBER;
    ld_end_date   DATE ;
    ld_start_date DATE ;
--
--
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
--
  BEGIN
--
    -- ***************************************
    -- ***      処理ロジックの記述         ***
    -- ***************************************
--
--
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
    --【管理タイプ2：品目在庫補充元管理】
    IF ((ir_sr_line_rec.base_code    = gv_dummy_base_code)         -- 拠点コードがダミーコード(AAAA)
    AND (ir_sr_line_rec.ship_to_code = gv_no_ship_to_code)) THEN   -- 配送先がダミーコード(000000000)
      BEGIN
        -- 前歴の物流構成アドオンIDを取得
        SELECT xsr.sourcing_rules_id   sourcing_rules_id -- 物流構成アドオンID
        INTO   ln_sr_id
        FROM   xxcmn_sourcing_rules    xsr               -- 物流構成アドオンマスタ
             ,(SELECT xsr.item_code              item_code                       -- 品目コード
                     ,xsr.base_code              base_code                       -- 拠点コード
                     ,xsr.ship_to_code           ship_to_code                    -- 配送先コード
                     ,xsr.delivery_whse_code     delivery_whse_code              -- 出庫倉庫コード
                     ,MAX(xsr.start_date_active) start_date                      -- 適用開始日
               FROM   xxcmn_sourcing_rules       xsr                             -- 物流構成アドオンマスタ
               WHERE  xsr.item_code          = ir_sr_line_rec.item_code          -- 品目コード
               AND    xsr.base_code          = ir_sr_line_rec.base_code          -- 拠点コード
               AND    xsr.ship_to_code       = ir_sr_line_rec.ship_to_code       -- 配送先コード
               AND    xsr.delivery_whse_code = ir_sr_line_rec.delivery_whse_code -- 出庫倉庫コード
               AND    xsr.start_date_active  < ir_sr_line_rec.start_date_active  -- 適用開始日
               GROUP BY xsr.item_code
                       ,xsr.base_code
                       ,xsr.ship_to_code
                       ,xsr.delivery_whse_code
              )                        max_data          -- 自レコードより前歴の中で最新のレコード
        WHERE  max_data.item_code          = xsr.item_code          -- 品目コード
        AND    max_data.base_code          = xsr.base_code          -- 拠点コード
        AND    max_data.ship_to_code       = xsr.ship_to_code       -- 配送先コード
        AND    max_data.delivery_whse_code = xsr.delivery_whse_code -- 出庫倉庫コード
        AND    max_data.start_date         = xsr.start_date_active  -- 適用開始日
        AND    ROWNUM = 1
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END ;
--
      -- 後歴の適用開始日を取得
      SELECT MIN(xsr.start_date_active) start_date -- 自レコードより高歴の中で古いレコード
      INTO   ld_start_date
      FROM   xxcmn_sourcing_rules       xsr        -- 物流構成アドオンマスタ
      WHERE  xsr.item_code          = ir_sr_line_rec.item_code          -- 品目コード
      AND    xsr.base_code          = ir_sr_line_rec.base_code          -- 拠点コード
      AND    xsr.ship_to_code       = ir_sr_line_rec.ship_to_code       -- 配送先コード
      AND    xsr.delivery_whse_code = ir_sr_line_rec.delivery_whse_code -- 出庫倉庫コード
      AND    xsr.start_date_active  > ir_sr_line_rec.start_date_active  -- 適用開始日
      ;
--
    --【管理タイプ1：品目出荷元倉庫・計画商品管理】
    ELSE
-- 2008/11/17 H.Itou Add End
      BEGIN
        -- 前歴の物流構成アドオンIDを取得
        SELECT xsr.sourcing_rules_id   sourcing_rules_id -- 物流構成アドオンID
        INTO   ln_sr_id
        FROM   xxcmn_sourcing_rules    xsr               -- 物流構成アドオンマスタ
             ,(SELECT xsr.item_code              item_code                      -- 品目コード
                     ,xsr.base_code              base_code                      -- 拠点コード
                     ,xsr.ship_to_code           ship_to_code                   -- 配送先コード
                     ,MAX(xsr.start_date_active) start_date                     -- 適用開始日
               FROM   xxcmn_sourcing_rules       xsr                            -- 物流構成アドオンマスタ
               WHERE  xsr.item_code          = ir_sr_line_rec.item_code         -- 品目コード
               AND    xsr.base_code          = ir_sr_line_rec.base_code         -- 拠点コード
               AND    xsr.ship_to_code       = ir_sr_line_rec.ship_to_code      -- 配送先コード
               AND    xsr.start_date_active  < ir_sr_line_rec.start_date_active -- 適用開始日
               GROUP BY xsr.item_code
                       ,xsr.base_code
                       ,xsr.ship_to_code
              )                        max_data          -- 自レコードより前歴の中で最新のレコード
        WHERE  max_data.item_code          = xsr.item_code          -- 品目コード
        AND    max_data.base_code          = xsr.base_code          -- 拠点コード
        AND    max_data.ship_to_code       = xsr.ship_to_code       -- 配送先コード
        AND    max_data.start_date         = xsr.start_date_active  -- 適用開始日
        AND    ROWNUM = 1
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        NULL;
      END ;
--
      -- 後歴の適用開始日を取得
      SELECT MIN(xsr.start_date_active) start_date -- 自レコードより高歴の中で古いレコード
      INTO   ld_start_date
      FROM   xxcmn_sourcing_rules       xsr        -- 物流構成アドオンマスタ
      WHERE  xsr.item_code          = ir_sr_line_rec.item_code         -- 品目コード
      AND    xsr.base_code          = ir_sr_line_rec.base_code         -- 拠点コード
      AND    xsr.ship_to_code       = ir_sr_line_rec.ship_to_code      -- 配送先コード
      AND    xsr.start_date_active  > ir_sr_line_rec.start_date_active -- 適用開始日
      ;
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
    END IF;
-- 2008/11/17 H.Itou Add End
--
    -- 適用終了日の編集
    -- 登録対象データに適用開始日が存在している場合
    IF(ir_sr_line_rec.start_date_active IS NOT NULL)THEN
    -- 前歴適用終了日を、登録対象データの適用開始日を元に設定する
      ld_end_date := ir_sr_line_rec.start_date_active -1;
    END IF;
    -- 登録対象データの適用終了日を取得する
    IF(ld_start_date IS NULL) THEN
      -- 最大適用日を設定する
      ld_start_date:= FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD');
    ELSE
      -- 取得した後歴の適用開始日を元に設定する
      ld_start_date := ld_start_date-1;
    END IF;
--
    -- 前歴適用終了日の更新（前歴が取得できなかった場合不要）
    IF(ln_sr_id IS NOT NULL) THEN
--
      UPDATE xxcmn_sourcing_rules xsr -- 物流構成アドオンマスタ
      SET xsr.end_date_active         = ld_end_date
          ,xsr.last_updated_by        = in_insert_user_id
          ,xsr.last_update_date       = id_insert_date
          ,xsr.last_update_login      = in_insert_login_id
          ,xsr.request_id             = in_insert_request_id
          ,xsr.program_application_id = in_insert_program_appl_id
          ,xsr.program_id             = in_insert_program_id
          ,xsr.program_update_date    = id_insert_date          
      WHERE xsr.sourcing_rules_id = ln_sr_id;
--
    END IF;
--
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
--
    RETURN ld_start_date;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  固定部 END   ############################################
--
  END modify_end_date;
--
  /**********************************************************************************
   * Procedure Name   : delete_sourcing_rules
   * Description      : 物流構成アドオンマスタ削除(B-6)プロシージャ
   ***********************************************************************************/
  PROCEDURE delete_sourcing_rules(
    in_sr_rules_id    IN         NUMBER,   -- 物流構成アドオンID
    ov_errbuf         OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_sourcing_rules'; -- プログラム名
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
      DELETE xxcmn_sourcing_rules xsr                -- 物流構成アドオンマスタ
      WHERE  xsr.sourcing_rules_id = in_sr_rules_id  -- 物流構成アドオンID
      ;
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
  END delete_sourcing_rules;
--
  /**********************************************************************************
   * Procedure Name   : set_table_data
   * Description      : 登録対象レコード編集(B-5)プロシージャ
   ***********************************************************************************/
  PROCEDURE set_table_data(
    ir_sr_line    IN OUT NOCOPY sr_line_rec,  -- 1.レコード
    ov_errbuf     OUT NOCOPY VARCHAR2,        --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY  VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY  VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_table_data'; -- プログラム名
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
--
    -- 物理構成アドオンIDをシーケンスより取得
    SELECT xxcmn_sourcing_rules_s1.NEXTVAL 
    INTO ir_sr_line.sourcing_rules_id
    FROM dual;
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
  END set_table_data;
--
  /**********************************************************************************
   * Procedure Name   : check_data
   * Description      : 項目チェック(B-2)(B-3)(B-4)プロシージャ
   ***********************************************************************************/
  PROCEDURE check_data(
    ir_sr_line    IN OUT NOCOPY sr_line_rec,  -- 1.レコード
    ov_errbuf     OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY  VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_data'; -- プログラム名
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
    cv_obsolete_handling CONSTANT VARCHAR2(1) := '0';         -- 廃止区分（取扱中）
    cv_customer_base     CONSTANT VARCHAR2(1) := '1';         -- 顧客区分（拠点）
    cv_customer_supply   CONSTANT VARCHAR2(2) := '11';        -- 顧客区分（支給先）
    cv_z_item_code       CONSTANT VARCHAR2(7) := 'ZZZZZZZ';   -- 品目コード（ZZZZZZZ）
    cv_no_base_code      CONSTANT VARCHAR2(4) := '0000';      -- 拠点コード（指定なし）
    cv_no_ship_to_code   CONSTANT VARCHAR2(9) := '000000000'; -- 配送先コード（指定なし）
--
    -- *** ローカル変数 ***
    ln_count NUMBER := 0;
    ld_max_date DATE ;
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
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
    -- ==========================================
    --  項目チェック(B-2) 入力不可項目チェック
    -- ==========================================
    --【管理タイプ2：品目在庫補充元管理】
    IF ((ir_sr_line.base_code    = gv_dummy_base_code)         -- 拠点コードがダミーコード(AAAA)
    AND (ir_sr_line.ship_to_code = gv_no_ship_to_code)) THEN   -- 配送先がダミーコード(000000000)
      -- 計画商品フラグをYESは不可
      IF (ir_sr_line.plan_item_flag = 1) THEN
        ir_sr_line.message := xxcmn_common_pkg.get_msg(
                                gv_msg_kbn                                       -- アプリケーション：XXCMN
                               ,gv_msg_ng_plan_item_flg                          -- メッセージ：APP-XXCMN-10129  計画商品フラグ存在NG
                               ,gv_tkn_ng_item_code    ,ir_sr_line.item_code     -- トークン：NG_ITEM_CODE
                               ,gv_tkn_ng_base_code    ,ir_sr_line.base_code     -- トークン：NG_BASE_CODE
                               ,gv_tkn_ng_ship_to_code ,ir_sr_line.ship_to_code  -- トークン：NG_SHIP_TO_CODE
                               ,gv_tkn_s_date_act      ,TO_CHAR(ir_sr_line.start_date_active,'YYYY/MM/DD') -- トークン：S_DATE_ACT
                               );
        RAISE check_data_expt;
      END IF;
--
    --【管理タイプ1：品目出荷元倉庫・計画商品管理】
    ELSE
      -- 移動元倉庫1は入力不可
      IF (ir_sr_line.move_from_whse_code1 IS NOT NULL) THEN
        ir_sr_line.message := xxcmn_common_pkg.get_msg(
                                gv_msg_kbn                                       -- アプリケーション：XXCMN
                               ,gv_msg_xxcmn_10606                               -- メッセージ：APP-XXCMN-10606  指定不可エラー
                               ,gv_tkn_ng_base_code    ,ir_sr_line.base_code     -- トークン：NG_BASE_CODE
                               ,gv_tkn_ng_ship_to_code ,ir_sr_line.ship_to_code  -- トークン：NG_SHIP_TO_CODE
                               ,gv_tkn_item            ,gv_colmun2               -- トークン：ITEM = 移動元倉庫1
                               );
        RAISE check_data_expt;
      END IF;
--
      -- 移動元倉庫2は入力不可
      IF (ir_sr_line.move_from_whse_code2 IS NOT NULL) THEN
        ir_sr_line.message := xxcmn_common_pkg.get_msg(
                                gv_msg_kbn                                       -- アプリケーション：XXCMN
                               ,gv_msg_xxcmn_10606                               -- メッセージ：APP-XXCMN-10606  指定不可エラー
                               ,gv_tkn_ng_base_code    ,ir_sr_line.base_code     -- トークン：NG_BASE_CODE
                               ,gv_tkn_ng_ship_to_code ,ir_sr_line.ship_to_code  -- トークン：NG_SHIP_TO_CODE
                               ,gv_tkn_item            ,gv_colmun3               -- トークン：ITEM = 移動元倉庫2
                               );
        RAISE check_data_expt;
      END IF;
--
      -- 仕入先サイト1は入力不可
      IF (ir_sr_line.vendor_site_code1 IS NOT NULL) THEN
        ir_sr_line.message := xxcmn_common_pkg.get_msg(
                                gv_msg_kbn                                       -- アプリケーション：XXCMN
                               ,gv_msg_xxcmn_10606                               -- メッセージ：APP-XXCMN-10606  指定不可エラー
                               ,gv_tkn_ng_base_code    ,ir_sr_line.base_code     -- トークン：NG_BASE_CODE
                               ,gv_tkn_ng_ship_to_code ,ir_sr_line.ship_to_code  -- トークン：NG_SHIP_TO_CODE
                               ,gv_tkn_item            ,gv_colmun4               -- トークン：ITEM = 仕入先サイト1
                               );
        RAISE check_data_expt;
      END IF;
--
      -- 仕入先サイト2は入力不可
      IF (ir_sr_line.vendor_site_code2 IS NOT NULL) THEN
        ir_sr_line.message := xxcmn_common_pkg.get_msg(
                                gv_msg_kbn                                       -- アプリケーション：XXCMN
                               ,gv_msg_xxcmn_10606                               -- メッセージ：APP-XXCMN-10606  指定不可エラー
                               ,gv_tkn_ng_base_code    ,ir_sr_line.base_code     -- トークン：NG_BASE_CODE
                               ,gv_tkn_ng_ship_to_code ,ir_sr_line.ship_to_code  -- トークン：NG_SHIP_TO_CODE
                               ,gv_tkn_item            ,gv_colmun5               -- トークン：ITEM = 仕入先サイト2
                               );
        RAISE check_data_expt;
      END IF;
    END IF;
-- 2008/11/17 H.Itou Add End
    -- =======================================
    --  項目チェック(B-2) マスタ存在チェック
    -- =======================================
    -- ダミーコードでない時、品目存在チェック
    IF (ir_sr_line.item_code <> cv_z_item_code) THEN
      -- 品目存在チェック
      SELECT COUNT(ximv.item_id)
      INTO ln_count
      FROM xxcmn_item_mst2_v ximv    -- OPM品目情報VIEW
      WHERE ximv.item_no = ir_sr_line.item_code
-- 2010/02/12 M.Miyagawa Mod Start
--        AND ximv.obsolete_date IS NULL    --廃止日
        AND ximv.inactive_ind   <> '1'    --無効フラグ
        AND ximv.obsolete_class <> '1'    --廃止区分
-- 2010/02/12 M.Miyagawa Mod End
        AND ROWNUM = 1;
--
      IF (ln_count = 0) THEN
      -- 品目存在チェックNG
        ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_item,
                                gv_tkn_ng_item_code, ir_sr_line.item_code);
        RAISE check_data_expt;
      END IF;
--
      -- 品目適用日付チェック
      SELECT COUNT(ximv.item_id)
      INTO ln_count
      FROM xxcmn_item_mst_v ximv    -- OPM品目情報VIEW
      WHERE ximv.item_no = ir_sr_line.item_code
        AND ROWNUM = 1;
--
      IF (ln_count = 0) THEN
      -- 品目適用日付チェックNG
        ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_d_item,
                                gv_tkn_ng_item_code, ir_sr_line.item_code);
        RAISE check_data_expt;
      END IF;
    END IF;
--
    IF (ir_sr_line.base_code <> cv_no_base_code) THEN
      --拠点存在チェック
      SELECT COUNT(xcav.party_id)
      INTO ln_count
      FROM xxcmn_cust_accounts2_v xcav        -- 顧客情報VIEW
      WHERE xcav.party_number = ir_sr_line.base_code
        AND xcav.customer_class_code = cv_customer_base
-- 2009/10/02 ADD START
        AND xcav.account_status = 'A' -- 有効
-- 2009/10/02 ADD END
        AND ROWNUM = 1;
  --
      IF (ln_count = 0) THEN
      -- 拠点存在チェックNG
        ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_base,
                                gv_tkn_ng_base_code, ir_sr_line.base_code);
        RAISE check_data_expt;
      END IF;
  --
      -- 拠点適用日付チェック
      SELECT COUNT(xcav.party_id)
      INTO ln_count
      FROM xxcmn_cust_accounts_v xcav        -- 顧客情報VIEW
      WHERE xcav.party_number = ir_sr_line.base_code
        AND xcav.customer_class_code = cv_customer_base
        AND ROWNUM = 1;
  --
      IF (ln_count = 0) THEN
      -- 拠点適用日付チェックNG
        ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_d_base,
                                gv_tkn_ng_base_code, ir_sr_line.base_code);
        RAISE check_data_expt;
      END IF;
    END IF;
--
    IF (ir_sr_line.ship_to_code <> cv_no_ship_to_code) THEN
      -- 配送先存在チェック
      SELECT COUNT(xpsv.party_id)
      INTO ln_count
      FROM xxcmn_party_sites2_v xpsv     -- パーティサイトマスタVIEW
          ,xxcmn_cust_accounts2_v xcav   -- 顧客マスタVIEW
      WHERE xpsv.ship_to_no = ir_sr_line.ship_to_code
        AND xpsv.party_id = xcav.party_id
        AND xcav.customer_class_code <>cv_customer_supply
        AND ROWNUM = 1;
  --
      IF (ln_count = 0) THEN
      -- 配送先存在チェック
        SELECT COUNT(xvv.vendor_id)
        INTO ln_count
        FROM xxcmn_vendors2_v xvv    -- 仕入先VIEW
        WHERE xvv.segment1 = ir_sr_line.ship_to_code
          AND xvv.vendor_div = cv_customer_supply
          AND ROWNUM = 1;
  --
        IF (ln_count = 0) THEN
          -- 配送先存在チェックNG
          ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_ship_to,
                                  gv_tkn_ng_ship_to_code, ir_sr_line.ship_to_code);
          RAISE check_data_expt;
        END IF;
      END IF;
--
      -- 配送先適用日チェック
      SELECT COUNT(xpsv.party_id)
      INTO ln_count
      FROM xxcmn_party_sites_v xpsv     -- パーティサイトマスタVIEW
          ,xxcmn_cust_accounts_v xcav   -- 顧客マスタVIEW
      WHERE xpsv.ship_to_no = ir_sr_line.ship_to_code
        AND xpsv.party_id = xcav.party_id
        AND ROWNUM = 1;
  --
      IF (ln_count = 0) THEN
      -- 配送先適用日チェック
        SELECT COUNT(xvv.vendor_id)
        INTO ln_count
        FROM xxcmn_vendors_v xvv    -- 仕入先VIEW
        WHERE xvv.segment1 = ir_sr_line.ship_to_code
          AND xvv.vendor_div = cv_customer_supply
          AND ROWNUM = 1;
  --
        IF (ln_count = 0) THEN
        -- 配送先適用日チェックNG
          ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_d_ship_to,
                                  gv_tkn_ng_ship_to_code, ir_sr_line.ship_to_code);
          RAISE check_data_expt;
        END IF;
      END IF;
    END IF;
--
    --出庫倉庫存在チェック
    SELECT COUNT(xil.mtl_organization_id)
    INTO ln_count
    FROM xxcmn_item_locations_v xil -- 倉庫マスタVIEW
    WHERE xil.segment1 = ir_sr_line.delivery_whse_code
      AND ROWNUM = 1;
--
    IF (ln_count = 0) THEN
    -- 出庫倉庫存在チェックNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_whse,
                              gv_tkn_ng_whse_code, ir_sr_line.delivery_whse_code);
      RAISE check_data_expt;
    END IF;
--
    -- 移動元倉庫1存在チェック
    IF (ir_sr_line.move_from_whse_code1 IS NOT NULL)THEN
      SELECT COUNT(xil.mtl_organization_id)
      INTO ln_count
      FROM xxcmn_item_locations_v xil -- 倉庫マスタVIEW
      WHERE xil.segment1 = ir_sr_line.move_from_whse_code1
        AND ROWNUM = 1;
--
      IF (ln_count = 0) THEN
      -- 移動元倉庫1存在チェックNG
        ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn,gv_msg_ng_whse1,
                                gv_tkn_ng_whse_code1, ir_sr_line.move_from_whse_code1);
        RAISE check_data_expt;
      END IF;
      -- 移動元倉庫未入力チェック
    ELSIF (ir_sr_line.move_from_whse_code2 IS NOT NULL) THEN
      -- 移動元倉庫未入力NG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_input_whse1,
                              gv_tkn_ng_item_code, ir_sr_line.item_code,
                              gv_tkn_ng_base_code, ir_sr_line.base_code,
                              gv_tkn_ng_ship_to_code, ir_sr_line.ship_to_code,
                              gv_tkn_s_date_act,
                              TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD'));
        RAISE check_data_expt;
    END IF;
--
    -- 移動元倉庫2存在チェック
    IF (ir_sr_line.move_from_whse_code2 IS NOT NULL)THEN
      SELECT COUNT(xil.mtl_organization_id)
      INTO ln_count
      FROM xxcmn_item_locations_v xil -- 倉庫マスタVIEW
      WHERE xil.segment1 = ir_sr_line.move_from_whse_code2
        AND ROWNUM = 1;
--
      IF (ln_count = 0) THEN
      -- 移動元倉庫2存在チェックNG
        ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_whse2,
                                gv_tkn_ng_whse_code2, ir_sr_line.move_from_whse_code2);
        RAISE check_data_expt;
      END IF;
    END IF;
--
    -- 仕入サイト1存在チェック
    IF (ir_sr_line.vendor_site_code1 IS NOT NULL)THEN
      SELECT COUNT(xvv.vendor_id)
      INTO   ln_count
-- 2008/11/11 H.Itou Mod Start
--      FROM xxcmn_vendors_v xvv    -- 仕入先VIEW
--      WHERE xvv.segment1 = ir_sr_line.vendor_site_code1
      FROM   xxcmn_vendor_sites_v xvv -- 仕入先サイトVIEW
      WHERE  xvv.vendor_site_code = ir_sr_line.vendor_site_code1
-- 2008/11/11 H.Itou Mod End
      AND    ROWNUM = 1;
--
      IF (ln_count = 0) THEN
      -- 仕入サイト1存在チェックNG
        ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_vendor_site1,
                                gv_tkn_ng_vendor_site_code1, ir_sr_line.vendor_site_code1);
        RAISE check_data_expt;
      END IF;
    END IF;
--
    -- 仕入サイト2存在チェック
    IF (ir_sr_line.vendor_site_code2 IS NOT NULL)THEN
      SELECT COUNT(xvv.vendor_id)
      INTO   ln_count
-- 2008/11/11 H.Itou Mod Start
--      FROM xxcmn_vendors_v xvv    -- 仕入先VIEW
--      WHERE xvv.segment1 = ir_sr_line.vendor_site_code2
      FROM   xxcmn_vendor_sites_v xvv -- 仕入先サイトVIEW
      WHERE  xvv.vendor_site_code = ir_sr_line.vendor_site_code2
-- 2008/11/11 H.Itou Mod End
      AND    ROWNUM = 1;
--
      IF (ln_count = 0) THEN
      -- 仕入サイト2存在チェックNG
        ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_vendor_site2,
                                gv_tkn_ng_vendor_site_code2, ir_sr_line.vendor_site_code2);
        RAISE check_data_expt;
      END IF;
    END IF;
--
    -- 計画商品フラグ存在チェック
    IF (ir_sr_line.plan_item_flag = 1)
        AND ((ir_sr_line.item_code = cv_z_item_code) 
        OR ( (ir_sr_line.base_code = cv_no_base_code) 
          OR (ir_sr_line.ship_to_code <> cv_no_ship_to_code))) THEN
          -- 計画商品フラグ存在チェックNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_plan_item_flg,
                              gv_tkn_ng_item_code, ir_sr_line.item_code,
                              gv_tkn_ng_base_code, ir_sr_line.base_code,
                              gv_tkn_ng_ship_to_code, ir_sr_line.ship_to_code,
                              gv_tkn_s_date_act,
                              TO_CHAR(ir_sr_line.start_date_active,'YYYY/MM/DD'));
      RAISE check_data_expt;
    END IF;
--
    ld_max_date := FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD');
    -- 適用日付チェック 
    IF (ir_sr_line.start_date_active > NVL(ir_sr_line.end_date_active, ld_max_date)) THEN
      -- 適用日付チェックNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_date_act,
                              gv_tkn_ng_item_code, ir_sr_line.item_code,
                              gv_tkn_ng_base_code, ir_sr_line.base_code,
                              gv_tkn_ng_ship_to_code, ir_sr_line.ship_to_code,
                              gv_tkn_s_date_act, 
                              TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD'),
                              gv_tkn_e_date_act,
                              TO_CHAR(ir_sr_line.end_date_active, 'YYYY/MM/DD'));
      RAISE check_data_expt;
    END IF;
--
-- 2008/11/17 H.Itou Mod Start 統合テスト指摘491
--    -- 主キー重複チェック
--    SELECT COUNT(xsli.item_code) cnt
--    INTO   ln_count
--    FROM   xxcmn_sr_lines_if     xsli                              -- 物流構成アドオンインタフェース
--    WHERE  xsli.item_code          = ir_sr_line.item_code          -- 品目コード
--    AND    xsli.base_code          = ir_sr_line.base_code          -- 拠点コード
--    AND    xsli.ship_to_code       = ir_sr_line.ship_to_code       -- 配送先コード
--    AND    xsli.delivery_whse_code = ir_sr_line.delivery_whse_code -- 出庫倉庫コード
--    AND    xsli.start_date_active  = ir_sr_line.start_date_active  -- 適用開始日
--    ;
---- 
--    IF (ln_count > 1 ) THEN
--      -- 主キー重複チェックNG
--      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_rep_key,
--                              gv_tkn_ng_item_code, ir_sr_line.item_code,
--                              gv_tkn_ng_base_code, ir_sr_line.base_code,
--                              gv_tkn_ng_ship_to_code, ir_sr_line.ship_to_code,
--                              gv_tkn_s_date_act,
--                              TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD'));
--      RAISE check_data_expt;
----
--    END IF ;
--
    -- ======================================================
    --  重複チェック(B-3)【管理タイプ2：品目在庫補充元管理】
    -- ======================================================
    IF ((ir_sr_line.base_code    = gv_dummy_base_code)         -- 拠点コードがダミーコード(AAAA)
    AND (ir_sr_line.ship_to_code = gv_no_ship_to_code)) THEN   -- 配送先がダミーコード(000000000)
      -- -----------------------------------------------------------------------------------------
      -- 重複チェック(※キー：品目コード・拠点コード・配送先コード・出庫倉庫コード・適用開始日)
      -- -----------------------------------------------------------------------------------------
      SELECT COUNT(1) cnt
      INTO   ln_count
      FROM   xxcmn_sr_lines_if     xsli                              -- 物流構成アドオンインタフェース
      WHERE  xsli.item_code          = ir_sr_line.item_code          -- 品目コード
      AND    xsli.base_code          = ir_sr_line.base_code          -- 拠点コード
      AND    xsli.ship_to_code       = ir_sr_line.ship_to_code       -- 配送先コード
      AND    xsli.delivery_whse_code = ir_sr_line.delivery_whse_code -- 出庫倉庫コード
      AND    xsli.start_date_active  = ir_sr_line.start_date_active  -- 適用開始日
      ;
--
      IF (ln_count > 1 ) THEN
        ir_sr_line.message := xxcmn_common_pkg.get_msg(
                                gv_msg_kbn                                             -- アプリケーション：XXCMN
                               ,gv_msg_xxcmn_10608                                     -- メッセージ：APP-XXCMN-10608 主キー重複NG(管理タイプ2用)
                               ,gv_tkn_ng_item_code    ,ir_sr_line.item_code           -- トークン：NG_ITEM_CODE
                               ,gv_tkn_ng_base_code    ,ir_sr_line.base_code           -- トークン：NG_BASE_CODE
                               ,gv_tkn_ng_ship_to_code ,ir_sr_line.ship_to_code        -- トークン：NG_SHIP_TO_CODE
                               ,gv_tkn_ng_whse_code    ,ir_sr_line.delivery_whse_code  -- トークン：NG_WHSE_CODE
                               ,gv_tkn_s_date_act      ,TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD') -- トークン：S_DATE_ACT
                               );
        RAISE check_data_expt;
--
      END IF ;
--
      ---------------------------------------------------------------------------------------------------
      -- 移動元保管場所チェック
      --   キーがIF・マスタにある場合(※キー：品目コード・拠点コード・配送先コード・移動元保管倉庫コード1・適用開始日)
      --   移動元保管場所コード2・仕入先サイトコード1・仕入先サイトコード2すべてが同一でなければエラー
      ---------------------------------------------------------------------------------------------------
      SELECT COUNT(1)  cnt
      INTO   ln_count
      FROM  ( --------------------------
              -- IF重複レコード取得
              --------------------------
              SELECT xsli.move_from_whse_code2 move_from_whse_code2              -- 移動元保管倉庫コード2
                    ,xsli.vendor_site_code1    vendor_site_code1                 -- 仕入先サイトコード1
                    ,xsli.vendor_site_code2    vendor_site_code2                 -- 仕入先サイトコード2
              FROM   xxcmn_sr_lines_if         xsli                              -- 物流構成アドオンインタフェース
              WHERE  xsli.item_code            = ir_sr_line.item_code            -- 品目コード           (キー項目)
              AND    xsli.base_code            = ir_sr_line.base_code            -- 拠点コード           (キー項目)
              AND    xsli.ship_to_code         = ir_sr_line.ship_to_code         -- 配送先コード         (キー項目)
              AND    xsli.move_from_whse_code1 = ir_sr_line.move_from_whse_code1 -- 移動元保管倉庫コード1(キー項目)
              AND    xsli.start_date_active    = ir_sr_line.start_date_active    -- 適用開始日           (キー項目)
--
              --------------------------
              -- マスタ重複レコード取得
              --------------------------
              UNION ALL
              SELECT xsr.move_from_whse_code2 move_from_whse_code2              -- 移動元保管倉庫コード2
                    ,xsr.vendor_site_code1    vendor_site_code1                 -- 仕入先サイトコード1
                    ,xsr.vendor_site_code2    vendor_site_code2                 -- 仕入先サイトコード2
              FROM   xxcmn_sourcing_rules      xsr                              -- 物流構成アドオンマスタ
              WHERE  xsr.item_code            = ir_sr_line.item_code            -- 品目コード           (キー項目)
              AND    xsr.base_code            = ir_sr_line.base_code            -- 拠点コード           (キー項目)
              AND    xsr.ship_to_code         = ir_sr_line.ship_to_code         -- 配送先コード         (キー項目)
              AND    xsr.move_from_whse_code1 = ir_sr_line.move_from_whse_code1 -- 移動元保管倉庫コード1(キー項目)
              AND    xsr.start_date_active    = ir_sr_line.start_date_active    -- 適用開始日           (キー項目)
              AND    NOT EXISTS(                                                -- 洗い替えするマスタの場合は削除するので比較対象外
                       SELECT 1
                       FROM   xxcmn_sourcing_rules xsr1
                       WHERE  xsr1.sourcing_rules_id = xsr.sourcing_rules_id
                       AND    xsr1.sourcing_rules_id = ir_sr_line.sourcing_rules_id)
            )  subsql
      WHERE  ROWNUM = 1
      AND   (NVL(subsql.move_from_whse_code2, '*') <> NVL(ir_sr_line.move_from_whse_code2, '*') -- 移動元保管倉庫コード2
        OR   NVL(subsql.vendor_site_code1,    '*') <> NVL(ir_sr_line.vendor_site_code1,    '*') -- 仕入先サイトコード1
        OR   NVL(subsql.vendor_site_code2,    '*') <> NVL(ir_sr_line.vendor_site_code2,    '*'))-- 仕入先サイトコード2
      ;
--
      IF (ln_count = 1 ) THEN
        ir_sr_line.message := xxcmn_common_pkg.get_msg(
                                gv_msg_kbn                                               -- アプリケーション：XXCMN
                               ,gv_msg_xxcmn_10607                                       -- メッセージ：APP-XXCMN-10607 移動元保管場所キーチェックエラー
                               ,gv_tkn_ng_item_code    ,ir_sr_line.item_code             -- トークン：NG_ITEM_CODE
                               ,gv_tkn_ng_base_code    ,ir_sr_line.base_code             -- トークン：NG_BASE_CODE
                               ,gv_tkn_ng_ship_to_code ,ir_sr_line.ship_to_code          -- トークン：NG_SHIP_TO_CODE
                               ,gv_tkn_ng_whse_code    ,ir_sr_line.move_from_whse_code1  -- トークン：NG_WHSE_CODE
                               ,gv_tkn_s_date_act      ,TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD') -- トークン：S_DATE_ACT
                               );
        RAISE check_data_expt;
--
      END IF ;
--
    -- ================================================================
    --  重複チェック(B-3)【管理タイプ1：品目出荷元倉庫・計画商品管理】
    -- ================================================================
    ELSE
      -------------------------------------------------------------------------------
      -- 重複チェック(※キー：品目コード・拠点コード・配送先コード・適用開始日)
      -------------------------------------------------------------------------------
      SELECT COUNT(1) cnt
      INTO   ln_count
      FROM   xxcmn_sr_lines_if     xsli                              -- 物流構成アドオンインタフェース
      WHERE  xsli.item_code          = ir_sr_line.item_code          -- 品目コード
      AND    xsli.base_code          = ir_sr_line.base_code          -- 拠点コード
      AND    xsli.ship_to_code       = ir_sr_line.ship_to_code       -- 配送先コード
      AND    xsli.start_date_active  = ir_sr_line.start_date_active  -- 適用開始日
      ;
--
      IF (ln_count > 1 ) THEN
        ir_sr_line.message := xxcmn_common_pkg.get_msg(
                                gv_msg_kbn                                       -- アプリケーション：XXCMN
                               ,gv_msg_rep_key                                   -- メッセージ：APP-XXCMN-10055 主キー重複NG
                               ,gv_tkn_ng_item_code    ,ir_sr_line.item_code     -- トークン：NG_ITEM_CODE
                               ,gv_tkn_ng_base_code    ,ir_sr_line.base_code     -- トークン：NG_BASE_CODE
                               ,gv_tkn_ng_ship_to_code ,ir_sr_line.ship_to_code  -- トークン：NG_SHIP_TO_CODE
                               ,gv_tkn_s_date_act      ,TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD') -- トークン：S_DATE_ACT
                               );
        RAISE check_data_expt;
--
      END IF;
    END IF;
-- 2008/11/17 H.Itou Mod End
--
    -- =======================================
    --  拠点／配送先チェック(B-4)
    -- =======================================
    IF ((ir_sr_line.base_code = cv_no_base_code)
        AND (ir_sr_line.ship_to_code = cv_no_ship_to_code))
      OR
        ((ir_sr_line.base_code <> cv_no_base_code)
        AND (ir_sr_line.ship_to_code <> cv_no_ship_to_code)) THEN
          -- 拠点／配送先チェックNG
      ir_sr_line.message := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_base_ship_to,
                              gv_tkn_ng_item_code, ir_sr_line.item_code,
                              gv_tkn_ng_base_code, ir_sr_line.base_code,
                              gv_tkn_ng_ship_to_code, ir_sr_line.ship_to_code,
                              gv_tkn_s_date_act,
                              TO_CHAR(ir_sr_line.start_date_active, 'YYYY/MM/DD'));
      RAISE check_data_expt;
    END IF;
    ir_sr_line.row_level_status := gn_data_status_normal;
--
  EXCEPTION
    --*** データチェック処理エラー ***
    WHEN check_data_expt THEN
      ir_sr_line.row_level_status := gn_data_status_warn;
      gn_data_status := gn_data_status_warn;
      ov_retcode := gv_status_warn;
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
  END check_data;
--
  /***********************************************************************************
   * Procedure Name   : get_profile
   * Description      : MAX日付取得プロシージャ
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   ############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_max_pro_date CONSTANT VARCHAR2(20) := 'MAX日付';
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
    cv_mgr_type2_base_code_name    CONSTANT VARCHAR2(100) := 'XXCMN:物流構成マスタ管理タイプ２拠点コード';
-- 2008/11/17 H.Itou Add End
--
    -- *** ローカル変数 ***
    lv_max_date  VARCHAR2(10);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --最大日付取得
    lv_max_date := SUBSTR(FND_PROFILE.VALUE(gv_prf_max_date),1,10);
--
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
    -- XXCMN:物流構成マスタ管理タイプ２拠点コード
    gv_dummy_base_code := SUBSTRB(FND_PROFILE.VALUE(gv_prf_mgr_type2_base_code),1,10);
--
-- 2008/11/17 H.Itou Add End
--
    -- プロファイルが取得できない場合はエラー
    IF (lv_max_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_no_profile,
                                            gv_tkn_ng_profile, cv_max_pro_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
    -- XXCMN:物流構成マスタ管理タイプ２拠点コードが取得できない場合、エラー
    IF (gv_dummy_base_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     gv_msg_kbn                                      -- アプリケーション：XXCMN
                    ,gv_msg_no_profile                               -- APP-XXCMN-10002 プロファイル取得エラー
                    ,gv_tkn_ng_profile ,cv_mgr_type2_base_code_name  -- トークン：NG_PROFLIE = XXCMN:物流構成マスタ管理タイプ２拠点コード
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2008/11/17 H.Itou Add End
    gv_max_date := lv_max_date; -- 最大日付に設定
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ######################################
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
--#####################################  固定部 END   ############################################
--
  END get_profile;
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
    ld_end_date  DATE ;
    lr_sr_line_rec sr_line_rec;
    ln_sourcing_rule_id NUMBER;
    -- 挿入用データ格納用
    ln_insert_user_id         NUMBER(15,0);
    ld_insert_date            DATE;
    ln_insert_login_id        NUMBER(15,0);
    ln_insert_request_id      NUMBER(15,0);
    ln_insert_prog_appl_id    NUMBER(15,0);
    ln_insert_program_id      NUMBER(15,0);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 要求IDカーソル xsli_request
    CURSOR xsli_request_id_cur IS
-- 2009/06/29 MOD START
    SELECT DISTINCT xsl.request_id
    FROM xxcmn_sr_lines_if xsl
    WHERE EXISTS(
     SELECT 'X'
     FROM   fnd_concurrent_requests fcr
     WHERE  fcr.request_id = xsl.request_id 
    );
/*
    SELECT fcr.request_id 
    FROM fnd_concurrent_requests fcr
    WHERE EXISTS (
          SELECT 1
          FROM xxcmn_sr_lines_if xsl
          WHERE xsl.request_id = fcr.request_id
          AND ROWNUM = 1
        );
*/
-- 2009/06/29 MOD END
--
    -- 前歴＋後歴のロックカーソル xsr_lock_start_end_cur
    CURSOR xsr_lock_start_end_cur IS
    SELECT xsr.item_code     item_code
          ,xsr.base_code     base_code
          ,xsr.ship_to_code  ship_to_code
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
          ,xsli.item_code    if_item_code
-- 2008/11/17 H.Itou Add End
    FROM   xxcmn_sr_lines_if    xsli  -- 物流構成アドオンインタフェース
          ,xxcmn_sourcing_rules xsr 
    WHERE  xsli.item_code         = xsr.item_code
    AND    xsli.base_code         = xsr.base_code
    AND    xsli.ship_to_code      = xsr.ship_to_code
    FOR UPDATE OF  xsr.item_code
                  ,xsr.base_code
                  ,xsr.ship_to_code
                  ,xsr.start_date_active 
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
                  ,xsli.item_code
-- 2008/11/17 H.Itou Add End
    NOWAIT;
--
    -- 物流構成アドオンインタフェース取得カーソル get_sr_line_cur
    CURSOR get_sr_line_cur IS
    -- ============================================
    -- 管理タイプ1：品目出荷元倉庫・計画商品管理
    -- ============================================
    SELECT xsli.item_code            item_code                 -- 品目コード
          ,xsli.base_code            base_code                 -- 拠点コード
          ,xsli.ship_to_code         ship_to_code              -- 配送先コード
          ,xsli.start_date_active    start_date_active         -- 適用開始日
          ,xsli.end_date_active      end_date_active           -- 適用終了日
          ,xsli.delivery_whse_code   delivery_whse_code        -- 出庫倉庫コード
          ,xsli.move_from_whse_code1 move_from_whse_code1      -- 移動元倉庫コード1
          ,xsli.move_from_whse_code2 move_from_whse_code2      -- 移動元倉庫コード2
          ,xsli.vendor_site_code1    vendor_site_code1         -- 仕入先サイトコード1
          ,xsli.vendor_site_code2    vendor_site_code2         -- 仕入先サイトコード2
          ,xsli.plan_item_flag       plan_item_flag            -- 計画商品フラグ
          ,xsr.sourcing_rules_id     sourcing_rules_id         -- 物流構成アドオンID(洗い替え対象ID)
-- 2009/06/10 ADD START
          ,xsli.sourcing_rules_id    delete_key                -- 削除キー
-- 2009/06/10 ADD END
    FROM   xxcmn_sr_lines_if         xsli                      -- 物流構成アドオンインタフェーステーブル
          ,xxcmn_sourcing_rules      xsr                       -- 物流構成アドオンマスタ
    WHERE  xsli.item_code          = xsr.item_code(+)          -- 品目コード    (キー項目)
    AND    xsli.base_code          = xsr.base_code(+)          -- 拠点コード    (キー項目)
    AND    xsli.ship_to_code       = xsr.ship_to_code(+)       -- 配送先        (キー項目)
    AND    xsli.start_date_active  = xsr.start_date_active(+)  -- 適用開始日    (キー項目)
-- 2008/11/17 H.Itou Add Start 統合テスト指摘491
    AND    NOT ((xsli.base_code          = gv_dummy_base_code) -- 拠点コードがダミー(AAAA)でない
            AND (xsli.ship_to_code       = gv_no_ship_to_code))-- 配送先コードがダミー(000000000)でない
    -- ============================================
    -- 管理タイプ2：品目在庫補充元管理
    -- ============================================
    UNION ALL
    SELECT xsli.item_code            item_code                 -- 品目コード
          ,xsli.base_code            base_code                 -- 拠点コード
          ,xsli.ship_to_code         ship_to_code              -- 配送先コード
          ,xsli.start_date_active    start_date_active         -- 適用開始日
          ,xsli.end_date_active      end_date_active           -- 適用終了日
          ,xsli.delivery_whse_code   delivery_whse_code        -- 出庫倉庫コード
          ,xsli.move_from_whse_code1 move_from_whse_code1      -- 移動元倉庫コード1
          ,xsli.move_from_whse_code2 move_from_whse_code2      -- 移動元倉庫コード2
          ,xsli.vendor_site_code1    vendor_site_code1         -- 仕入先サイトコード1
          ,xsli.vendor_site_code2    vendor_site_code2         -- 仕入先サイトコード2
          ,xsli.plan_item_flag       plan_item_flag            -- 計画商品フラグ
          ,xsr.sourcing_rules_id     sourcing_rules_id         -- 物流構成アドオンID(洗い替え対象ID)
-- 2009/06/10 ADD START
          ,xsli.sourcing_rules_id    delete_key                -- 削除キー
-- 2009/06/10 ADD END
    FROM   xxcmn_sr_lines_if         xsli                      -- 物流構成アドオンインタフェーステーブル
          ,xxcmn_sourcing_rules      xsr                       -- 物流構成アドオンマスタ
    WHERE  xsli.item_code          = xsr.item_code(+)          -- 品目コード    (キー項目)
    AND    xsli.base_code          = xsr.base_code(+)          -- 拠点コード    (キー項目)
    AND    xsli.ship_to_code       = xsr.ship_to_code(+)       -- 配送先        (キー項目)
    AND    xsli.delivery_whse_code = xsr.delivery_whse_code(+) -- 出荷先保管倉庫(キー項目)
    AND    xsli.start_date_active  = xsr.start_date_active(+)  -- 適用開始日    (キー項目)
    AND    xsli.base_code          = gv_dummy_base_code        -- 拠点コードがダミー(AAAA)
    AND    xsli.ship_to_code       = gv_no_ship_to_code        -- 配送先コードがダミー(000000000)
-- 2008/11/17 H.Itou Add End
-- 2008/11/17 H.Itou Mod Start 統合テスト指摘491
--    ORDER BY xsli.item_code
--            ,xsli.base_code
--            ,xsli.ship_to_code
--            ,xsli.start_date_active
    ORDER BY item_code
            ,base_code
            ,ship_to_code
            ,start_date_active
            ,delivery_whse_code
-- 2008/11/17 H.Itou Mod End
-- 2008/11/17 H.Itou Del Start 統合テスト指摘491
--    FOR UPDATE OF xsli.item_code
--                  ,xsli.base_code
--                  ,xsli.ship_to_code
--                  ,xsli.start_date_active
--    NOWAIT
-- 2008/11/17 H.Itou Del End
    ;
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
    -- インサートデータの初期化
    ln_insert_user_id      := FND_GLOBAL.USER_ID;
    ld_insert_date         := SYSDATE;
    ln_insert_login_id     := FND_GLOBAL.LOGIN_ID;
    ln_insert_request_id   := FND_GLOBAL.CONC_REQUEST_ID;
    ln_insert_prog_appl_id := FND_GLOBAL.PROG_APPL_ID;
    ln_insert_program_id   := FND_GLOBAL.CONC_PROGRAM_ID;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    --  get_profile プロファイルよりMAX日付を取得します。
    -- ===============================
--
    get_profile(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- 例外処理
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    --  処理対象要求ID取得
    -- ===============================
--
    <<get_request_id_loop>>
    FOR get_req_data IN xsli_request_id_cur  LOOP
      gn_request_id_cnt := gn_request_id_cnt + 1;
      gt_request_id_tbl(gn_request_id_cnt) := get_req_data.request_id;
    END LOOP get_request_id_loop;
--
    -- ===============================
    --  前歴＋後歴のロック取得
    -- ===============================
    BEGIN
--
      <<get_start_end_loop>>
      FOR ln_count IN  xsr_lock_start_end_cur  LOOP
        EXIT;
      END LOOP get_start_end_loop;
    -- 例外処理
    EXCEPTION
      WHEN check_lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_lock,
                                              gv_tkn_table, gv_xxcmn_sr_lines_if);
        lv_errbuf := lv_errmsg;
        RAISE check_sub_main_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
    --
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
    -- ===============================
    --  物流構成アドオンインタフェース取得(B-1)
    -- ===============================
    BEGIN
--
      -- セーブポイントを取得
      SAVEPOINT spoint;
-- 2009/06/10 ADD START
      -- 削除キーが設定されているIFデータに一致する物流構成マスタを一括削除する。
      -- 処理結果ログは後続の処理で出力する。
      BEGIN
        DELETE
        FROM   xxcmn_sourcing_rules xsr                -- 物流構成アドオンマスタ
        WHERE  EXISTS(
          SELECT 'X'
          FROM   xxcmn_sr_lines_if         xsli
          WHERE  xsli.sourcing_rules_id =  xsr.sourcing_rules_id
          );
      EXCEPTION
        WHEN others THEN
          lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10022','TABLE',gv_xxcmn_sourcing_rules);
          lv_errbuf := lv_errmsg || ' ' || SQLERRM;
          RAISE check_sub_main_expt;
      END;
-- 2009/06/10 ADD END
--
      <<get_srl_loop>>
      FOR get_srl_data IN get_sr_line_cur
      LOOP
        -- 処理件数のカウントアップ
        gn_target_cnt := gn_target_cnt + 1;
        -- レコード変数に格納
        lr_sr_line_rec.item_code := get_srl_data.item_code;
        lr_sr_line_rec.base_code := get_srl_data.base_code;
        lr_sr_line_rec.ship_to_code := get_srl_data.ship_to_code;
        lr_sr_line_rec.start_date_active := get_srl_data.start_date_active;
        lr_sr_line_rec.end_date_active := get_srl_data.end_date_active;
        lr_sr_line_rec.delivery_whse_code := get_srl_data.delivery_whse_code;
        lr_sr_line_rec.move_from_whse_code1 := get_srl_data.move_from_whse_code1;
        lr_sr_line_rec.move_from_whse_code2 := get_srl_data.move_from_whse_code2;
        lr_sr_line_rec.vendor_site_code1 := get_srl_data.vendor_site_code1;
        lr_sr_line_rec.vendor_site_code2 := get_srl_data.vendor_site_code2;
        lr_sr_line_rec.plan_item_flag := get_srl_data.plan_item_flag;
-- 2009/06/10 ADD START
        lr_sr_line_rec.delete_key       := get_srl_data.delete_key; --削除キー格納
        lr_sr_line_rec.row_level_status := gn_data_status_normal;   --ステータス初期化
-- 2009/06/10 ADD END
        -- 削除用物流構成アドオンID格納
        ln_sourcing_rule_id := get_srl_data.sourcing_rules_id;
--
        -- 削除キーが設定されないデータは登録、更新処理を行う
        IF(lr_sr_line_rec.delete_key IS NULL) THEN
          -- ===============================
          --  項目チェック(B-2)(B-3)(B-4)
          -- ===============================    
          check_data(
            lr_sr_line_rec, -- 1.レコード
            lv_errbuf,      --   エラー・メッセージ           --# 固定 #
            lv_retcode,     --   リターン・コード             --# 固定 #
            lv_errmsg);     --   ユーザー・エラー・メッセージ --# 固定 #
  --
            -- 例外処理
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
  --
          -- ===============================
          --  登録対象レコード編集(B-5)
          -- ===============================    
          IF (gn_data_status = gn_data_status_normal) THEN
            set_table_data(
              lr_sr_line_rec,                -- 1.レコード
              lv_errbuf,                     --   エラー・メッセージ           --# 固定 #
              lv_retcode,                    --   リターン・コード             --# 固定 #
              lv_errmsg);                    --   ユーザー・エラー・メッセージ --# 固定 #
          END IF;
  --
            -- 例外処理
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
  --
          IF (gn_data_status = gn_data_status_normal)
            AND (gn_target_cnt > 0)  THEN
            -- ===============================
            --  物流構成アドオンマスタ削除(B-6)
            -- ===============================    
            IF (ln_sourcing_rule_id IS NOT NULL) THEN
              delete_sourcing_rules(
                ln_sourcing_rule_id,            -- 物流構成アドオンID
                lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
                lv_retcode,                     -- リターン・コード             --# 固定 #
                lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
  --
              -- 例外処理
              IF (lv_retcode = gv_status_error) THEN
                RAISE check_sub_main_expt;
              END IF;
            END IF;
  --
            -- ===============================
            --  適用終了日編集(B-7)
            -- ===============================    
            lr_sr_line_rec.end_date_active  := modify_end_date(
              lr_sr_line_rec,         -- 1.レコード
              ln_insert_user_id,      -- 2.ユーザーID  
              ld_insert_date,         -- 3.更新日
              ln_insert_login_id,     -- 4.ログインID
              ln_insert_request_id,   -- 5.要求ID
              ln_insert_prog_appl_id, -- 6.コンカレント・プログラムのアプリケーションID
              ln_insert_program_id);   -- 7.コンカレント・プログラムID
  --
            -- 例外処理
            IF (lv_retcode = gv_status_error) THEN
              RAISE check_sub_main_expt;
            END IF;
  --
            -- ===============================
            --  倉庫重複チェック(B-8)
            -- ===============================    
            check_whse_data(
              lr_sr_line_rec, -- 1.レコード
              lv_errbuf,      --   エラー・メッセージ           --# 固定 #
              lv_retcode,     --   リターン・コード             --# 固定 #
              lv_errmsg);     --   ユーザー・エラー・メッセージ --# 固定 #
    --
              -- 例外処理
            IF (lv_retcode = gv_status_error) THEN
              RAISE check_sub_main_expt;
            END IF;
  --
  -- 2008/10/29 v1.4 T.Yoshimoto Add Start 統合#251
            -- ===============================
            --  倉庫重複チェック2(B-11)
            -- ===============================    
            check_whse_data2(
              lr_sr_line_rec, -- 1.レコード
              lv_errbuf,      --   エラー・メッセージ           --# 固定 #
              lv_retcode,     --   リターン・コード             --# 固定 #
              lv_errmsg);     --   ユーザー・エラー・メッセージ --# 固定 #
    --
              -- 例外処理
            IF (lv_retcode = gv_status_error) THEN
              RAISE check_sub_main_expt;
            END IF;
  -- 2008/10/29 v1.4 T.Yoshimoto Add End 統合#251
  --
            -- ===============================
            --  物流構成アドオンマスタ挿入(B-9)
            -- ===============================    
            -- 登録処理
            insert_sr_rules(
              lr_sr_line_rec,         -- 1.レコード
              ln_insert_user_id,      -- 2.ユーザーID  
              ld_insert_date,         -- 3.更新日
              ln_insert_login_id,     -- 4.ログインID
              ln_insert_request_id,   -- 5.要求ID
              ln_insert_prog_appl_id, -- 6.コンカレント・プログラムのアプリケーションID
              ln_insert_program_id,   -- 7.コンカレント・プログラムID
              lv_errbuf,              -- エラー・メッセージ           --# 固定 #
              lv_retcode,             -- リターン・コード             --# 固定 #
              lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
  --
            -- 例外処理
            IF (lv_retcode = gv_status_error) THEN
              RAISE check_sub_main_expt;
            END IF;
          END IF;
        END IF;
-- 2009/06/10 ADD END
--
        gt_sr_line_tbl(gn_target_cnt) := lr_sr_line_rec;
--
        IF (lr_sr_line_rec.row_level_status = gn_data_status_normal) THEN
          gn_normal_cnt := gn_normal_cnt + 1;
        ELSIF (lr_sr_line_rec.row_level_status = gn_data_status_warn) THEN
          gn_warn_cnt   := gn_warn_cnt + 1;
        ELSE 
          gn_error_cnt  := gn_error_cnt + 1;
        END IF;
--
      END LOOP get_srl_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
    EXCEPTION
      WHEN check_lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_ng_lock,
                                              gv_tkn_table, gv_xxcmn_sr_lines_if);
        lv_errbuf := lv_errmsg;
        RAISE check_sub_main_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- 警告がある場合はセーブポイントへロールバック
    IF (gn_warn_cnt > 0) THEN
      ROLLBACK TO spoint;
    END IF;
--
    -- 正常か警告の場合かつ処理件数が1件以上の場合
    IF ((gn_data_status <> gn_data_status_error)
         AND ( gn_target_cnt > 0 )) THEN
        -- ===============================
        --  物流構成アドオンインタフェーステーブル削除(B-10)
        -- ===============================    
      delete_sr_lines_if(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- 例外処理
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (gn_normal_cnt > 0) THEN
      -- ログ出力処理(成功:0)
      disp_report(gn_data_status_normal,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      -- 例外処理
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (gn_error_cnt > 0) THEN
      -- ログ出力処理(失敗:1)
      disp_report(gn_data_status_error,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      -- 例外処理
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (gn_warn_cnt > 0) THEN
      -- ログ出力処理(警告:2)
      disp_report(gn_data_status_warn,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      -- 例外処理
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
    END IF;
--
    IF (gn_data_status = gn_data_status_warn) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
    WHEN check_sub_main_expt THEN
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
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
    errbuf        OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT NOCOPY VARCHAR2       --   リターン・コード    --# 固定 #
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
--###########################  固定部 START   ####################################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
--
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
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   ####################################################
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
--###########################  固定部 END   ######################################################
--
END xxcmn890001c;
/
