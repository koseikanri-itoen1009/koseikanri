CREATE OR REPLACE PACKAGE BODY xxpo310002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo310002c(body)
 * Description      : HHT発注情報IF
 * MD.050           : 受入実績            T_MD050_BPO_310
 * MD.070           : HHT発注情報IF       T_MD070_BPO_31E
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              前処理                                       (E-1)
 *  parameter_check        パラメータチェック                           (E-2)
 *  get_mast_data          発注情報取得                                 (E-3)
 *  create_csv_file        受入予定情報出力                             (E-4)
 *  disp_report            件数出力                                     (E-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/08    1.0   Oracle 山根 一浩 初回作成
 *  2008/04/21    1.1   Oracle 山根 一浩 変更要求No43対応
 *  2008/05/23    1.2   Oracle 藤井 良平 結合テスト不具合（シナリオ4-1）
 *  2008/07/14    1.3   Oracle 椎名 昭圭 仕様不備障害#I_S_001.4,#I_S_192.1.2,#T_S_435対応
 *  2008/09/01    1.4   Oracle 山根 一浩 T_TE080_BPO_310 指摘9対応
 *  2008/09/17    1.5   Oracle 大橋 孝郎 指摘204対応
 *  2009/01/26    1.6   Oracle 椎名 昭圭 本番#1046対応
 *  2010/01/19    1.7   SCS    吉元 強樹 E_本稼動#1075対応
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
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
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
-- add start 1.5
  warning_expt           EXCEPTION;
-- add end 1.5
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name            CONSTANT VARCHAR2(100) := 'xxpo310002c';   -- パッケージ名
  gv_app_name            CONSTANT VARCHAR2(5)   := 'XXPO';          -- アプリケーション短縮名
--
  gv_status_po_zumi      CONSTANT VARCHAR2(2)   := '20';            -- 発注作成済
  gv_status_money_zumi   CONSTANT VARCHAR2(2)   := '35';            -- 金額確定済
  gv_class_code_seihin   CONSTANT VARCHAR2(1)   := '5';             -- 製品
-- 2010/01/19 v1.7 T.Yoshimoto Add Start 本稼動#1175
  gv_ship_class_1         CONSTANT VARCHAR2(1)   := '1';             -- 出荷可
-- 2010/01/19 v1.7 T.Yoshimoto Add End 本稼動#1175
--
  -- トークン
  gv_tkn_number_31e_01    CONSTANT VARCHAR2(15) := 'APP-XXPO-10062';  -- 受入予定情報ﾌｧｲﾙ名取得ｴﾗｰ
  gv_tkn_number_31e_02    CONSTANT VARCHAR2(15) := 'APP-XXPO-10063';  -- 受入予定情報既存在ｴﾗｰ
  gv_tkn_number_31e_03    CONSTANT VARCHAR2(15) := 'APP-XXPO-10064';  -- 受入予定情報出力先取得ｴﾗｰ
  gv_tkn_number_31e_04    CONSTANT VARCHAR2(15) := 'APP-XXPO-10065';  -- 出力先ﾃﾞｨﾚｸﾄﾘ不存在ｴﾗｰ
  gv_tkn_number_31e_05    CONSTANT VARCHAR2(15) := 'APP-XXPO-10093';  -- 発注情報未取得ｴﾗｰ
  gv_tkn_number_31e_06    CONSTANT VARCHAR2(15) := 'APP-XXPO-10102';  -- 不正なﾊﾟﾗﾒｰﾀ1
  gv_tkn_number_31e_07    CONSTANT VARCHAR2(15) := 'APP-XXPO-10103';  -- 不正なﾊﾟﾗﾒｰﾀ2
  gv_tkn_number_31e_08    CONSTANT VARCHAR2(15) := 'APP-XXPO-10104';  -- 不正なﾊﾟﾗﾒｰﾀ3
  gv_tkn_number_31e_09    CONSTANT VARCHAR2(15) := 'APP-XXPO-10106';  -- 不正なﾊﾟﾗﾒｰﾀ5
  gv_tkn_number_31e_10    CONSTANT VARCHAR2(15) := 'APP-XXPO-30027';  -- 処理件数
  gv_tkn_number_31e_11    CONSTANT VARCHAR2(15) := 'APP-XXPO-30035';  -- 入力ﾊﾟﾗﾒｰﾀ情報1
--
  gv_tkn_count            CONSTANT VARCHAR2(15) := 'COUNT';
  gv_tkn_date_from        CONSTANT VARCHAR2(15) := 'DATE_FROM';
  gv_tkn_date_to          CONSTANT VARCHAR2(15) := 'DATE_TO';
  gv_tkn_param_name       CONSTANT VARCHAR2(15) := 'PARAM_NAME';
  gv_tkn_param_value      CONSTANT VARCHAR2(15) := 'PARAM_VALUE';
  gv_tkn_path             CONSTANT VARCHAR2(15) := 'PATH';
  gv_tkn_ship             CONSTANT VARCHAR2(15) := 'SHIP';
  gv_tkn_vendor           CONSTANT VARCHAR2(15) := 'VENDOR';
--
  gv_tkn_2byte_date_from  CONSTANT VARCHAR2(50) := '納入日(FROM)';
  gv_tkn_2byte_date_to    CONSTANT VARCHAR2(50) := '納入日(TO)';
  gv_tkn_2byte_ship       CONSTANT VARCHAR2(50) := '納入先';
  gv_tkn_2byte_vendor     CONSTANT VARCHAR2(50) := '取引先';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ***************************************
  -- ***    取得情報格納レコード型定義   ***
  -- ***************************************
--
  -- D-3:発注情報取得対象データ
  TYPE masters_rec IS RECORD(
    po_header_number    po_headers_all.segment1%TYPE,               -- 発注番号
    segment1            xxcmn_vendors_v.segment1%TYPE,              -- 仕入先番号
    vendor_short_name   xxcmn_vendors_v.vendor_short_name%TYPE,     -- 略称(取引先名)
    attribute4          po_headers_all.attribute4%TYPE,             -- 納入日
    attribute5          po_headers_all.attribute5%TYPE,             -- 納入先コード
    description         xxcmn_item_locations_v.description%TYPE,    -- 摘要(納入先名)
    line_num            po_lines_all.line_num%TYPE,                 -- 明細番号
    item_no             xxcmn_item_mst_v.item_no%TYPE,              -- 品目
    item_short_name     xxcmn_item_mst_v.item_short_name%TYPE,      -- 略称(品名称)
    lot_no              po_lines_all.attribute1%TYPE,               -- ロットNo
    attribute1          ic_lots_mst.attribute1%TYPE,                -- 製造年月日
-- 2008/07/14 1.3 ADD Start
    attribute3          ic_lots_mst.attribute3%TYPE,                -- 賞味期限
-- 2008/07/14 1.3 ADD End
    attribute2          ic_lots_mst.attribute2%TYPE,                -- 固有記号
    attribute11         po_lines_all.attribute11%TYPE,              -- 発注数量
    attribute10         po_lines_all.attribute10%TYPE,              -- 発注単位
    attribute15         po_lines_all.attribute15%TYPE,              -- 明細摘要
-- 2009/01/26 v1.6 ADD START
    num_of_cases        xxcmn_item_mst_v.num_of_cases%TYPE,         -- ケース入数
    conv_unit           xxcmn_item_mst_v.conv_unit%TYPE,            -- 入出庫換算単位
    prod_class_code     xxcmn_item_categories5_v.prod_class_code%TYPE, -- 商品区分
    item_class_code     xxcmn_item_categories5_v.item_class_code%TYPE, -- 品目区分
-- 2009/01/26 v1.6 ADD END
--
    exec_flg            NUMBER                                      -- 処理フラグ
  );
  -- 各マスタへ反映するデータを格納する結合配列
  TYPE masters_tbl  IS TABLE OF masters_rec  INDEX BY PLS_INTEGER;
--
  -- ***************************************
  -- ***      登録用項目テーブル型       ***
  -- ***************************************
--
  gt_master_tbl                masters_tbl;  -- 各マスタへ登録するデータ
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_rcv_sch_out_dir          VARCHAR2(2000);             -- XXPO:受入予定情報出力先
  gv_rcv_sch_file_name        VARCHAR2(2000);             -- XXPO:受入予定情報ファイル名
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 前処理(E-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'init_proc';       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
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
    -- 受入予定情報出力先
    gv_rcv_sch_out_dir := FND_PROFILE.VALUE('XXPO_RCV_SCH_OUT_DIR');
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_rcv_sch_out_dir IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_03);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 受入予定情報ファイル名
    gv_rcv_sch_file_name := FND_PROFILE.VALUE('XXPO_RCV_SCH_FILE_NAME');
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_rcv_sch_file_name IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_01);
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : パラメータチェック(E-2)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_from_date   IN            VARCHAR2,     -- 1.納入日(FROM)
    iv_to_date     IN            VARCHAR2,     -- 2.納入日(TO)
-- 2008/07/14 1.3 UPDATE Start
--    iv_inv_code   IN            VARCHAR2,     -- 3.納入先コード
--    iv_vendor_id  IN            VARCHAR2,     -- 4.取引先コード
    iv_inv_code_01 IN           VARCHAR2,     -- 03.納入先コード01
    iv_inv_code_02 IN           VARCHAR2,     -- 04.納入先コード02
    iv_inv_code_03 IN           VARCHAR2,     -- 05.納入先コード03
    iv_inv_code_04 IN           VARCHAR2,     -- 06.納入先コード04
    iv_inv_code_05 IN           VARCHAR2,     -- 07.納入先コード05
    iv_inv_code_06 IN           VARCHAR2,     -- 08.納入先コード06
    iv_inv_code_07 IN           VARCHAR2,     -- 09.納入先コード07
    iv_inv_code_08 IN           VARCHAR2,     -- 10.納入先コード08
    iv_inv_code_09 IN           VARCHAR2,     -- 11.納入先コード09
    iv_inv_code_10 IN           VARCHAR2,     -- 12.納入先コード10
    iv_vendor_id   IN           VARCHAR2,     -- 13.取引先コード
-- 2008/07/14 1.3 UPDATE End
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'parameter_check';       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ld_from_date       DATE;
    ld_to_date         DATE;
    ln_cnt             NUMBER;
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
-- 2008/07/14 1.3 UPDATE Start
--    -- 納入先が未入力
--    IF (iv_inv_code IS NULL) THEN
    -- 納入先01が未入力
    IF (iv_inv_code_01 IS NULL) THEN
-- 2008/07/14 1.3 UPDATE End
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_06,
                                            gv_tkn_param_name,
                                            gv_tkn_2byte_ship);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 納入日(FROM)が未入力
    IF (iv_from_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_06,
                                            gv_tkn_param_name,
                                            gv_tkn_2byte_date_from);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 納入日(TO)が未入力
    IF (iv_to_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_06,
                                            gv_tkn_param_name,
                                            gv_tkn_2byte_date_to);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 日付に変換
    ld_from_date := FND_DATE.STRING_TO_DATE(iv_from_date,'YYYY/MM/DD');
--
    -- 日付として妥当でない
    IF (ld_from_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_08,
                                              gv_tkn_param_value,
                                              iv_from_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 日付に変換
    ld_to_date := FND_DATE.STRING_TO_DATE(iv_to_date,'YYYY/MM/DD');
--
    -- 日付として妥当でない
    IF (ld_to_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_08,
                                            gv_tkn_param_value,
                                            iv_to_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 納入日(FROM) > 納入日(TO)
    IF (ld_from_date > ld_to_date) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_09);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2008/07/14 1.3 UPDATE Start
/*    -- 納入先コードチェック
    SELECT COUNT(xilv.segment1)
    INTO   ln_cnt
    FROM   xxcmn_item_locations_v xilv                  -- OPM保管場所情報VIEW
    WHERE  xilv.segment1 = iv_inv_code
    AND    ROWNUM        = 1;
--
    -- 納入先コードがない
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_07,
                                            gv_tkn_param_name,
                                            gv_tkn_2byte_ship,
                                            gv_tkn_param_value,
                                            iv_inv_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
*/--
    -- 納入先コード01チェック
    SELECT COUNT(xilv.segment1)
    INTO   ln_cnt
    FROM   xxcmn_item_locations_v xilv                  -- OPM保管場所情報VIEW
    WHERE  xilv.segment1 = iv_inv_code_01
    AND    ROWNUM        = 1;
--
    -- 納入先コードがない
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_07,
                                            gv_tkn_param_name,
                                            gv_tkn_2byte_ship,
                                            gv_tkn_param_value,
                                            iv_inv_code_01);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 納入先コード02チェック
    IF (iv_inv_code_02 IS NOT NULL) THEN
      SELECT COUNT(xilv.segment1)
      INTO   ln_cnt
      FROM   xxcmn_item_locations_v xilv                  -- OPM保管場所情報VIEW
      WHERE  xilv.segment1 = iv_inv_code_02
      AND    ROWNUM        = 1;
--
      -- 納入先コードがない
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_07,
                                              gv_tkn_param_name,
                                              gv_tkn_2byte_ship,
                                              gv_tkn_param_value,
                                              iv_inv_code_02);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    -- 納入先コード03チェック
    IF (iv_inv_code_03 IS NOT NULL) THEN
      SELECT COUNT(xilv.segment1)
      INTO   ln_cnt
      FROM   xxcmn_item_locations_v xilv                  -- OPM保管場所情報VIEW
      WHERE  xilv.segment1 = iv_inv_code_03
      AND    ROWNUM        = 1;
--
      -- 納入先コードがない
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_07,
                                              gv_tkn_param_name,
                                              gv_tkn_2byte_ship,
                                              gv_tkn_param_value,
                                              iv_inv_code_03);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    -- 納入先コード04チェック
    IF (iv_inv_code_04 IS NOT NULL) THEN
      SELECT COUNT(xilv.segment1)
      INTO   ln_cnt
      FROM   xxcmn_item_locations_v xilv                  -- OPM保管場所情報VIEW
      WHERE  xilv.segment1 = iv_inv_code_04
      AND    ROWNUM        = 1;
--
      -- 納入先コードがない
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_07,
                                              gv_tkn_param_name,
                                              gv_tkn_2byte_ship,
                                              gv_tkn_param_value,
                                              iv_inv_code_04);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    -- 納入先コード05チェック
    IF (iv_inv_code_05 IS NOT NULL) THEN
      SELECT COUNT(xilv.segment1)
      INTO   ln_cnt
      FROM   xxcmn_item_locations_v xilv                  -- OPM保管場所情報VIEW
      WHERE  xilv.segment1 = iv_inv_code_05
      AND    ROWNUM        = 1;
--
      -- 納入先コードがない
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_07,
                                              gv_tkn_param_name,
                                              gv_tkn_2byte_ship,
                                              gv_tkn_param_value,
                                              iv_inv_code_05);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    -- 納入先コード06チェック
    IF (iv_inv_code_06 IS NOT NULL) THEN
      SELECT COUNT(xilv.segment1)
      INTO   ln_cnt
      FROM   xxcmn_item_locations_v xilv                  -- OPM保管場所情報VIEW
      WHERE  xilv.segment1 = iv_inv_code_06
      AND    ROWNUM        = 1;
--
      -- 納入先コードがない
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_07,
                                              gv_tkn_param_name,
                                              gv_tkn_2byte_ship,
                                              gv_tkn_param_value,
                                              iv_inv_code_06);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    -- 納入先コード07チェック
    IF (iv_inv_code_07 IS NOT NULL) THEN
      SELECT COUNT(xilv.segment1)
      INTO   ln_cnt
      FROM   xxcmn_item_locations_v xilv                  -- OPM保管場所情報VIEW
      WHERE  xilv.segment1 = iv_inv_code_07
      AND    ROWNUM        = 1;
--
      -- 納入先コードがない
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_07,
                                              gv_tkn_param_name,
                                              gv_tkn_2byte_ship,
                                              gv_tkn_param_value,
                                              iv_inv_code_07);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    -- 納入先コード08チェック
    IF (iv_inv_code_08 IS NOT NULL) THEN
      SELECT COUNT(xilv.segment1)
      INTO   ln_cnt
      FROM   xxcmn_item_locations_v xilv                  -- OPM保管場所情報VIEW
      WHERE  xilv.segment1 = iv_inv_code_08
      AND    ROWNUM        = 1;
--
      -- 納入先コードがない
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_07,
                                              gv_tkn_param_name,
                                              gv_tkn_2byte_ship,
                                              gv_tkn_param_value,
                                              iv_inv_code_08);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    -- 納入先コード09チェック
    IF (iv_inv_code_09 IS NOT NULL) THEN
      SELECT COUNT(xilv.segment1)
      INTO   ln_cnt
      FROM   xxcmn_item_locations_v xilv                  -- OPM保管場所情報VIEW
      WHERE  xilv.segment1 = iv_inv_code_09
      AND    ROWNUM        = 1;
--
      -- 納入先コードがない
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_07,
                                              gv_tkn_param_name,
                                              gv_tkn_2byte_ship,
                                              gv_tkn_param_value,
                                              iv_inv_code_09);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    -- 納入先コード10チェック
    IF (iv_inv_code_10 IS NOT NULL) THEN
      SELECT COUNT(xilv.segment1)
      INTO   ln_cnt
      FROM   xxcmn_item_locations_v xilv                  -- OPM保管場所情報VIEW
      WHERE  xilv.segment1 = iv_inv_code_10
      AND    ROWNUM        = 1;
--
      -- 納入先コードがない
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_07,
                                              gv_tkn_param_name,
                                              gv_tkn_2byte_ship,
                                              gv_tkn_param_value,
                                              iv_inv_code_10);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
-- 2008/07/14 1.3 UPDATE End
--
    -- 取引先が指定あり
    IF (iv_vendor_id IS NOT NULL) THEN
      SELECT COUNT(xvv.segment1)
      INTO   ln_cnt
      FROM   xxcmn_vendors_v xvv                        -- 仕入先情報VIEW
      WHERE  xvv.segment1 = iv_vendor_id
      AND    ROWNUM       = 1;
--
      -- 取引先コードがない
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_07,
                                              gv_tkn_param_name,
                                              gv_tkn_2byte_vendor,
                                              gv_tkn_param_value,
                                              iv_vendor_id);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 入力パラメータ表示
-- 2008/07/14 1.3 UPDATE Start
/*    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_31e_11,
                                          gv_tkn_vendor,
                                          iv_vendor_id,
                                          gv_tkn_ship,
                                          iv_inv_code,
                                          gv_tkn_date_from,
                                          iv_from_date,
                                          gv_tkn_date_to,
                                          iv_to_date);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
*/--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '＜入力パラメータ情報＞');
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '取引先コード：'   || iv_vendor_id);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '納入先コード01：' || iv_inv_code_01);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '納入先コード02：' || iv_inv_code_02);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '納入先コード03：' || iv_inv_code_03);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '納入先コード04：' || iv_inv_code_04);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '納入先コード05：' || iv_inv_code_05);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '納入先コード06：' || iv_inv_code_06);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '納入先コード07：' || iv_inv_code_07);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '納入先コード08：' || iv_inv_code_08);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '納入先コード09：' || iv_inv_code_09);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '納入先コード10：' || iv_inv_code_10);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '納入日(From)：'   || iv_from_date);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '納入日(To)：'     || iv_to_date);
--
-- 2008/07/14 1.3 UPDATE End
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END parameter_check;
--
  /***********************************************************************************
   * Procedure Name   : get_mast_data
   * Description      : 発注情報取得(E-3)
   ***********************************************************************************/
  PROCEDURE get_mast_data(
    iv_from_date   IN            VARCHAR2,     -- 1.納入日(FROM)
    iv_to_date     IN            VARCHAR2,     -- 2.納入日(TO)
-- 2008/07/14 1.3 UPDATE Start
--    iv_inv_code   IN            VARCHAR2,     -- 3.納入先コード
--    iv_vendor_id  IN            VARCHAR2,     -- 4.取引先コード
    iv_inv_code_01 IN           VARCHAR2,     -- 03.納入先コード01
    iv_inv_code_02 IN           VARCHAR2,     -- 04.納入先コード02
    iv_inv_code_03 IN           VARCHAR2,     -- 05.納入先コード03
    iv_inv_code_04 IN           VARCHAR2,     -- 06.納入先コード04
    iv_inv_code_05 IN           VARCHAR2,     -- 07.納入先コード05
    iv_inv_code_06 IN           VARCHAR2,     -- 08.納入先コード06
    iv_inv_code_07 IN           VARCHAR2,     -- 09.納入先コード07
    iv_inv_code_08 IN           VARCHAR2,     -- 10.納入先コード08
    iv_inv_code_09 IN           VARCHAR2,     -- 11.納入先コード09
    iv_inv_code_10 IN           VARCHAR2,     -- 12.納入先コード10
    iv_vendor_id   IN           VARCHAR2,     -- 13.取引先コード
-- 2008/07/14 1.3 UPDATE End
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_mast_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_cnt            NUMBER;
    mst_rec           masters_rec;
--
    -- *** ローカル・カーソル ***
    CURSOR mst_data_cur
    IS
      SELECT pha.segment1 as po_header_number              -- 発注番号
            ,pha.attribute4                                -- 納入日
            ,pha.attribute5                                -- 納入先コード
            ,pla.line_num                                  -- 明細番号
            ,pla.attribute1 as lot_no                      -- ロットNo
            ,pla.attribute11                               -- 発注数量
            ,pla.attribute10                               -- 発注単位
-- 2010/01/19 v1.7 T.Yoshimoto Add Start 本稼動#1175
            --,pla.attribute15                               -- 明細摘要
            ,pha.attribute15                               -- ヘッダ摘要
-- 2010/01/19 v1.7 T.Yoshimoto Add End 本稼動#1175
            ,xiv.item_no                                   -- 品目コード
            ,xiv.item_short_name                           -- 略称(品名称)
            ,ilm.attribute1                                -- 製造年月日
-- 2008/07/14 1.3 ADD Start
            ,ilm.attribute3                                -- 賞味期限
-- 2008/07/14 1.3 ADD End
            ,ilm.attribute2                                -- 固有記号
            ,xvv.segment1                                  -- 仕入先番号
            ,xvv.vendor_short_name                         -- 略称(取引先名)
            ,xilv.description                              -- 摘要(納入先名)
-- 2009/01/26 v1.6 ADD START
            ,xiv.num_of_cases                              -- ケース入数
            ,xiv.conv_unit                                 -- 入出庫換算単位
            ,xicv.prod_class_code                          -- 商品区分
            ,xicv.item_class_code                          -- 品目区分
-- 2009/01/26 v1.6 ADD END
      FROM   po_headers_all pha                  -- 発注ヘッダ
            ,po_lines_all pla                    -- 発注明細
            ,xxcmn_item_mst_v xiv                -- OPM品目情報VIEW
            ,ic_lots_mst ilm                     -- OPMロットマスタ
            ,xxcmn_vendors_v xvv                 -- 仕入先情報VIEW
            ,xxcmn_item_locations_v xilv         -- OPM保管場所情報VIEW
-- 2009/01/26 ADD START
            ,xxcmn_item_categories5_v xicv
-- 2009/01/26 ADD END
      WHERE  pha.po_header_id = pla.po_header_id
      AND    pla.item_id      = xiv.inventory_item_id
      AND    pla.attribute1   = ilm.lot_no
      AND    xiv.item_id      = ilm.item_id
      AND    pha.vendor_id    = xvv.vendor_id
      AND    pha.attribute5   = xilv.segment1
      AND   ((iv_vendor_id IS NULL)
      OR     (xvv.segment1    = iv_vendor_id))
-- 2008/07/14 1.3 UPDATE Start
--      AND    pha.attribute5   = iv_inv_code
      AND    pha.attribute5   IN (iv_inv_code_01,
                                  iv_inv_code_02,
                                  iv_inv_code_03,
                                  iv_inv_code_04,
                                  iv_inv_code_05,
                                  iv_inv_code_06,
                                  iv_inv_code_07,
                                  iv_inv_code_08,
                                  iv_inv_code_09,
                                  iv_inv_code_10)
-- 2008/07/14 1.3 UPDATE End
      AND    pha.attribute4   >= iv_from_date
      AND    pha.attribute4   <= iv_to_date
      AND    pha.attribute1   >= gv_status_po_zumi                   -- 発注作成済:20
      AND    pha.attribute1   < gv_status_money_zumi                 -- 金額確定済:35
-- 2009/01/26 v1.6 ADD START
      AND    xiv.item_id      = xicv.item_id
-- 2009/01/26 v1.6 ADD END
      AND   NOT EXISTS (
        SELECT plav.po_header_id
        FROM   po_lines_all plav                 -- 発注明細
              ,xxcmn_item_mst_v xiv              -- OPM品目情報VIEW
              ,xxcmn_item_categories3_v xic      -- OPM品目カテゴリVIEW3
        WHERE  plav.po_header_id = pla.po_header_id
        AND    plav.item_id      = xiv.inventory_item_id
        AND    xiv.item_id       = xic.item_id
/* 2008/09/01 Mod ↓
-- 2008/05/23 v1.2 Add
        AND    plav.cancel_flag  = 'N'
-- 2008/05/23 v1.2 Add
2008/09/01 Mod ↑ */
        AND    NVL(xic.item_class_code,'0') <> gv_class_code_seihin  -- 製品:5
      )
-- 2010/01/19 v1.7 T.Yoshimoto Add Start 本稼動#1175
        AND    xiv.ship_class               = gv_ship_class_1        -- 出荷可:1
-- 2010/01/19 v1.7 T.Yoshimoto Add End 本稼動#1175
-- 2008/09/01 Add ↓
      AND    pla.cancel_flag  = 'N'
-- 2008/09/01 Add ↑
      ORDER BY pha.segment1,pla.line_num;
--
    -- *** ローカル・レコード ***
    lr_mst_data_rec mst_data_cur%ROWTYPE;
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
    ln_cnt := 0;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      mst_rec.po_header_number  := lr_mst_data_rec.po_header_number;
      mst_rec.attribute4        := lr_mst_data_rec.attribute4;
      mst_rec.attribute5        := lr_mst_data_rec.attribute5;
      mst_rec.line_num          := lr_mst_data_rec.line_num;
      mst_rec.lot_no            := lr_mst_data_rec.lot_no;
      mst_rec.attribute11       := lr_mst_data_rec.attribute11;
      mst_rec.attribute10       := lr_mst_data_rec.attribute10;
      mst_rec.attribute15       := lr_mst_data_rec.attribute15;
      mst_rec.item_no           := lr_mst_data_rec.item_no;
      mst_rec.item_short_name   := lr_mst_data_rec.item_short_name;
      mst_rec.attribute1        := lr_mst_data_rec.attribute1;
-- 2008/07/14 1.3 ADD Start
      mst_rec.attribute3        := lr_mst_data_rec.attribute3;
-- 2008/07/14 1.3 ADD End
      mst_rec.attribute2        := lr_mst_data_rec.attribute2;
      mst_rec.segment1          := lr_mst_data_rec.segment1;
      mst_rec.vendor_short_name := lr_mst_data_rec.vendor_short_name;
      mst_rec.description       := lr_mst_data_rec.description;
-- 2009/01/26 v1.6 ADD START
      mst_rec.num_of_cases      := lr_mst_data_rec.num_of_cases;
      mst_rec.conv_unit         := lr_mst_data_rec.conv_unit;
      mst_rec.prod_class_code   := lr_mst_data_rec.prod_class_code;
      mst_rec.item_class_code   := lr_mst_data_rec.item_class_code;
-- 2009/01/26 v1.6 ADD END
--
      gt_master_tbl(ln_cnt)     := mst_rec;
--
      ln_cnt := ln_cnt + 1;
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_mast_data;
--
  /***********************************************************************************
   * Procedure Name   : create_csv_file
   * Description      : 受入予定情報出力(E-4)
   ***********************************************************************************/
  PROCEDURE create_csv_file(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'create_csv_file';           -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_sep_com      CONSTANT VARCHAR2(1)  := ',';
-- 2009/01/26 v1.6 ADD START
    cv_leaf         CONSTANT VARCHAR2(1)  := '1';
    cv_prod         CONSTANT VARCHAR2(1)  := '5';
    cv_case         CONSTANT VARCHAR2(2)  := 'CS';
-- 2009/01/26 v1.6 ADD END
--
    -- *** ローカル変数 ***
    mst_rec         masters_rec;
    lv_data         VARCHAR2(5000);
    lf_file_hand    UTL_FILE.FILE_TYPE;         -- ファイル・ハンドルの宣言
--
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
--
-- 2009/01/26 v1.6 ADD START
    lv_qty          VARCHAR2(150);
    lv_unit         VARCHAR2(240);
-- 2009/01/26 v1.6 ADD END
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
    -- ファイル存在チェック
    UTL_FILE.FGETATTR(gv_rcv_sch_out_dir,
                      gv_rcv_sch_file_name,
                      lb_retcd,
                      ln_file_size,
                      ln_block_size);
--
    -- ファイル存在
    IF (lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_02);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    BEGIN
--
      -- ファイルオープン
      lf_file_hand := UTL_FILE.FOPEN(gv_rcv_sch_out_dir,
                                     gv_rcv_sch_file_name,
                                     'w');
--
      -- データあり
      IF (gt_master_tbl.COUNT > 0) THEN
--
        <<file_put_loop>>
        FOR i IN 0..gt_master_tbl.COUNT-1 LOOP
          mst_rec := gt_master_tbl(i);
--
-- 2009/01/26 v1.6 ADD START
         -- 入出庫換算単位が'CS'、かつ
         -- リーフ製品の場合、かつ
         -- ケース入り数が1以上の場合
         IF (
              (mst_rec.conv_unit = cv_case)
                AND(mst_rec.prod_class_code = cv_leaf)
                  AND (mst_rec.item_class_code = cv_prod)
                    AND (mst_rec.num_of_cases > 0)
            ) THEN
           lv_qty  := mst_rec.attribute11 / mst_rec.num_of_cases;
           lv_unit := mst_rec.conv_unit;
         ELSE
           lv_qty  := mst_rec.attribute11;
           lv_unit := mst_rec.attribute10;
         END IF;
--
-- 2009/01/26 v1.6 ADD END
          -- データ作成
          lv_data := mst_rec.po_header_number  || cv_sep_com ||        -- 発注番号
-- 2008/07/14 1.3 UPDATE Start
--                     mst_rec.segment1          || cv_sep_com ||        -- 仕入先番号
                     REPLACE(mst_rec.segment1, cv_sep_com)
                                               || cv_sep_com ||        -- 仕入先番号
--                     mst_rec.vendor_short_name || cv_sep_com ||        -- 略称(取引先名)
                     REPLACE(mst_rec.vendor_short_name, cv_sep_com)
                                               || cv_sep_com ||        -- 略称(取引先名)
-- 2008/07/14 1.3 UPDATE End
                     mst_rec.attribute4        || cv_sep_com ||        -- 納入日
                     mst_rec.attribute5        || cv_sep_com ||        -- 納入先コード
-- 2008/07/14 1.3 UPDATE Start
--                     mst_rec.description       || cv_sep_com ||        -- 摘要(納入先名)
                     REPLACE(mst_rec.description, cv_sep_com)
                                               || cv_sep_com ||        -- 摘要(納入先名)
-- 2008/07/14 1.3 UPDATE End
                     mst_rec.line_num          || cv_sep_com ||        -- 明細番号
                     mst_rec.item_no           || cv_sep_com ||        -- 品目
-- 2008/07/14 1.3 UPDATE Start
--                     mst_rec.item_short_name   || cv_sep_com ||        -- 略称(品名称)
                     REPLACE(mst_rec.item_short_name, cv_sep_com)
                                               || cv_sep_com ||        -- 略称(品名称)
-- 2008/07/14 1.3 UPDATE End
                     mst_rec.lot_no            || cv_sep_com ||        -- ロットNo
                     mst_rec.attribute1        || cv_sep_com ||        -- 製造年月日
-- 2008/07/14 1.3 ADD Start
                     mst_rec.attribute3        || cv_sep_com ||        -- 賞味期限
-- 2008/07/14 1.3 ADD End
                     mst_rec.attribute2        || cv_sep_com ||        -- 固有記号
-- 2009/01/26 v1.6 UPDATE START
--                     mst_rec.attribute11       || cv_sep_com ||        -- 発注数量
--                     mst_rec.attribute10       || cv_sep_com ||        -- 発注単位
                     lv_qty                    || cv_sep_com ||        -- 発注数量
                     lv_unit                   || cv_sep_com ||        -- 発注単位
-- 2009/01/26 v1.6 UPDATE END
-- 2008/07/14 1.3 UPDATE Start
--                     mst_rec.attribute15;                              -- 明細摘要
                     REPLACE(mst_rec.attribute15, cv_sep_com);         -- 明細摘要
-- 2008/07/14 1.3 UPDATE End
--
          -- データ出力
          UTL_FILE.PUT_LINE(lf_file_hand,lv_data);
        END LOOP file_put_loop;
--
      -- データなし
      ELSE
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_05);
        lv_errbuf := lv_errmsg;
-- mod start 1.5
--        RAISE global_api_expt;
        RAISE warning_expt;
-- mod end 1.5
      END IF;
--
      -- ファイルクローズ
      UTL_FILE.FCLOSE(lf_file_hand);
--
    EXCEPTION
--
      WHEN UTL_FILE.INVALID_PATH OR         -- ファイルパス不正エラー
           UTL_FILE.INVALID_FILENAME OR     -- ファイル名不正エラー
           UTL_FILE.ACCESS_DENIED OR        -- ファイルアクセス権限エラー
           UTL_FILE.WRITE_ERROR THEN        -- 書き込みエラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_04,
                                              gv_tkn_path,
                                              gv_rcv_sch_out_dir);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
-- add start 1.5
    WHEN warning_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
-- add end 1.5
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END create_csv_file;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : 処理結果レポート出力(E-5)
   ***********************************************************************************/
  PROCEDURE disp_report(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'disp_report';           -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_count       NUMBER;
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
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    ln_count := gt_master_tbl.COUNT;
--
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_31e_10,
                                          gv_tkn_count,
                                          TO_CHAR(ln_count));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END disp_report;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_from_date  IN            VARCHAR2,     -- 1.納入日(FROM)
    iv_to_date    IN            VARCHAR2,     -- 2.納入日(TO)
-- 2008/07/14 1.3 UPDATE Start
--    iv_inv_code   IN            VARCHAR2,     -- 3.納入先コード
--    iv_vendor_id  IN            VARCHAR2,     -- 4.取引先コード
    iv_inv_code_01 IN           VARCHAR2,     -- 03.納入先コード01
    iv_inv_code_02 IN           VARCHAR2,     -- 04.納入先コード02
    iv_inv_code_03 IN           VARCHAR2,     -- 05.納入先コード03
    iv_inv_code_04 IN           VARCHAR2,     -- 06.納入先コード04
    iv_inv_code_05 IN           VARCHAR2,     -- 07.納入先コード05
    iv_inv_code_06 IN           VARCHAR2,     -- 08.納入先コード06
    iv_inv_code_07 IN           VARCHAR2,     -- 09.納入先コード07
    iv_inv_code_08 IN           VARCHAR2,     -- 10.納入先コード08
    iv_inv_code_09 IN           VARCHAR2,     -- 11.納入先コード09
    iv_inv_code_10 IN           VARCHAR2,     -- 12.納入先コード10
    iv_vendor_id   IN           VARCHAR2,     -- 13.取引先コード
-- 2008/07/14 1.3 UPDATE End
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- ================================
    -- E-1.前処理
    -- ================================
    init_proc(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- E-2.パラメータチェック
    -- ================================
    parameter_check(
      iv_from_date,       -- 1.納入日(FROM)
      iv_to_date,         -- 2.納入日(TO)
-- 2008/07/14 1.3 UPDATE Start
--      iv_inv_code,          -- 3.納入先コード
--      iv_vendor_id,         -- 4.取引先コード
      iv_inv_code_01,       -- 03.納入先コード01
      iv_inv_code_02,       -- 04.納入先コード02
      iv_inv_code_03,       -- 05.納入先コード03
      iv_inv_code_04,       -- 06.納入先コード04
      iv_inv_code_05,       -- 07.納入先コード05
      iv_inv_code_06,       -- 08.納入先コード06
      iv_inv_code_07,       -- 09.納入先コード07
      iv_inv_code_08,       -- 10.納入先コード08
      iv_inv_code_09,       -- 11.納入先コード09
      iv_inv_code_10,       -- 12.納入先コード10
      iv_vendor_id,         -- 13.取引先コード
-- 2008/07/14 1.3 UPDATE End
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- E-3.発注情報取得
    -- ================================
    get_mast_data(
      iv_from_date,       -- 1.納入日(FROM)
      iv_to_date,         -- 2.納入日(TO)
-- 2008/07/14 1.3 UPDATE Start
--      iv_inv_code,          -- 3.納入先コード
--      iv_vendor_id,         -- 4.取引先コード
      iv_inv_code_01,       -- 03.納入先コード01
      iv_inv_code_02,       -- 04.納入先コード02
      iv_inv_code_03,       -- 05.納入先コード03
      iv_inv_code_04,       -- 06.納入先コード04
      iv_inv_code_05,       -- 07.納入先コード05
      iv_inv_code_06,       -- 08.納入先コード06
      iv_inv_code_07,       -- 09.納入先コード07
      iv_inv_code_08,       -- 10.納入先コード08
      iv_inv_code_09,       -- 11.納入先コード09
      iv_inv_code_10,       -- 12.納入先コード10
      iv_vendor_id,         -- 13.取引先コード
-- 2008/07/14 1.3 UPDATE End
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- E-4.受入予定情報出力
    -- ================================
    create_csv_file(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
-- add start 1.5
    ELSIF (lv_retcode = gv_status_warn) THEN
      RAISE warning_expt;
-- add end 1.5
    END IF;
--
    -- ================================
    -- E-5.件数出力
    -- ================================
    disp_report(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
-- add start 1.5
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
-- add end 1.5
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
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
    errbuf           OUT NOCOPY VARCHAR2,         --   エラーメッセージ #固定#
    retcode          OUT NOCOPY VARCHAR2,         --   エラーコード     #固定#
    iv_from_date  IN            VARCHAR2,         -- 1.納入日(FROM)
    iv_to_date    IN            VARCHAR2,         -- 2.納入日(TO)
-- 2008/07/14 1.3 UPDATE Start
--    iv_inv_code   IN            VARCHAR2,         -- 3.納入先コード
--    iv_vendor_id  IN            VARCHAR2)         -- 4.取引先コード
    iv_inv_code_01 IN           VARCHAR2,         -- 03.納入先コード01
    iv_inv_code_02 IN           VARCHAR2,         -- 04.納入先コード02
    iv_inv_code_03 IN           VARCHAR2,         -- 05.納入先コード03
    iv_inv_code_04 IN           VARCHAR2,         -- 06.納入先コード04
    iv_inv_code_05 IN           VARCHAR2,         -- 07.納入先コード05
    iv_inv_code_06 IN           VARCHAR2,         -- 08.納入先コード06
    iv_inv_code_07 IN           VARCHAR2,         -- 09.納入先コード07
    iv_inv_code_08 IN           VARCHAR2,         -- 10.納入先コード08
    iv_inv_code_09 IN           VARCHAR2,         -- 11.納入先コード09
    iv_inv_code_10 IN           VARCHAR2,         -- 12.納入先コード10
    iv_vendor_id   IN           VARCHAR2)         -- 13.取引先コード
-- 2008/07/14 1.3 UPDATE End
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME',
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
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
      iv_from_date,         -- 1.納入日(FROM)
      iv_to_date,           -- 2.納入日(TO)
-- 2008/07/14 1.3 UPDATE Start
--      iv_inv_code,          -- 3.納入先コード
--      iv_vendor_id,         -- 4.取引先コード
      iv_inv_code_01,       -- 03.納入先コード01
      iv_inv_code_02,       -- 04.納入先コード02
      iv_inv_code_03,       -- 05.納入先コード03
      iv_inv_code_04,       -- 06.納入先コード04
      iv_inv_code_05,       -- 07.納入先コード05
      iv_inv_code_06,       -- 08.納入先コード06
      iv_inv_code_07,       -- 09.納入先コード07
      iv_inv_code_08,       -- 10.納入先コード08
      iv_inv_code_09,       -- 11.納入先コード09
      iv_inv_code_10,       -- 12.納入先コード10
      iv_vendor_id,         -- 13.取引先コード
-- 2008/07/14 1.3 UPDATE End
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
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
-- add start 1.5
    ELSIF (lv_retcode = gv_status_warn) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.5
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
/*
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
*/
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
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxpo310002c;
/
