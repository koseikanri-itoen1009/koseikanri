CREATE OR REPLACE PACKAGE BODY xxwip730003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip730003c(body)
 * Description      : 運賃アドオンインタフェース取込処理
 * MD.050           : 運賃計算（トランザクション）       T_MD050_BPO_732
 * MD.070           : 運賃アドオンインタフェース取込処理 T_MD070_BPO_73E
 * Version          : 1.8
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_related_date       関連データ取得(E-1)
 *  get_lock               ロック取得(E-2)
 *  get_deliv_if_date      運賃アドオンインタフェースデータ取得(E-3)
 *  chk_object             更新対象チェック(E-4)
 *  get_deliv_cal_date     運賃計算用データ取得(E-5)
 *  set_date               データ設定(E-6)
 *  upd_deliv_head         運賃ヘッダーアドオン更新(E-7)
 *  del_deliv_head         運賃ヘッダーアドオン削除(E-8)
 *  del_deliv_if           運賃アドオンインタフェース削除(E-9)
 *  out_message            メッセージ出力(E-10)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/07    1.0  Oracle 和田 大輝  初回作成
 *  2008/05/13    1.1  Oracle 椎名 昭圭  内部変更要求#85対応
 *  2008/05/26    1.2  Oracle 野村 正幸  結合障害 
 *  2008/07/10    1.3  Oracle 野村 正幸  ST障害 #432 対応
 *  2008/07/25    1.4  Oracle 野村 正幸  ST障害 #473 対応
 *  2008/09/16    1.5  Oracle 吉田 夏樹  T_S_570 対応
 *  2008/12/01    1.6  Oracle 野村 正幸  本番#303対応
 *  2009/03/03    1.7  野村 正幸         本番#1239対応
 *  2016/06/24    1.8  S.Niki            E_本稼動_13659対応
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
  gn_normal_cnt    NUMBER;                    -- 更新件数
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
--
    lock_expt                  EXCEPTION;  -- ロック取得例外
--
    PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(100) := 'xxwip730003c'; -- パッケージ名
--
  -- アプリケーション短縮名
  gv_wip_msg_kbn          CONSTANT VARCHAR2(5) := 'XXWIP';
--
  -- メッセージ番号(XXWIP)
  gv_wip_msg_73e_005      CONSTANT VARCHAR2(15) := 'APP-XXWIP-10067'; -- プロファイル取得エラー
  gv_wip_msg_73e_004      CONSTANT VARCHAR2(15) := 'APP-XXWIP-10004'; -- ロックエラー詳細メッセージ
  gv_wip_msg_73e_306      CONSTANT VARCHAR2(15) := 'APP-XXWIP-30006'; -- 保留期間経過メッセージ
  gv_wip_msg_73e_305      CONSTANT VARCHAR2(15) := 'APP-XXWIP-30005'; -- 配送区分存在なしメッセージ
  gv_wip_msg_73e_304      CONSTANT VARCHAR2(15) := 'APP-XXWIP-30004'; -- 運賃更新不可能メッセージ
--
  -- トークン
  gv_tkn_ng_profile       CONSTANT VARCHAR2(10) := 'NG_PROFILE';
  gv_tkn_table            CONSTANT VARCHAR2(5)  := 'TABLE';
--
  -- トークン値
  gv_reserve_period_name  CONSTANT VARCHAR2(30) := '運賃データ保留期間';
  gv_deliv_if_name        CONSTANT VARCHAR2(30) := '運賃アドオンインタフェース';
  gv_deliv_head_name      CONSTANT VARCHAR2(30) := '運賃ヘッダーアドオン';
--
  -- プロファイル・オプション
  gv_reserve_period    CONSTANT VARCHAR2(20) := 'XXWIP_RESERVE_PERIOD';       -- 運賃データ保留期間
--
  gv_ktg_yes           CONSTANT VARCHAR2(1)   := 'Y';
  gv_ktg_no            CONSTANT VARCHAR2(1)   := 'N';
--
  gv_tbl_n_deliv_if    CONSTANT VARCHAR2(18) := 'XXWIP_DELIVERYS_IF'; -- 運賃アドオンインタフェース
  gv_tbl_n_deliv_head  CONSTANT VARCHAR2(15) := 'XXWIP_DELIVERYS';    -- 運賃ヘッダーアドオン
--
  -- 参照タイプ・コード
  gv_lu_cd_ship_method CONSTANT VARCHAR2(17) := 'XXCMN_SHIP_METHOD';  -- 配送区分
--
  gv_ptn_out           CONSTANT VARCHAR2(1) := '1';                   -- 外部用
  gv_ptn_it            CONSTANT VARCHAR2(1) := '2';                   -- 伊藤園産業用
  -- 支払請求区分
  gv_p_b_cls_pay       CONSTANT VARCHAR2(1) := '1';                   -- 支払
  gv_p_b_cls_bil       CONSTANT VARCHAR2(1) := '2';                   -- 請求
-- ##### Ver.1.8 E_本稼動_13659対応 START #####
  -- ダミー
  gv_dummy             CONSTANT VARCHAR2(1) := 'X';                   -- ダミー
-- ##### Ver.1.8 E_本稼動_13659対応 END   #####
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 運賃アドオンインタフェースに格納するレコード
  TYPE deliv_if_rec IS RECORD(
    delivery_id            xxwip_deliverys_if.delivery_id%TYPE,            -- 1.運賃アドオンID
    pattern_flag           xxwip_deliverys_if.pattern_flag%TYPE,           -- 2.パターン区分
    delivery_company_code  xxwip_deliverys_if.delivery_company_code%TYPE,  -- 3.運送業者
    delivery_no            xxwip_deliverys_if.delivery_no%TYPE,            -- 4.配送No
    invoice_no             xxwip_deliverys_if.invoice_no%TYPE,             -- 5.送り状No
    p_b_classe             xxwip_deliverys_if.p_b_classe%TYPE,             -- 6.支払請求区分
    delivery_classe        xxwip_deliverys_if.delivery_classe%TYPE,        -- 7.配送区分
    charged_amount         xxwip_deliverys_if.charged_amount%TYPE,         -- 8.請求運賃
    qty1                   xxwip_deliverys_if.qty1%TYPE,                   -- 9.個数1
    qty2                   xxwip_deliverys_if.qty2%TYPE,                   -- 10.個数2
    delivery_weight1       xxwip_deliverys_if.delivery_weight1%TYPE,       -- 11.重量1
    delivery_weight2       xxwip_deliverys_if.delivery_weight2%TYPE,       -- 12.重量2
    distance               xxwip_deliverys_if.distance%TYPE,               -- 13.距離
    many_rate              xxwip_deliverys_if.many_rate%TYPE,              -- 14.諸料金
    congestion_charge      xxwip_deliverys_if.congestion_charge%TYPE,      -- 15.通行料
    picking_charge         xxwip_deliverys_if.picking_charge%TYPE,         -- 16.ピッキング料
    consolid_surcharge     xxwip_deliverys_if.consolid_surcharge%TYPE,     -- 17.混載割増金額
    total_amount           xxwip_deliverys_if.total_amount%TYPE,           -- 18.合計
    creation_date          xxwip_deliverys_if.creation_date%TYPE,          -- 19.作成日
    last_update_date       xxwip_deliverys_if.last_update_date%TYPE        -- 20.最終更新日
  );
--
  -- 運賃ヘッダーアドオンに格納するレコード
  TYPE deliv_head_rec IS RECORD(
    deliverys_header_id   xxwip_deliverys.deliverys_header_id%TYPE,     -- 1.運賃ヘッダーアドオンID
    delivery_company_code xxwip_deliverys.delivery_company_code%TYPE,   -- 2.運送業者
    delivery_no           xxwip_deliverys.delivery_no%TYPE,             -- 3.配送No
-- ##### 20080916 Ver.1.5 T_S_570対応 START #####
    --invoice_no            xxwip_deliverys.invoice_no%TYPE,              -- 4.送り状No
    invoice_no2           xxwip_deliverys.invoice_no2%TYPE,              -- 4.送り状No2
-- ##### 20080916 Ver.1.5 T_S_570対応 END #####
    p_b_classe            xxwip_deliverys.p_b_classe%TYPE,              -- 5.支払請求区分
    report_date           xxwip_deliverys.report_date%TYPE,             -- 6.報告日
    judgement_date        xxwip_deliverys.judgement_date%TYPE,          -- 7.判断日
    goods_classe          xxwip_deliverys.goods_classe%TYPE,            -- 8.商品区分
    charged_amount        xxwip_deliverys.charged_amount%TYPE,          -- 9.請求運賃
    contract_rate         xxwip_deliverys.contract_rate%TYPE,           --   契約運賃
    balance               xxwip_deliverys.balance%TYPE,                 -- 10.差額
    total_amount          xxwip_deliverys.total_amount%TYPE,            -- 11.合計
    many_rate             xxwip_deliverys.many_rate%TYPE,               -- 12.諸料金
    distance              xxwip_deliverys.distance%TYPE,                -- 13.最長距離
    delivery_classe       xxwip_deliverys.delivery_classe%TYPE,         -- 14.配送区分
    qty1                  xxwip_deliverys.qty1%TYPE,                    -- 15.個数1
    qty2                  xxwip_deliverys.qty2%TYPE,                    -- 16.個数2
    delivery_weight1      xxwip_deliverys.delivery_weight1%TYPE,        -- 17.重量1
    delivery_weight2      xxwip_deliverys.delivery_weight2%TYPE,        -- 18.重量2
    consolid_surcharge    xxwip_deliverys.consolid_surcharge%TYPE,      -- 19.混載割増金額
    congestion_charge     xxwip_deliverys.congestion_charge%TYPE,       -- 20.通行料
    picking_charge        xxwip_deliverys.picking_charge%TYPE,          -- 21.ピッキング料
    consolid_qty          xxwip_deliverys.consolid_qty%TYPE,            -- 22.混載数
    output_flag           xxwip_deliverys.output_flag%TYPE,             -- 23.差異区分
    defined_flag          xxwip_deliverys.defined_flag%TYPE,            -- 24.支払確定区分
    return_flag           xxwip_deliverys.return_flag%TYPE,             -- 25.支払確定戻
    form_update_flag      xxwip_deliverys.form_update_flag%TYPE,        -- 26.画面更新有無区分
    outside_up_count      xxwip_deliverys.outside_up_count%TYPE         -- 27.外部業者変更回数
  );
--
  -- 運賃アドオンマスタに格納するレコード
  gr_deliv_charges        xxwip_common3_pkg.delivery_charges_rec;
--
  -- 運賃用運送業者アドオンマスタに格納するレコード
  TYPE delivery_company IS RECORD(
    pay_picking_amount    xxwip_delivery_company.pay_picking_amount%TYPE,  -- 1.支払ピッキング単価
    bill_picking_amount   xxwip_delivery_company.bill_picking_amount%TYPE  -- 2.請求ピッキング単価
  );
--
  gr_deliv_company        delivery_company;
--
  -- PL/SQL表
  TYPE deliv_if_tbl       IS TABLE OF deliv_if_rec   INDEX BY PLS_INTEGER;
  TYPE deliv_head_tbl     IS TABLE OF deliv_head_rec INDEX BY PLS_INTEGER;
  gt_deliv_if_tbl         deliv_if_tbl;       -- 運賃アドオンインタフェース(取得用)
  gt_deliv_head_tbl       deliv_head_tbl;     -- 運賃ヘッダーアドオン(取得用)
--
--
  -- *******************************************************
  -- * 運賃アドオンインタフェース
  -- *******************************************************
  -- 削除用PL/SQL表型
  -- 運賃アドオンID
  TYPE d_deliv_if_id_type IS TABLE OF xxwip_deliverys_if.delivery_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- パターン区分
  TYPE d_deliv_if_ptn_flg_type IS TABLE OF xxwip_deliverys_if.pattern_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- 運送業者
  TYPE d_deliv_if_com_cd_type IS TABLE OF xxwip_deliverys_if.delivery_company_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 配送No
  TYPE d_deliv_if_no_type IS TABLE OF xxwip_deliverys_if.delivery_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- 送り状No
  TYPE d_deliv_if_invoice_no_type IS TABLE OF xxwip_deliverys_if.invoice_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- 支払請求区分
  TYPE d_deliv_if_p_b_cls_type IS TABLE OF xxwip_deliverys_if.p_b_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 配送区分
  TYPE d_deliv_if_deliv_cls_type IS TABLE OF xxwip_deliverys_if.delivery_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 請求運賃
  TYPE d_deliv_if_chrg_amt_type IS TABLE OF xxwip_deliverys_if.charged_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- 個数1
  TYPE d_deliv_if_qty1_type IS TABLE OF xxwip_deliverys_if.qty1%TYPE
  INDEX BY BINARY_INTEGER;
  -- 個数2
  TYPE d_deliv_if_qty2_type IS TABLE OF xxwip_deliverys_if.qty2%TYPE
  INDEX BY BINARY_INTEGER;
  -- 重量1
  TYPE d_deliv_if_deliv_wht1_type IS TABLE OF xxwip_deliverys_if.delivery_weight1%TYPE
  INDEX BY BINARY_INTEGER;
  -- 重量2
  TYPE d_deliv_if_deliv_wht2_type IS TABLE OF xxwip_deliverys_if.delivery_weight2%TYPE
  INDEX BY BINARY_INTEGER;
  -- 距離
  TYPE d_deliv_if_distance_type IS TABLE OF xxwip_deliverys_if.distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- 諸料金
  TYPE d_deliv_if_many_rt_type IS TABLE OF xxwip_deliverys_if.many_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- 通行料
  TYPE d_deliv_if_cng_chrg_type IS TABLE OF xxwip_deliverys_if.congestion_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- ピッキング料
  TYPE d_deliv_if_pic_chrg_type IS TABLE OF xxwip_deliverys_if.picking_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- 混載割増金額
  TYPE d_deliv_if_cns_srchrg_type IS TABLE OF xxwip_deliverys_if.consolid_surcharge%TYPE
  INDEX BY BINARY_INTEGER;
  -- 合計
  TYPE d_deliv_if_ttl_amt_type IS TABLE OF xxwip_deliverys_if.total_amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  -- 削除用運賃アドオンインタフェースのPL/SQL表
  d_deliv_if_id_tab            d_deliv_if_id_type;           -- 運賃アドオンID
--
  -- 配送区分チェック用PL/SQL表
  d_deliv_cls_id_tab           d_deliv_if_id_type;           -- 運賃アドオンID
  d_deliv_cls_ptn_flg_tab      d_deliv_if_ptn_flg_type;      -- パターン区分
  d_deliv_cls_com_cd_tab       d_deliv_if_com_cd_type;       -- 運送業者
  d_deliv_cls_no_tab           d_deliv_if_no_type;           -- 配送No
  d_deliv_cls_invoice_no_tab   d_deliv_if_invoice_no_type;   -- 送り状No
  d_deliv_cls_p_b_cls_tab      d_deliv_if_p_b_cls_type;      -- 支払請求区分
  d_deliv_cls_deliv_cls_tab    d_deliv_if_deliv_cls_type;    -- 配送区分
  d_deliv_cls_chrg_amt_tab     d_deliv_if_chrg_amt_type;     -- 請求運賃
  d_deliv_cls_qty1_tab         d_deliv_if_qty1_type;         -- 個数1
  d_deliv_cls_qty2_tab         d_deliv_if_qty2_type;         -- 個数2
  d_deliv_cls_deliv_wht1_tab   d_deliv_if_deliv_wht1_type;   -- 重量1
  d_deliv_cls_deliv_wht2_tab   d_deliv_if_deliv_wht2_type;   -- 重量2
  d_deliv_cls_distance_tab     d_deliv_if_distance_type;     -- 距離
  d_deliv_cls_many_rt_tab      d_deliv_if_many_rt_type;      -- 諸料金
  d_deliv_cls_cng_chrg_tab     d_deliv_if_cng_chrg_type;     -- 通行料
  d_deliv_cls_pic_chrg_tab     d_deliv_if_pic_chrg_type;     -- ピッキング料
  d_deliv_cls_cns_srchrg_tab   d_deliv_if_cns_srchrg_type;   -- 混載割増金額
  d_deliv_cls_ttl_amt_tab      d_deliv_if_ttl_amt_type;      -- 合計
--
  -- 保留期間経過チェック用PL/SQL表
  d_rsv_prd_id_tab           d_deliv_if_id_type;           -- 運賃アドオンID
  d_rsv_prd_ptn_flg_tab      d_deliv_if_ptn_flg_type;      -- パターン区分
  d_rsv_prd_com_cd_tab       d_deliv_if_com_cd_type;       -- 運送業者
  d_rsv_prd_no_tab           d_deliv_if_no_type;           -- 配送No
  d_rsv_prd_invoice_no_tab   d_deliv_if_invoice_no_type;   -- 送り状No
  d_rsv_prd_p_b_cls_tab      d_deliv_if_p_b_cls_type;      -- 支払請求区分
  d_rsv_prd_deliv_cls_tab    d_deliv_if_deliv_cls_type;    -- 配送区分
  d_rsv_prd_chrg_amt_tab     d_deliv_if_chrg_amt_type;     -- 請求運賃
  d_rsv_prd_qty1_tab         d_deliv_if_qty1_type;         -- 個数1
  d_rsv_prd_qty2_tab         d_deliv_if_qty2_type;         -- 個数2
  d_rsv_prd_deliv_wht1_tab   d_deliv_if_deliv_wht1_type;   -- 重量1
  d_rsv_prd_deliv_wht2_tab   d_deliv_if_deliv_wht2_type;   -- 重量2
  d_rsv_prd_distance_tab     d_deliv_if_distance_type;     -- 距離
  d_rsv_prd_many_rt_tab      d_deliv_if_many_rt_type;      -- 諸料金
  d_rsv_prd_cng_chrg_tab     d_deliv_if_cng_chrg_type;     -- 通行料
  d_rsv_prd_pic_chrg_tab     d_deliv_if_pic_chrg_type;     -- ピッキング料
  d_rsv_prd_cns_srchrg_tab   d_deliv_if_cns_srchrg_type;   -- 混載割増金額
  d_rsv_prd_ttl_amt_tab      d_deliv_if_ttl_amt_type;      -- 合計
--
  -- 更新不可能用PL/SQL表
  d_not_upd_id_tab           d_deliv_if_id_type;           -- 運賃アドオンID
  d_not_upd_ptn_flg_tab      d_deliv_if_ptn_flg_type;      -- パターン区分
  d_not_upd_com_cd_tab       d_deliv_if_com_cd_type;       -- 運送業者
  d_not_upd_no_tab           d_deliv_if_no_type;           -- 配送No
  d_not_upd_invoice_no_tab   d_deliv_if_invoice_no_type;   -- 送り状No
  d_not_upd_p_b_cls_tab      d_deliv_if_p_b_cls_type;      -- 支払請求区分
  d_not_upd_deliv_cls_tab    d_deliv_if_deliv_cls_type;    -- 配送区分
  d_not_upd_chrg_amt_tab     d_deliv_if_chrg_amt_type;     -- 請求運賃
  d_not_upd_qty1_tab         d_deliv_if_qty1_type;         -- 個数1
  d_not_upd_qty2_tab         d_deliv_if_qty2_type;         -- 個数2
  d_not_upd_deliv_wht1_tab   d_deliv_if_deliv_wht1_type;   -- 重量1
  d_not_upd_deliv_wht2_tab   d_deliv_if_deliv_wht2_type;   -- 重量2
  d_not_upd_distance_tab     d_deliv_if_distance_type;     -- 距離
  d_not_upd_many_rt_tab      d_deliv_if_many_rt_type;      -- 諸料金
  d_not_upd_cng_chrg_tab     d_deliv_if_cng_chrg_type;     -- 通行料
  d_not_upd_pic_chrg_tab     d_deliv_if_pic_chrg_type;     -- ピッキング料
  d_not_upd_cns_srchrg_tab   d_deliv_if_cns_srchrg_type;   -- 混載割増金額
  d_not_upd_ttl_amt_tab      d_deliv_if_ttl_amt_type;      -- 合計
--
  -- *******************************************************
  -- * 運賃ヘッダーアドオン
  -- *******************************************************
  -- 更新用PL/SQL表型
  -- 運送業者
  TYPE u_deliv_head_com_code_id_type IS TABLE OF xxwip_deliverys.delivery_company_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 配送No
  TYPE u_deliv_head_deliv_no_type IS TABLE OF xxwip_deliverys.delivery_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- 送り状No
-- ##### 20080916 Ver.1.5 T_S_570対応 START #####
  --TYPE u_deliv_head_invoice_no_type IS TABLE OF xxwip_deliverys.invoice_no%TYPE
  TYPE u_deliv_head_invoice_no_type IS TABLE OF xxwip_deliverys.invoice_no2%TYPE
-- ##### 20080916 Ver.1.5 T_S_570対応 END #####
  INDEX BY BINARY_INTEGER;
  -- 支払請求区分
  TYPE u_deliv_head_p_b_cls_type IS TABLE OF xxwip_deliverys.p_b_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 報告日
  TYPE u_deliv_head_rpt_date_type IS TABLE OF xxwip_deliverys.report_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 配送区分
  TYPE u_deliv_head_deliv_cls_type IS TABLE OF xxwip_deliverys.delivery_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 請求運賃
  TYPE u_deliv_head_chrg_amt_type IS TABLE OF xxwip_deliverys.charged_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- 契約運賃
  TYPE u_deliv_head_con_rate_type IS TABLE OF xxwip_deliverys.contract_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- 差額
  TYPE u_deliv_head_balance_type IS TABLE OF xxwip_deliverys.balance%TYPE
  INDEX BY BINARY_INTEGER;
  -- 個数1
  TYPE u_deliv_head_qty1_type IS TABLE OF xxwip_deliverys.qty1%TYPE
  INDEX BY BINARY_INTEGER;
  -- 個数2
  TYPE u_deliv_head_qty2_type IS TABLE OF xxwip_deliverys.qty2%TYPE
  INDEX BY BINARY_INTEGER;
  -- 重量1
  TYPE u_deliv_head_deliv_wht1_type IS TABLE OF xxwip_deliverys.delivery_weight1%TYPE
  INDEX BY BINARY_INTEGER;
  -- 重量2
  TYPE u_deliv_head_deliv_wht2_type IS TABLE OF xxwip_deliverys.delivery_weight2%TYPE
  INDEX BY BINARY_INTEGER;
  -- 距離
  TYPE u_deliv_head_dst_type IS TABLE OF xxwip_deliverys.distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- 諸料金
  TYPE u_deliv_head_many_rt_type IS TABLE OF xxwip_deliverys.many_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- 通行料
  TYPE u_deliv_head_cng_chrg_type IS TABLE OF xxwip_deliverys.congestion_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- ピッキング料
  TYPE u_deliv_head_pic_chrg_type IS TABLE OF xxwip_deliverys.picking_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- 混載割増金額
  TYPE u_deliv_head_cns_srchrg_type IS TABLE OF xxwip_deliverys.consolid_surcharge%TYPE
  INDEX BY BINARY_INTEGER;
  -- 合計
  TYPE u_deliv_head_ttl_amt_type IS TABLE OF xxwip_deliverys.total_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- 差異区分
  TYPE u_deliv_head_op_flg_type IS TABLE OF xxwip_deliverys.output_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- 支払確定区分
  TYPE u_deliv_head_dfn_flg_type IS TABLE OF xxwip_deliverys.defined_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- 支払確定戻
  TYPE u_deliv_head_rtrn_flg_type IS TABLE OF xxwip_deliverys.return_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- 画面更新有無区分
  TYPE u_deliv_head_frm_upd_flg_type IS TABLE OF xxwip_deliverys.form_update_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- 外部業者変更回数
  TYPE u_deliv_head_os_up_cnt_type IS TABLE OF xxwip_deliverys.outside_up_count%TYPE
  INDEX BY BINARY_INTEGER;
--
  u_deliv_head_com_code_id_tab   u_deliv_head_com_code_id_type;   -- 運賃業者
  u_deliv_head_deliv_no_tab      u_deliv_head_deliv_no_type;      -- 配送No
  u_deliv_head_invoice_no_tab    u_deliv_head_invoice_no_type;    -- 送り状No2
  u_deliv_head_p_b_cls_tab       u_deliv_head_p_b_cls_type;       -- 支払請求区分
  u_deliv_head_rpt_date_tab      u_deliv_head_rpt_date_type;      -- 報告日
  u_deliv_head_deliv_cls_tab     u_deliv_head_deliv_cls_type;     -- 配送区分
  u_deliv_head_chrg_amt_tab      u_deliv_head_chrg_amt_type;      -- 請求運賃
  u_deliv_head_con_rate_tab      u_deliv_head_con_rate_type;      -- 契約運賃
  u_deliv_head_balance_tab       u_deliv_head_balance_type;       -- 差額
  u_deliv_head_qty1_tab          u_deliv_head_qty1_type;          -- 個数1
  u_deliv_head_qty2_tab          u_deliv_head_qty2_type;          -- 個数2
  u_deliv_head_deliv_wht1_tab    u_deliv_head_deliv_wht1_type;    -- 重量1
  u_deliv_head_deliv_wht2_tab    u_deliv_head_deliv_wht2_type;    -- 重量2
  u_deliv_head_dst_tab           u_deliv_head_dst_type;           -- 距離
  u_deliv_head_many_rt_tab       u_deliv_head_many_rt_type;       -- 諸料金
  u_deliv_head_cng_chrg_tab      u_deliv_head_cng_chrg_type;      -- 通行料
  u_deliv_head_pic_chrg_tab      u_deliv_head_pic_chrg_type;      -- ピッキング料
  u_deliv_head_cns_srchrg_tab    u_deliv_head_cns_srchrg_type;    -- 混載割増金額
  u_deliv_head_ttl_amt_tab       u_deliv_head_ttl_amt_type;       -- 合計
  u_deliv_head_op_flg_tab        u_deliv_head_op_flg_type;        -- 差異区分
  u_deliv_head_dfn_flg_tab       u_deliv_head_dfn_flg_type;       -- 支払確定区分
  u_deliv_head_rtrn_flg_tab      u_deliv_head_rtrn_flg_type;      -- 支払確定戻
  u_deliv_head_frm_upd_flg_tab   u_deliv_head_frm_upd_flg_type;   -- 画面更新有無区分
  u_deliv_head_os_up_cnt_tab     u_deliv_head_os_up_cnt_type;     -- 外部業者変更回数
--
  -- 請求データ削除用PL/SQL表
  -- 配送No
  TYPE d_bil_deliv_no_type IS TABLE OF xxwip_deliverys.delivery_no%TYPE
  INDEX BY BINARY_INTEGER;
  d_bil_deliv_no_tab       d_bil_deliv_no_type;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gd_sysdate               DATE;            -- システム日付
  gn_user_id               NUMBER;          -- ユーザID
  gn_login_id              NUMBER;          -- ログインID
  gn_conc_request_id       NUMBER;          -- コンカレント要求ID
  gn_prog_appl_id          NUMBER;          -- コンカレント・プログラム・アプリケーションID
  gn_conc_program_id       NUMBER;          -- コンカレント・プログラムID
--
  -- プロファイル・オプション
  gn_wip_reserve_period    NUMBER;          -- 運賃データ保留期間
--
  gv_target_type           VARCHAR2(1);     -- 締日区分(Y:締め日前、N:締め日後)
--
  gn_deliv_head_cnt        NUMBER;          -- 運賃ヘッダーアドオン用PL/SQL表カウンター
  gn_upd_deliv_head_cnt    NUMBER;          -- 更新用運賃ヘッダーアドオン用PL/SQL表カウンター
  gn_deliv_cls_cnt         NUMBER;          -- 配送区分チェック用PL/SQL表カウンター
  gn_rsv_prd_cnt           NUMBER;          -- 保留期間経過チェック用PL/SQL表カウンター
  gn_not_upd_cnt           NUMBER;          -- 更新不可能用PL/SQL表カウンター
  gn_bil_deliv_no_cnt      NUMBER;          -- 請求データ削除用PL/SQL表カウンター
  gn_deliv_if_del_cnt      NUMBER;          -- 削除用運賃アドオンインタフェースカウンター
--
-- ##### Ver.1.8 E_本稼動_13659対応 START #####
  gv_prod_div              VARCHAR2(1);     -- 商品区分
-- ##### Ver.1.8 E_本稼動_13659対応 END   #####
--
  /**********************************************************************************
   * Procedure Name   : get_related_date
   * Description      : 関連データ取得(E-1)
   ***********************************************************************************/
  PROCEDURE get_related_date(
-- ##### Ver.1.8 E_本稼動_13659対応 START #####
    iv_prod_div   IN  VARCHAR2,     --   商品区分
-- ##### Ver.1.8 E_本稼動_13659対応 END   #####
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_related_date'; -- プログラム名
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
    lv_orgn_code      sy_orgn_mst.orgn_code%TYPE;   -- 組織
    ln_grace_period   NUMBER;                       -- 運賃計算用猶予期間
    ld_close_date     DATE;                         -- クローズ日付
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
    gd_sysdate          := SYSDATE;                    -- システム日時
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- ログインID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- コンカレント要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- コンカレント・プログラムID
--
-- ##### Ver.1.8 E_本稼動_13659対応 START #####
    -- 入力項目.商品区分をグローバル変数に格納
    gv_prod_div         := iv_prod_div;                -- 商品区分
-- ##### Ver.1.8 E_本稼動_13659対応 END   #####
--
    -- ***********************************************
    -- プロファイル：運賃データ保留期間 取得
    -- ***********************************************
    gn_wip_reserve_period := FND_PROFILE.VALUE(gv_reserve_period);
--
    IF (gn_wip_reserve_period IS NULL) THEN -- プロファイルが取得できない場合はエラー
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                            gv_wip_msg_73e_005,
                                            gv_tkn_ng_profile,
                                            gv_reserve_period_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **********************************************
    -- 締日区分取得
    -- **********************************************
    xxwip_common3_pkg.check_lastmonth_close(
      gv_target_type,   -- 締め日区分
      lv_errbuf,        -- エラー・メッセージ
      lv_retcode,       -- リターン・コード
      lv_errmsg);       -- ユーザー・エラー・メッセージ
    IF (lv_retcode = gv_status_error) THEN -- 締日取得エラーの場合
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
  END get_related_date;
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : ロック取得(E-2)
   ***********************************************************************************/
  PROCEDURE get_lock(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock'; -- プログラム名
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
    -- *********************************************
    -- 運賃ヘッダーアドオンのロック取得
    -- *********************************************
    -- ロック取得失敗の場合
    IF (NOT(xxcmn_common_pkg.get_tbl_lock(
          gv_wip_msg_kbn,        -- スキーマ名
          gv_tbl_n_deliv_head))) -- テーブル名
    THEN
      -- ロックエラー詳細メッセージの出力
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                            gv_wip_msg_73e_004,
                                            gv_tkn_table,
                                            gv_deliv_head_name);
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
  END get_lock;
--
--
  /**********************************************************************************
   * Procedure Name   : get_deliv_if_date
   * Description      : 運賃アドオンインタフェースデータ取得(E-3)
   ***********************************************************************************/
  PROCEDURE get_deliv_if_date(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_if_date'; -- プログラム名
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
    BEGIN
      -- 運賃アドオンインタフェースデータを取得
      SELECT xdi.delivery_id,            -- 1.運賃アドオンID
             xdi.pattern_flag,           -- 2.パターン区分
             xdi.delivery_company_code,  -- 3.運送業者
             xdi.delivery_no,            -- 4.配送No
             xdi.invoice_no,             -- 5.送り状No
             xdi.p_b_classe,             -- 6.支払請求区分
             xdi.delivery_classe,        -- 7.配送区分
             xdi.charged_amount,         -- 8.請求運賃
             xdi.qty1,                   -- 9.個数1
             xdi.qty2,                   -- 10.個数2
             xdi.delivery_weight1,       -- 11.重量1
             xdi.delivery_weight2,       -- 12.重量2
             xdi.distance,               -- 13.距離
             xdi.many_rate,              -- 14.諸料金
             xdi.congestion_charge,      -- 15.通行料
             xdi.picking_charge,         -- 16.ピッキング料
             xdi.consolid_surcharge,     -- 17.混載割増金額
             xdi.total_amount,           -- 18.合計
             xdi.creation_date,          -- 19.作成日
             xdi.last_update_date        -- 20.最終更新日
      BULK COLLECT INTO gt_deliv_if_tbl
      FROM    xxwip_deliverys_if xdi     -- 運賃アドオンインタフェース
-- ##### Ver.1.8 E_本稼動_13659対応 START #####
      WHERE  EXISTS (SELECT /*+ INDEX(xd XXWIP_DELIVERYS_N01) */
                            gv_dummy
                     FROM   xxwip_deliverys  xd    -- 運賃ヘッダアドオン
                     WHERE  xdi.delivery_company_code = xd.delivery_company_code   -- 運送業者
                     AND    xdi.delivery_no           = xd.delivery_no             -- 配送No
                     AND    xdi.p_b_classe            = xd.p_b_classe              -- 支払請求区分
                     AND    xd.goods_classe           = gv_prod_div                -- 商品区分
             )
         OR  NOT EXISTS (SELECT /*+ INDEX(xd2 XXWIP_DELIVERYS_N01) */
                                gv_dummy
                         FROM   xxwip_deliverys  xd2    -- 運賃ヘッダアドオン
                         WHERE  xdi.delivery_company_code = xd2.delivery_company_code   -- 運送業者
                         AND    xdi.delivery_no           = xd2.delivery_no             -- 配送No
                         AND    xdi.p_b_classe            = xd2.p_b_classe              -- 支払請求区分
             )
-- ##### Ver.1.8 E_本稼動_13659対応 END   #####
      ORDER BY xdi.delivery_id
      FOR UPDATE NOWAIT;
--
    EXCEPTION
      WHEN lock_expt THEN 
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                              gv_wip_msg_73e_004,
                                              gv_tkn_table,
                                              gv_deliv_if_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    -- 対象データがない場合
    IF (gt_deliv_if_tbl.COUNT = 0) THEN
      -- リターン・コードに警告を設定
      ov_retcode := gv_status_warn;
      -- 処理をスキップ
      RETURN;
    ELSE
      -- 対象件数の格納
      gn_target_cnt := gt_deliv_if_tbl.COUNT;
    END IF;
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
  END get_deliv_if_date;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_object
   * Description      : 更新対象チェック(E-4)
   ***********************************************************************************/
  PROCEDURE chk_object(
    ir_deliv_if_rec IN  deliv_if_rec, --   運賃アドオンインタフェースレコード
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_object'; -- プログラム名
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
    ln_count               NUMBER;        -- 存在チェック用カウンター
--
    lv_head_date_flg       VARCHAR2(1);   -- 運賃ヘッダーアドオンデータ存在フラグ(Y:有り、N:無し)
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
    -- パターン区分 = 「伊藤園産業」且つ、支払請求区分 = 「支払」
    -- 配送区分がNULL以外の場合、チェック処理を行う
    IF ((ir_deliv_if_rec.delivery_classe IS NOT NULL)
      AND (ir_deliv_if_rec.pattern_flag = gv_ptn_it)
      AND (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
--
      -- ************************************************
      -- 配送区分存在チェック
      -- ************************************************
      SELECT COUNT(xlvv.meaning)         -- 内容
      INTO   ln_count
      FROM   xxcmn_lookup_values_v xlvv -- クイックコード情報VIEW
      WHERE  xlvv.lookup_type = gv_lu_cd_ship_method
      AND    xlvv.lookup_code = ir_deliv_if_rec.delivery_classe
      AND    ROWNUM = 1;
--
      -- 存在しない場合
      IF (ln_count < 1) THEN
        -- 削除用運賃アドオンインタフェースカウンターのカウントアップ
        gn_deliv_if_del_cnt := gn_deliv_if_del_cnt + 1;
        -- エラー件数のカウントアップ
        gn_error_cnt := gn_error_cnt + 1;
--
        -- 削除用運賃アドオンインタフェースに格納
        d_deliv_if_id_tab(gn_deliv_if_del_cnt) := ir_deliv_if_rec.delivery_id;
--
        -- 配送区分チェック用PL/SQL表用カウンターのカウントアップ
        gn_deliv_cls_cnt := gn_deliv_cls_cnt + 1;
--
        -- 配送区分チェック用PL/SQL表に格納
        -- 運賃アドオンID
        d_deliv_cls_id_tab(gn_deliv_cls_cnt)         := ir_deliv_if_rec.delivery_id;
        -- パターン区分
        d_deliv_cls_ptn_flg_tab(gn_deliv_cls_cnt)    := ir_deliv_if_rec.pattern_flag;
        -- 運送業者
        d_deliv_cls_com_cd_tab(gn_deliv_cls_cnt)     := ir_deliv_if_rec.delivery_company_code;
        -- 配送No
        d_deliv_cls_no_tab(gn_deliv_cls_cnt)         := ir_deliv_if_rec.delivery_no;
        -- 送り状No
        d_deliv_cls_invoice_no_tab(gn_deliv_cls_cnt) := ir_deliv_if_rec.invoice_no;
        -- 支払請求区分
        d_deliv_cls_p_b_cls_tab(gn_deliv_cls_cnt)    := ir_deliv_if_rec.p_b_classe;
        -- 配送区分
        d_deliv_cls_deliv_cls_tab(gn_deliv_cls_cnt)  := ir_deliv_if_rec.delivery_classe;
        -- 請求運賃
        d_deliv_cls_chrg_amt_tab(gn_deliv_cls_cnt)   := ir_deliv_if_rec.charged_amount;
        -- 個数1
        d_deliv_cls_qty1_tab(gn_deliv_cls_cnt)       := ir_deliv_if_rec.qty1;
        -- 個数2
        d_deliv_cls_qty2_tab(gn_deliv_cls_cnt)       := ir_deliv_if_rec.qty2;
        -- 重量1
        d_deliv_cls_deliv_wht1_tab(gn_deliv_cls_cnt) := ir_deliv_if_rec.delivery_weight1;
        -- 重量2
        d_deliv_cls_deliv_wht2_tab(gn_deliv_cls_cnt) := ir_deliv_if_rec.delivery_weight2;
        -- 距離
        d_deliv_cls_distance_tab(gn_deliv_cls_cnt)   := ir_deliv_if_rec.distance;
        -- 諸料金
        d_deliv_cls_many_rt_tab(gn_deliv_cls_cnt)    := ir_deliv_if_rec.many_rate;
        -- 通行料
        d_deliv_cls_cng_chrg_tab(gn_deliv_cls_cnt)   := ir_deliv_if_rec.congestion_charge;
        -- ピッキング料
        d_deliv_cls_pic_chrg_tab(gn_deliv_cls_cnt)   := ir_deliv_if_rec.picking_charge;
        -- 混載割増金額
        d_deliv_cls_cns_srchrg_tab(gn_deliv_cls_cnt) := ir_deliv_if_rec.consolid_surcharge;
        -- 合計
        d_deliv_cls_ttl_amt_tab(gn_deliv_cls_cnt)    := ir_deliv_if_rec.total_amount;
--
        -- リターン・コードに警告を設定
        ov_retcode := gv_status_warn;
--
        -- 処理をスキップ
        RETURN;
--
      END IF;
--
    END IF;
--
    BEGIN
      -- 運賃ヘッダーアドオン用PL/SQL表用カウンターのカウントアップ
      gn_deliv_head_cnt := gn_deliv_head_cnt + 1;
      -- 運賃ヘッダーアドオンデータ存在フラグの初期化(「Y」を設定)
      lv_head_date_flg := gv_ktg_yes;
--
      -- ************************************************
      -- 運賃ヘッダーアドオンデータ抽出処理
      -- ************************************************
      SELECT xd.deliverys_header_id,      -- 1.運賃ヘッダー
             xd.delivery_company_code,    -- 2.運送業者
             xd.delivery_no,              -- 3.配送No
-- ##### 20080916 Ver.1.5 T_S_570対応 START #####
             --xd.invoice_no,               -- 4.送り状No
             xd.invoice_no2,               -- 4.送り状No2
-- ##### 20080916 Ver.1.5 T_S_570対応 END #####
             xd.p_b_classe,               -- 5.支払請求区分
             xd.report_date,              -- 6.報告日
             xd.judgement_date,           -- 7.判断日
             xd.goods_classe,             -- 8.商品区分
             xd.charged_amount,           -- 9.請求運賃
             xd.contract_rate,            -- 10.契約運賃
             xd.balance,                  -- 11.差額
             xd.total_amount,             -- 12.合計
             xd.many_rate,                -- 13.諸料金
             xd.distance,                 -- 14.最長距離
             xd.delivery_classe,          -- 15.配送区分
             xd.qty1,                     -- 16.個数1
             xd.qty2,                     -- 17.個数2
             xd.delivery_weight1,         -- 18.重量1
             xd.delivery_weight2,         -- 19.重量2
             xd.consolid_surcharge,       -- 20.混載割増金額
             xd.congestion_charge,        -- 21.通行料
             xd.picking_charge,           -- 22.ピッキング料
             xd.consolid_qty,             -- 23.混載数
             xd.output_flag,              -- 24.差異区分
             xd.defined_flag,             -- 25.支払確定区分
             xd.return_flag,              -- 26.支払確定戻
             xd.form_update_flag,         -- 27.画面更新有無
             xd.outside_up_count          -- 28.外部業者変更
      INTO   gt_deliv_head_tbl(gn_deliv_head_cnt)
      FROM   xxwip_deliverys xd           -- 運賃ヘッダーアドオン
      WHERE  xd.delivery_company_code = ir_deliv_if_rec.delivery_company_code
      AND    xd.delivery_no           = ir_deliv_if_rec.delivery_no
      AND    xd.p_b_classe            = ir_deliv_if_rec.p_b_classe;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN   -- データなしエラー
        lv_head_date_flg := gv_ktg_no;
--
        -- 運賃ヘッダーアドオン用PL/SQL表用カウンターのカウントアップ
        gn_deliv_head_cnt := gn_deliv_head_cnt - 1;
    END;
--
    -- 運賃ヘッダーアドオンデータが取得できなかった場合(フラグ = 'N')
    IF (lv_head_date_flg = gv_ktg_no) THEN
      -- ************************************************
      -- 保留日数経過チェック
      -- ************************************************
      IF ((gn_wip_reserve_period + TRUNC(ir_deliv_if_rec.last_update_date)) < TRUNC(gd_sysdate))
      THEN
        -- 削除用運賃アドオンインタフェースカウンターのカウントアップ
        gn_deliv_if_del_cnt := gn_deliv_if_del_cnt + 1;
        -- エラー件数のカウントアップ
        gn_error_cnt := gn_error_cnt + 1;
--
        -- 削除用運賃アドオンインタフェースに格納
        d_deliv_if_id_tab(gn_deliv_if_del_cnt) := ir_deliv_if_rec.delivery_id;
--
        -- 保留期間経過チェック用PL/SQL表用カウンターのカウントアップ
        gn_rsv_prd_cnt := gn_rsv_prd_cnt + 1;
--
        -- 保留期間経過チェック用PL/SQL表に格納
        -- 運賃アドオンID
        d_rsv_prd_id_tab(gn_rsv_prd_cnt)         := ir_deliv_if_rec.delivery_id;
        -- パターン区分
        d_rsv_prd_ptn_flg_tab(gn_rsv_prd_cnt)    := ir_deliv_if_rec.pattern_flag;
        -- 運送業者
        d_rsv_prd_com_cd_tab(gn_rsv_prd_cnt)     := ir_deliv_if_rec.delivery_company_code;
        -- 配送No
        d_rsv_prd_no_tab(gn_rsv_prd_cnt)         := ir_deliv_if_rec.delivery_no;
        -- 送り状No
        d_rsv_prd_invoice_no_tab(gn_rsv_prd_cnt) := ir_deliv_if_rec.invoice_no;
        -- 支払請求区分
        d_rsv_prd_p_b_cls_tab(gn_rsv_prd_cnt)    := ir_deliv_if_rec.p_b_classe;
        -- 配送区分
        d_rsv_prd_deliv_cls_tab(gn_rsv_prd_cnt)  := ir_deliv_if_rec.delivery_classe;
        -- 請求運賃
        d_rsv_prd_chrg_amt_tab(gn_rsv_prd_cnt)   := ir_deliv_if_rec.charged_amount;
        -- 個数1
        d_rsv_prd_qty1_tab(gn_rsv_prd_cnt)       := ir_deliv_if_rec.qty1;
        -- 個数2
        d_rsv_prd_qty2_tab(gn_rsv_prd_cnt)       := ir_deliv_if_rec.qty2;
        -- 重量1
        d_rsv_prd_deliv_wht1_tab(gn_rsv_prd_cnt) := ir_deliv_if_rec.delivery_weight1;
        -- 重量2
        d_rsv_prd_deliv_wht2_tab(gn_rsv_prd_cnt) := ir_deliv_if_rec.delivery_weight2;
        -- 距離
        d_rsv_prd_distance_tab(gn_rsv_prd_cnt)   := ir_deliv_if_rec.distance;
        -- 諸料金
        d_rsv_prd_many_rt_tab(gn_rsv_prd_cnt)    := ir_deliv_if_rec.many_rate;
        -- 通行料
        d_rsv_prd_cng_chrg_tab(gn_rsv_prd_cnt)   := ir_deliv_if_rec.congestion_charge;
        -- ピッキング料
        d_rsv_prd_pic_chrg_tab(gn_rsv_prd_cnt)   := ir_deliv_if_rec.picking_charge;
        -- 混載割増金額
        d_rsv_prd_cns_srchrg_tab(gn_rsv_prd_cnt) := ir_deliv_if_rec.consolid_surcharge;
        -- 合計
        d_rsv_prd_ttl_amt_tab(gn_rsv_prd_cnt)    := ir_deliv_if_rec.total_amount;
--
        -- リターン・コードに警告を設定
        ov_retcode := gv_status_warn;
--
        -- 処理をスキップ
        RETURN;
--
      -- 対象データが存在しない、保留期間内のデータの場合
      ELSE
        -- スキップ件数の格納
        gn_warn_cnt := gn_warn_cnt + 1;
        -- リターン・コードに警告を設定
        ov_retcode := gv_status_warn;
        -- 処理をスキップ
        RETURN;
--
      END IF;
--
    END IF;
--
    -- ************************************************
    -- 締日チェック
    -- ************************************************
    -- 締め日前で且つ、判断日が前月の初日以降の場合
    IF ((gv_target_type = gv_ktg_yes) AND
      gt_deliv_head_tbl(gn_deliv_head_cnt).judgement_date >=
      TRUNC(ADD_MONTHS(gd_sysdate, -1), 'MM'))
    THEN
      -- 正常処理を継続
--
      -- 削除用運賃アドオンインタフェースカウンターのカウントアップ
      gn_deliv_if_del_cnt := gn_deliv_if_del_cnt + 1;
--
      -- 削除用運賃アドオンインタフェースに格納
      d_deliv_if_id_tab(gn_deliv_if_del_cnt) := ir_deliv_if_rec.delivery_id;
--
    -- 締め日後で且つ、判断日が今月の初日以降の場合
    ELSIF ((gv_target_type = gv_ktg_no) AND
      gt_deliv_head_tbl(gn_deliv_head_cnt).judgement_date >=
      TRUNC(gd_sysdate, 'MM'))
    THEN
      -- 正常処理を継続
--
      -- 削除用運賃アドオンインタフェースカウンターのカウントアップ
      gn_deliv_if_del_cnt := gn_deliv_if_del_cnt + 1;
--
      -- 削除用運賃アドオンインタフェースに格納
      d_deliv_if_id_tab(gn_deliv_if_del_cnt) := ir_deliv_if_rec.delivery_id;
--
    -- エラー対象データの場合
    ELSE
      -- 削除用運賃アドオンインタフェースカウンターのカウントアップ
      gn_deliv_if_del_cnt := gn_deliv_if_del_cnt + 1;
      -- エラー件数のカウントアップ
      gn_error_cnt := gn_error_cnt + 1;
--
      -- 削除用運賃アドオンインタフェースに格納
      d_deliv_if_id_tab(gn_deliv_if_del_cnt) := ir_deliv_if_rec.delivery_id;
--
      -- 更新不可能用PL/SQL表用カウンターのカウントアップ
      gn_not_upd_cnt := gn_not_upd_cnt + 1;
--
      -- 更新不可能用PL/SQL表に格納
      -- 運賃アドオンID
      d_not_upd_id_tab(gn_not_upd_cnt)         := ir_deliv_if_rec.delivery_id;
      -- パターン区分
      d_not_upd_ptn_flg_tab(gn_not_upd_cnt)    := ir_deliv_if_rec.pattern_flag;
      -- 運送業者
      d_not_upd_com_cd_tab(gn_not_upd_cnt)     := ir_deliv_if_rec.delivery_company_code;
      -- 配送No
      d_not_upd_no_tab(gn_not_upd_cnt)         := ir_deliv_if_rec.delivery_no;
      -- 送り状No
      d_not_upd_invoice_no_tab(gn_not_upd_cnt) := ir_deliv_if_rec.invoice_no;
      -- 支払請求区分
      d_not_upd_p_b_cls_tab(gn_not_upd_cnt)    := ir_deliv_if_rec.p_b_classe;
      -- 配送区分
      d_not_upd_deliv_cls_tab(gn_not_upd_cnt)  := ir_deliv_if_rec.delivery_classe;
      -- 請求運賃
      d_not_upd_chrg_amt_tab(gn_not_upd_cnt)   := ir_deliv_if_rec.charged_amount;
      -- 個数1
      d_not_upd_qty1_tab(gn_not_upd_cnt)       := ir_deliv_if_rec.qty1;
      -- 個数2
      d_not_upd_qty2_tab(gn_not_upd_cnt)       := ir_deliv_if_rec.qty2;
      -- 重量1
      d_not_upd_deliv_wht1_tab(gn_not_upd_cnt) := ir_deliv_if_rec.delivery_weight1;
      -- 重量2
      d_not_upd_deliv_wht2_tab(gn_not_upd_cnt) := ir_deliv_if_rec.delivery_weight2;
      -- 距離
      d_not_upd_distance_tab(gn_not_upd_cnt)   := ir_deliv_if_rec.distance;
      -- 諸料金
      d_not_upd_many_rt_tab(gn_not_upd_cnt)    := ir_deliv_if_rec.many_rate;
      -- 通行料
      d_not_upd_cng_chrg_tab(gn_not_upd_cnt)   := ir_deliv_if_rec.congestion_charge;
      -- ピッキング料
      d_not_upd_pic_chrg_tab(gn_not_upd_cnt)   := ir_deliv_if_rec.picking_charge;
      -- 混載割増金額
      d_not_upd_cns_srchrg_tab(gn_not_upd_cnt) := ir_deliv_if_rec.consolid_surcharge;
      -- 合計
      d_not_upd_ttl_amt_tab(gn_not_upd_cnt)    := ir_deliv_if_rec.total_amount;
--
      -- リターン・コードに警告を設定
      ov_retcode := gv_status_warn;
    END IF;
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
  END chk_object;
--
--
  /**********************************************************************************
   * Procedure Name   : get_deliv_cal_date
   * Description      : 運賃計算用データ取得(E-5)
   ***********************************************************************************/
  PROCEDURE get_deliv_cal_date(
    ir_deliv_if_rec IN  deliv_if_rec, --   運賃アドオンインタフェースレコード
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliv_cal_date'; -- プログラム名
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
    lt_delivery_classe       xxwip_deliverys_if.delivery_classe%TYPE;       -- 配送区分
    lt_distance              xxwip_deliverys_if.distance%TYPE;              -- 運賃距離
    lt_delivery_weight       xxwip_deliverys_if.delivery_weight1%TYPE;      -- 重量
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
    -- ********************************************
    -- 契約運賃、混載割増運賃の取得
    -- ********************************************
    -- 配送区分の設定
    -- 取得したデータのパターン区分が「伊藤園産業」で且つ、支払請求区分が「支払」の場合
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
      (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      -- 配送区分に値が入力されている場合
      IF (ir_deliv_if_rec.delivery_classe IS NOT NULL) THEN
        lt_delivery_classe := ir_deliv_if_rec.delivery_classe;
      -- 配送区分に値が入力されていない場合
      ELSE
        lt_delivery_classe := gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_classe;
      END IF;
    -- 上記以外の場合
    ELSE
      lt_delivery_classe := gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_classe;
    END IF;
--
    -- 運賃距離の設定
    -- 取得したデータのパターン区分が「伊藤園産業」で且つ、支払請求区分が「支払」の場合
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
      (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      IF (ir_deliv_if_rec.distance IS NOT NULL) THEN
        lt_distance := ir_deliv_if_rec.distance;
      ELSE
        lt_distance := gt_deliv_head_tbl(gn_deliv_head_cnt).distance;
      END IF;
    -- 上記以外の場合
    ELSE
      lt_distance := gt_deliv_head_tbl(gn_deliv_head_cnt).distance;
    END IF;
--
    -- 重量
    -- 取得したデータのパターン区分が「伊藤園産業」で且つ、支払請求区分が「支払」の場合
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
      (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      IF (ir_deliv_if_rec.delivery_weight1 IS NOT NULL) THEN
        lt_delivery_weight := ir_deliv_if_rec.delivery_weight1;
      ELSE
        lt_delivery_weight := gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_weight1;
      END IF;
    -- 上記以外の場合
    ELSE
      lt_delivery_weight := gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_weight1;
    END IF;
--
    -- ********************************************
    -- 運賃アドオンマスタ取得
    -- ********************************************
    -- 共通関数を使用し運送費を取得
    xxwip_common3_pkg.get_delivery_charges(
                        ir_deliv_if_rec.p_b_classe,                          -- 1.支払請求区分
                        gt_deliv_head_tbl(gn_deliv_head_cnt).goods_classe,   -- 2.商品区分
                        ir_deliv_if_rec.delivery_company_code,               -- 3.運送業者
                        lt_delivery_classe,                                  -- 4.配送区分
                        lt_distance,                                         -- 5.運賃距離
                        lt_delivery_weight,                                  -- 6.重量
                        gt_deliv_head_tbl(gn_deliv_head_cnt).judgement_date, -- 7.判断日
                        gr_deliv_charges,    -- 8.運賃アドオンマスタレコード(運消費,リーフ混載割増)
                        lv_errbuf,           -- エラー・メッセージ           --# 固定 #
                        lv_retcode,          -- リターン・コード             --# 固定 #
                        lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ********************************************
    -- ピッキング単価の取得
    -- ********************************************
    BEGIN
      SELECT NVL(xdc.pay_picking_amount, 0),      -- 1.支払ピッキング単価
             NVL(xdc.bill_picking_amount, 0)      -- 2.請求ピッキング単価
      INTO   gr_deliv_company.pay_picking_amount,
             gr_deliv_company.bill_picking_amount
      FROM   xxwip_delivery_company xdc           -- 運賃用運送業者アドオンマスタ
      WHERE  xdc.goods_classe          = gt_deliv_head_tbl(gn_deliv_head_cnt).goods_classe
      AND    xdc.delivery_company_code = ir_deliv_if_rec.delivery_company_code
      AND    gt_deliv_head_tbl(gn_deliv_head_cnt).judgement_date
             BETWEEN xdc.start_date_active AND xdc.end_date_active;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN  -- 対象データなしエラー
        -- 0 を設定
        gr_deliv_company.pay_picking_amount  := 0;
        gr_deliv_company.bill_picking_amount := 0;
    END;
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
  END get_deliv_cal_date;
--
--
  /**********************************************************************************
   * Procedure Name   : set_date
   * Description      : データ設定(E-6)
   ***********************************************************************************/
  PROCEDURE set_date(
    ir_deliv_if_rec IN  deliv_if_rec, --   運賃アドオンインタフェースレコード
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_date'; -- プログラム名
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
    -- *******************************************************************
    -- 運賃ヘッダーアドオン更新用PL/SQL表にデータを設定
    -- *******************************************************************
--
    -- 更新用運賃ヘッダーアドオン用PL/SQL表用カウンターのカウントアップ
    gn_upd_deliv_head_cnt := gn_upd_deliv_head_cnt + 1;
--
--
    -- 運送業者の設定
    u_deliv_head_com_code_id_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.delivery_company_code;
--
    -- 配送Noの設定
    u_deliv_head_deliv_no_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.delivery_no;
--
    -- 送り状No2
    IF (ir_deliv_if_rec.invoice_no IS NOT NULL) THEN
      u_deliv_head_invoice_no_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.invoice_no;
    ELSE
      u_deliv_head_invoice_no_tab(gn_upd_deliv_head_cnt) :=
-- ##### 20080916 Ver.1.5 T_S_570対応 START #####
        --gt_deliv_head_tbl(gn_deliv_head_cnt).invoice_no;
        gt_deliv_head_tbl(gn_deliv_head_cnt).invoice_no2;
-- ##### 20080916 Ver.1.5 T_S_570対応 END #####
    END IF;
--
    -- 支払請求区分
    u_deliv_head_p_b_cls_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.p_b_classe;
--
    -- 報告日
    -- パターン区分 ＝ 「外部」の場合
    IF (ir_deliv_if_rec.pattern_flag = gv_ptn_out) THEN
      u_deliv_head_rpt_date_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.creation_date;
    -- パターン区分 ＝ 「伊藤園産業」の場合
    ELSIF (ir_deliv_if_rec.pattern_flag = gv_ptn_it) THEN
      u_deliv_head_rpt_date_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).report_date;
    END IF;
--
    -- 配送区分
    -- パターン区分 = 「伊藤園産業」で且つ、支払請求区分 = 「支払」の場合
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
      (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      IF (ir_deliv_if_rec.delivery_classe IS NOT NULL) THEN
        u_deliv_head_deliv_cls_tab(gn_upd_deliv_head_cnt) :=
          ir_deliv_if_rec.delivery_classe;
      ELSE
        u_deliv_head_deliv_cls_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_classe;
      END IF;
    ELSE
      u_deliv_head_deliv_cls_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_classe;
    END IF;
--
    -- 請求運賃
    IF (ir_deliv_if_rec.charged_amount IS NOT NULL) THEN
      u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt) :=
        ir_deliv_if_rec.charged_amount;
    ELSE
      u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).charged_amount;
    END IF;
--
    -- 契約運賃
    -- パターン区分 = 「伊藤園産業」で且つ、支払請求区分 = 「支払」の場合
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
        (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      u_deliv_head_con_rate_tab(gn_upd_deliv_head_cnt) :=
                        gr_deliv_charges.shipping_expenses;
    ELSE
      u_deliv_head_con_rate_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).contract_rate;
    END IF;
--
    -- 個数1
    -- パターン区分 = 「伊藤園産業」で且つ、支払請求区分 = 「支払」の場合
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
      (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      IF (ir_deliv_if_rec.qty1 IS NOT NULL) THEN
        u_deliv_head_qty1_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.qty1;
      ELSE
        u_deliv_head_qty1_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).qty1;
      END IF;
    ELSE
      u_deliv_head_qty1_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).qty1;
    END IF;
--
    -- 個数2
    -- パターン区分 = 「外部」の場合
    IF (ir_deliv_if_rec.pattern_flag = gv_ptn_out) THEN
      IF (ir_deliv_if_rec.qty2 IS NOT NULL) THEN
        u_deliv_head_qty2_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.qty2;
      ELSE
        u_deliv_head_qty2_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).qty2;
      END IF;
    ELSE
      u_deliv_head_qty2_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).qty2;
    END IF;
--
    -- 重量1
    -- パターン区分 = 「伊藤園産業」で且つ、支払請求区分 = 「支払」の場合
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
      (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      IF (ir_deliv_if_rec.delivery_weight1 IS NOT NULL) THEN
        u_deliv_head_deliv_wht1_tab(gn_upd_deliv_head_cnt) :=
          ir_deliv_if_rec.delivery_weight1;
      ELSE
        u_deliv_head_deliv_wht1_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_weight1;
      END IF;
    ELSE
      u_deliv_head_deliv_wht1_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_weight1;
    END IF;
--
    -- 重量2
    -- パターン区分 = 「外部」の場合
    IF (ir_deliv_if_rec.pattern_flag = gv_ptn_out) THEN
      IF (ir_deliv_if_rec.delivery_weight2 IS NOT NULL) THEN
        u_deliv_head_deliv_wht2_tab(gn_upd_deliv_head_cnt) :=
          ir_deliv_if_rec.delivery_weight2;
      ELSE
        u_deliv_head_deliv_wht2_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_weight2;
      END IF;
    ELSE
      u_deliv_head_deliv_wht2_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_weight2;
    END IF;
--
    -- 距離
    -- パターン区分 = 「伊藤園産業」で且つ、支払請求区分 = 「支払」の場合
    IF ((ir_deliv_if_rec.pattern_flag = gv_ptn_it) AND
      (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay))
    THEN
      IF (ir_deliv_if_rec.distance IS NOT NULL) THEN
        u_deliv_head_dst_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.distance;
      ELSE
        u_deliv_head_dst_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).distance;
      END IF;
    ELSE
      u_deliv_head_dst_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).distance;
    END IF;
--
    -- 諸料金
    -- パターン区分 = 「伊藤園産業」の場合
    IF (ir_deliv_if_rec.pattern_flag = gv_ptn_it) THEN
      IF (ir_deliv_if_rec.many_rate IS NOT NULL) THEN
        u_deliv_head_many_rt_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.many_rate;
      ELSE
        u_deliv_head_many_rt_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).many_rate;
      END IF;
    ELSE
      u_deliv_head_many_rt_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).many_rate;
    END IF;
--
    -- 通行料
    IF (ir_deliv_if_rec.congestion_charge IS NOT NULL) THEN
      u_deliv_head_cng_chrg_tab(gn_upd_deliv_head_cnt) :=
        ir_deliv_if_rec.congestion_charge;
    ELSE
      u_deliv_head_cng_chrg_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).congestion_charge;
    END IF;
--
    -- ピッキング料
    -- パターン区分 = 「外部」の場合
    IF (ir_deliv_if_rec.pattern_flag = gv_ptn_out) THEN
      u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).picking_charge;
    -- パターン区分 = 「伊藤園産業」の場合
    ELSE
      -- 支払請求区分 ＝ 「支払」の場合
      IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
        IF (ir_deliv_if_rec.picking_charge IS NOT NULL) THEN
          u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) :=
            ir_deliv_if_rec.picking_charge;
        ELSE
          IF (ir_deliv_if_rec.qty1 IS NOT NULL) THEN
            u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) :=
-- ##### 20080725 Ver.1.4 ST障害473対応 START #####
--              ROUND(gr_deliv_company.pay_picking_amount * ir_deliv_if_rec.qty1);
              CEIL(gr_deliv_company.pay_picking_amount * ir_deliv_if_rec.qty1);
-- ##### 20080725 Ver.1.4 ST障害473対応 END   #####
          ELSE
-- ##### 20080725 Ver.1.4 ST障害473対応 START #####
/*****
            u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) :=
              ROUND(gr_deliv_company.pay_picking_amount *
                gt_deliv_head_tbl(gn_deliv_head_cnt).qty1);
*****/
            u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) :=
              CEIL(gr_deliv_company.pay_picking_amount *
                gt_deliv_head_tbl(gn_deliv_head_cnt).qty1);
-- ##### 20080725 Ver.1.4 ST障害473対応 END   #####
          END IF;
        END IF;
      -- 支払請求区分 ＝ 「請求」の場合
      ELSIF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_bil) THEN
        IF (ir_deliv_if_rec.picking_charge IS NOT NULL) THEN
          u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) :=
            ir_deliv_if_rec.picking_charge;
        ELSE
          u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) :=
            gt_deliv_head_tbl(gn_deliv_head_cnt).picking_charge;
        END IF;
      END IF;
    END IF;
--
    -- 混載割増金額
    -- パターン区分 = 「外部」の場合
    IF (ir_deliv_if_rec.pattern_flag = gv_ptn_out) THEN
      u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).consolid_surcharge;
    -- パターン区分 = 「伊藤園産業」の場合
    ELSE
      IF (ir_deliv_if_rec.consolid_surcharge IS NOT NULL) THEN
        u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt) :=
          ir_deliv_if_rec.consolid_surcharge;
      ELSE
        u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt) :=
          gr_deliv_charges.leaf_consolid_add * gt_deliv_head_tbl(gn_deliv_head_cnt).consolid_qty;
      END IF;
    END IF;
--
    -- 合計
    -- パターン区分 = 「外部」の場合
    IF (ir_deliv_if_rec.pattern_flag = gv_ptn_out) THEN
      u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).total_amount;
    -- パターン区分 = 「伊藤園産業」の場合
    ELSE
      IF (ir_deliv_if_rec.total_amount IS NOT NULL) THEN
        u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt) := ir_deliv_if_rec.total_amount;
      ELSE
-- ##### 20080725 Ver.1.4 ST障害473対応 START #####
/*****
        u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt) :=
                      u_deliv_head_con_rate_tab(gn_upd_deliv_head_cnt) +
                      u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt) +
                      u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) +
                      u_deliv_head_many_rt_tab(gn_upd_deliv_head_cnt);
*****/
-- ##### 20081201 Ver.1.6 本番#303対応 START #####
        -- 支払請求区分 ＝ 「支払」の場合
        -- 契約金額 ＋ 混載割増金額 ＋ ピッキング料 ＋ 諸料金
        IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
-- ##### 20081201 Ver.1.6 本番#303対応 END   #####
          u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt) :=
                        NVL(u_deliv_head_con_rate_tab(gn_upd_deliv_head_cnt),0) +
                        NVL(u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt),0) +
                        NVL(u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt),0) +
                        NVL(u_deliv_head_many_rt_tab(gn_upd_deliv_head_cnt),0);
-- ##### 20081201 Ver.1.6 本番#303対応 START #####
        -- 支払請求区分 ＝ 「請求」の場合
        -- 請求金額 ＋ 混載割増金額 ＋ ピッキング料 ＋ 諸料金
        ELSE
          u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt) :=
                        NVL(u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt),0) +
                        NVL(u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt),0) +
                        NVL(u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt),0) +
                        NVL(u_deliv_head_many_rt_tab(gn_upd_deliv_head_cnt),0);
        END IF;
-- ##### 20081201 Ver.1.6 本番#303対応 END   #####
-- ##### 20080725 Ver.1.4 ST障害473対応 END   #####
      END IF;
    END IF;
--
    -- 差額
-- ##### 20080725 Ver.1.4 ST障害473対応 START #####
/*****
    u_deliv_head_balance_tab(gn_upd_deliv_head_cnt) :=
                u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt) -
                  u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt);
*****/
-- ##### 20081201 Ver.1.6 本番#303対応 START #####
    -- 支払請求区分 ＝ 「支払」の場合
    IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
-- ##### 20081201 Ver.1.6 本番#303対応 END   #####
--  請求金額 － 合計
    u_deliv_head_balance_tab(gn_upd_deliv_head_cnt) :=
                NVL(u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt),0) -
                  NVL(u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt),0);
--
-- ##### 20081201 Ver.1.6 本番#303対応 START #####
--
    -- 支払請求区分 ＝ 「請求」の場合
    ELSE
      -- 合計 - （請求金額 ＋ 混載割増金額 ＋ ピッキング料 ＋ 諸料金）
      -- 計算結果は０になる
      u_deliv_head_balance_tab(gn_upd_deliv_head_cnt) :=
        u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt) -
        (NVL(u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt),0) +
         NVL(u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt),0) +
         NVL(u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt),0) +
         NVL(u_deliv_head_many_rt_tab(gn_upd_deliv_head_cnt),0));
    END IF;
-- ##### 20081201 Ver.1.6 本番#303対応 END   #####
-- ##### 20080725 Ver.1.4 ST障害473対応 END   #####
--
    -- 差異区分
    -- 支払請求区分 = 「支払」の場合
    IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
      -- 更新用PL/SQL表.差額 ≠ 「0」の場合
      IF (u_deliv_head_balance_tab(gn_upd_deliv_head_cnt) <> 0) THEN
        u_deliv_head_op_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_yes;
      -- 更新用PL/SQL表.差額 ＝ 「0」の場合
      ELSIF (u_deliv_head_balance_tab(gn_upd_deliv_head_cnt) = 0) THEN
          u_deliv_head_op_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_no;
      END IF;
    -- 支払請求区分 = 「請求」の場合
    ELSE
      u_deliv_head_op_flg_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).output_flag;
    END IF;
--
    -- 画面更新有無区分
    -- 運賃アドオンインタフェース.支払請求区分 ＝ 「支払」の場合
    IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
      -- 配送区分、個数1、重量1、距離、ピッキング料、合計、混載割増金額の
      -- いずれかが変更になった場合
      IF (u_deliv_head_deliv_cls_tab(gn_upd_deliv_head_cnt) <>
            gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_classe OR
          u_deliv_head_qty1_tab(gn_upd_deliv_head_cnt) <>
            gt_deliv_head_tbl(gn_deliv_head_cnt).qty1 OR
          u_deliv_head_deliv_wht1_tab(gn_upd_deliv_head_cnt) <>
            gt_deliv_head_tbl(gn_deliv_head_cnt).delivery_weight1 OR
          u_deliv_head_dst_tab(gn_upd_deliv_head_cnt) <>
            gt_deliv_head_tbl(gn_deliv_head_cnt).distance OR
          u_deliv_head_pic_chrg_tab(gn_upd_deliv_head_cnt) <>
            gt_deliv_head_tbl(gn_deliv_head_cnt).picking_charge OR
          u_deliv_head_ttl_amt_tab(gn_upd_deliv_head_cnt) <>
            gt_deliv_head_tbl(gn_deliv_head_cnt).total_amount OR
          u_deliv_head_cns_srchrg_tab(gn_upd_deliv_head_cnt) <>
            gt_deliv_head_tbl(gn_deliv_head_cnt).consolid_surcharge)
      THEN
        u_deliv_head_frm_upd_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_yes;
      ELSE
        u_deliv_head_frm_upd_flg_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).form_update_flag;
      END IF;
    -- 運賃アドオンインタフェース.支払請求区分 ＝ 「請求」の場合
    ELSIF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_bil) THEN
      u_deliv_head_frm_upd_flg_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).form_update_flag;
    END IF;
--
    -- 支払確定区分
    -- 運賃アドオンインタフェース.支払請求区分 ＝ 「支払」の場合
    IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
      -- 更新用PL/SQL表.差異区分 = 「Yes」の場合
      IF (u_deliv_head_op_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_yes) THEN
        u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_no;
      -- 更新用PL/SQL表.差異区分 ＝ 「No」の場合
      ELSIF (u_deliv_head_op_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_no) THEN
        -- 更新用PL/SQL表.請求運賃 ≠ 「0」の場合
        IF (u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt) <> 0) THEN
          u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_yes;
        -- 更新用PL/SQL表.請求運賃 ＝ 「0」の場合
        ELSIF (u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt) = 0) THEN
          -- 更新用PL/SQL表.画面更新有無区分 ＝ 「Yes」の場合
          IF (u_deliv_head_frm_upd_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_yes) THEN
            u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_yes;
          -- 更新用PL/SQL表.画面更新有無区分 ＝ 「No」の場合
          ELSIF (u_deliv_head_frm_upd_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_no) THEN
-- *--------* 20080916 Ver.1.7 本番#1239対応 START *--------*
--            u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_no;
--
            -- パターン区分 = 「伊藤園産業」の場合
            IF (ir_deliv_if_rec.pattern_flag = gv_ptn_it) THEN
              u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_yes;
--
            -- パターン区分 = 「外部」の場合
            ELSE
              u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_no;
            END IF;
-- *--------* 20080916 Ver.1.7 本番#1239対応 END   *--------*
          END IF;
        END IF;
      END IF;
    -- 運賃アドオンインタフェース.支払請求区分 ＝ 「請求」の場合
    ELSIF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_bil) THEN
      u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).defined_flag;
    END IF;
--
    -- 支払確定戻
    -- 運賃アドオンインタフェース.支払請求区分 = 「支払」の場合
    IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
      -- 運賃ヘッダーアドオン.支払確定区分 ＝ 「Yes」で且つ、
      -- 更新用PL/SQL表.支払確定区分 ＝ 「No」の場合
      IF (gt_deliv_head_tbl(gn_deliv_head_cnt).defined_flag = gv_ktg_yes AND
            u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_no)
      THEN
        u_deliv_head_rtrn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_yes;
      -- 更新用PL/SQL表.差異区分 ＝ 「No」で且つ、
      -- 更新用PL/SQL表.請求運賃 ＝ 「0」で且つ、
      -- 更新用PL/SQL表.画面更新有無区分 ＝ 「Yes」の場合
      ELSIF (u_deliv_head_op_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_no AND
              u_deliv_head_chrg_amt_tab(gn_upd_deliv_head_cnt) = 0 AND
              u_deliv_head_frm_upd_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_yes)
      THEN
        u_deliv_head_rtrn_flg_tab(gn_upd_deliv_head_cnt) := gv_ktg_no;
      -- 上記以外の場合
      ELSE
        u_deliv_head_rtrn_flg_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).return_flag;
      END IF;
    -- 運賃アドオンインタフェース.支払請求区分 = 「請求」の場合
    ELSIF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_bil) THEN
      u_deliv_head_rtrn_flg_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).return_flag;
    END IF;
--
    -- 外部業者変更回数
    -- 運賃アドオンインタフェース.支払請求区分 ＝ 「支払」の場合
    IF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_pay) THEN
      -- 運賃アドオンインタフェース.パターン区分 ＝ 「外部」の場合
      IF (ir_deliv_if_rec.pattern_flag = gv_ptn_out) THEN
        u_deliv_head_os_up_cnt_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).outside_up_count + 1;
      -- 運賃アドオンインタフェース.パターン区分 ＝ 「伊藤園産業」の場合
      ELSIF (ir_deliv_if_rec.pattern_flag = gv_ptn_it) THEN
        u_deliv_head_os_up_cnt_tab(gn_upd_deliv_head_cnt) :=
          gt_deliv_head_tbl(gn_deliv_head_cnt).outside_up_count;
      END IF;
    -- 運賃アドオンインタフェース.支払請求区分 ＝ 「請求」の場合
    ELSIF (ir_deliv_if_rec.p_b_classe = gv_p_b_cls_bil) THEN
      u_deliv_head_os_up_cnt_tab(gn_upd_deliv_head_cnt) :=
        gt_deliv_head_tbl(gn_deliv_head_cnt).outside_up_count;
    END IF;
--
--
    -- *******************************************************************
    -- 請求データ削除用PL/SQL表の設定
    -- *******************************************************************
    -- 更新用PL/SQL表.支払確定区分 ＝ 「No」の場合
    IF (u_deliv_head_dfn_flg_tab(gn_upd_deliv_head_cnt) = gv_ktg_no) THEN
      -- 請求データ削除用PL/SQL表カウンターのカウントアップ
      gn_bil_deliv_no_cnt := gn_bil_deliv_no_cnt + 1;
      -- 対象データの配送Noを設定
      d_bil_deliv_no_tab(gn_bil_deliv_no_cnt) := u_deliv_head_deliv_no_tab(gn_upd_deliv_head_cnt);
    END IF;
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
  END set_date;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_deliv_head
   * Description      : 運賃ヘッダーアドオン更新(E-7)
   ***********************************************************************************/
  PROCEDURE upd_deliv_head(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_deliv_head'; -- プログラム名
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
    -- ***********************************
    -- * 運賃ヘッダーアドオン   更新
    -- ***********************************
    FORALL ln_index IN u_deliv_head_com_code_id_tab.FIRST .. u_deliv_head_com_code_id_tab.LAST
      UPDATE xxwip_deliverys xd                                  -- 運賃ヘッダーアドオン
-- ##### 20080916 Ver.1.5 T_S_570対応 START #####
      --SET    xd.invoice_no             = u_deliv_head_invoice_no_tab(ln_index),  -- 1.送り状No
      SET    xd.invoice_no2             = u_deliv_head_invoice_no_tab(ln_index),  -- 1.送り状No2
-- ##### 20080916 Ver.1.5 T_S_570対応 END #####
             xd.delivery_classe        = u_deliv_head_deliv_cls_tab(ln_index),   -- 2.配送区分
             xd.report_date            = u_deliv_head_rpt_date_tab(ln_index),    -- 3.報告日
             xd.charged_amount         = u_deliv_head_chrg_amt_tab(ln_index),    -- 4.請求運賃
             xd.contract_rate          = u_deliv_head_con_rate_tab(ln_index),    --   契約運賃
             xd.distance               = u_deliv_head_dst_tab(ln_index),         -- 5.最長距離
             xd.qty1                   = u_deliv_head_qty1_tab(ln_index),        -- 6.個数1
             xd.qty2                   = u_deliv_head_qty2_tab(ln_index),        -- 7.個数2
             xd.delivery_weight1       = u_deliv_head_deliv_wht1_tab(ln_index),  -- 8.重量1
             xd.delivery_weight2       = u_deliv_head_deliv_wht2_tab(ln_index),  -- 9.重量2
             xd.balance                = u_deliv_head_balance_tab(ln_index),     -- 10.差額
             xd.many_rate              = u_deliv_head_many_rt_tab(ln_index),     -- 11.諸料金
             xd.congestion_charge      = u_deliv_head_cng_chrg_tab(ln_index),    -- 12.通行料
             xd.picking_charge         = u_deliv_head_pic_chrg_tab(ln_index),    -- 13.ピッキング料
             xd.consolid_surcharge     = u_deliv_head_cns_srchrg_tab(ln_index),  -- 14.混載割増金額
             xd.total_amount           = u_deliv_head_ttl_amt_tab(ln_index),     -- 15.合計
             xd.output_flag            = u_deliv_head_op_flg_tab(ln_index),      -- 16.差異区分
             xd.defined_flag           = u_deliv_head_dfn_flg_tab(ln_index),     -- 17.支払確定区分
             xd.return_flag            = u_deliv_head_rtrn_flg_tab(ln_index),    -- 18.支払確定戻
             xd.form_update_flag       = u_deliv_head_frm_upd_flg_tab(ln_index), -- 19.画面更新有無
             xd.outside_up_count       = u_deliv_head_os_up_cnt_tab(ln_index),   -- 20.外部業者変更
             xd.last_updated_by        = gn_user_id,             -- 21.最終更新者
             xd.last_update_date       = gd_sysdate,             -- 22.最終更新日
             xd.last_update_login      = gn_login_id,            -- 23.最終更新ログイン
             xd.request_id             = gn_conc_request_id,     -- 24.要求ID
             xd.program_application_id = gn_prog_appl_id,        -- 25.ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
             xd.program_id             = gn_conc_program_id,     -- 26.コンカレント・プログラムID
             xd.program_update_date    = gd_sysdate              -- 27.プログラム更新日
      WHERE  xd.delivery_company_code  = u_deliv_head_com_code_id_tab(ln_index)
      AND    xd.delivery_no            = u_deliv_head_deliv_no_tab(ln_index)
      AND    xd.p_b_classe             = u_deliv_head_p_b_cls_tab(ln_index);
--
    -- 更新件数の格納
-- ##### 20080710 Ver.1.3 ST障害432対応 START #####
--    gn_normal_cnt := u_deliv_head_com_code_id_tab.LAST;
    gn_normal_cnt := u_deliv_head_com_code_id_tab.COUNT;
-- ##### 20080710 Ver.1.3 ST障害432対応 END   #####
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
  END upd_deliv_head;
--
--
  /**********************************************************************************
   * Procedure Name   : del_deliv_head
   * Description      : 運賃ヘッダーアドオン削除(E-8)
   ***********************************************************************************/
  PROCEDURE del_deliv_head(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_deliv_head'; -- プログラム名
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
    -- ***********************************
    -- * 運賃ヘッダーアドオン   削除
    -- ***********************************
    FORALL ln_index IN d_bil_deliv_no_tab.FIRST .. d_bil_deliv_no_tab.LAST
      DELETE FROM xxwip_deliverys xd   -- 運賃ヘッダーアドオン
      WHERE  xd.p_b_classe  = gv_p_b_cls_bil
      AND    xd.delivery_no = d_bil_deliv_no_tab(ln_index);
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
  END del_deliv_head;
--
--
  /**********************************************************************************
   * Procedure Name   : del_deliv_if
   * Description      : 運賃アドオンインタフェース削除(E-9)
   ***********************************************************************************/
  PROCEDURE del_deliv_if(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_deliv_if'; -- プログラム名
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
    -- ***********************************
    -- * 運賃アドオンインタフェース   削除
    -- ***********************************
    FORALL ln_index IN d_deliv_if_id_tab.FIRST .. d_deliv_if_id_tab.LAST
      DELETE FROM xxwip_deliverys_if xdi   -- 運賃アドオンインタフェース
      WHERE  xdi.delivery_id  = d_deliv_if_id_tab(ln_index);
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
  END del_deliv_if;
--
--
  /**********************************************************************************
   * Procedure Name   : out_message
   * Description      : メッセージ出力(E-10)
   ***********************************************************************************/
  PROCEDURE out_message(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_message'; -- プログラム名
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
    lv_message VARCHAR2(5000);   -- メッセージ格納
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
    -- **************************************************
    -- 保留期間経過メッセージ出力ループ
    -- **************************************************
    -- 運賃アドオンIDが存在する場合
    IF (d_rsv_prd_id_tab.EXISTS(1)) THEN
--
      -- 終了ステータスを警告に設定
      ov_retcode := gv_status_warn;
--
      -- タイトルの出力
      lv_message := '     ';
      lv_message := lv_message || xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                                           gv_wip_msg_73e_306);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_message);
--
      <<reserve_period_loop>>
      FOR ln_index IN d_rsv_prd_id_tab.FIRST .. d_rsv_prd_id_tab.LAST LOOP
        lv_message := '     ' || ln_index || ' ';
        lv_message := lv_message || d_rsv_prd_id_tab(ln_index) || ',';          -- 運賃アドオンID
        lv_message := lv_message || d_rsv_prd_ptn_flg_tab(ln_index) || ',';     -- パターン区分
        lv_message := lv_message || d_rsv_prd_com_cd_tab(ln_index) || ',';      -- 運送業者
        lv_message := lv_message || d_rsv_prd_no_tab(ln_index) || ',';          -- 配送No
        lv_message := lv_message || d_rsv_prd_invoice_no_tab(ln_index) || ',';  -- 送り状No
        lv_message := lv_message || d_rsv_prd_p_b_cls_tab(ln_index) || ',';     -- 支払請求区分
        lv_message := lv_message || d_rsv_prd_deliv_cls_tab(ln_index) || ',';   -- 配送区分
        lv_message := lv_message || d_rsv_prd_chrg_amt_tab(ln_index) || ',';    -- 請求運賃
        lv_message := lv_message || d_rsv_prd_qty1_tab(ln_index) || ',';        -- 個数1
        lv_message := lv_message || d_rsv_prd_qty2_tab(ln_index) || ',';        -- 個数2
        lv_message := lv_message || d_rsv_prd_deliv_wht1_tab(ln_index) || ',';  -- 重量1
        lv_message := lv_message || d_rsv_prd_deliv_wht2_tab(ln_index) || ',';  -- 重量2
        lv_message := lv_message || d_rsv_prd_distance_tab(ln_index) || ',';    -- 距離
        lv_message := lv_message || d_rsv_prd_many_rt_tab(ln_index) || ',';     -- 諸料金
        lv_message := lv_message || d_rsv_prd_cng_chrg_tab(ln_index) || ',';    -- 通行料
        lv_message := lv_message || d_rsv_prd_pic_chrg_tab(ln_index) || ',';    -- ピッキング料
        lv_message := lv_message || d_rsv_prd_cns_srchrg_tab(ln_index) || ',';  -- 混載割増金額
        lv_message := lv_message || d_rsv_prd_ttl_amt_tab(ln_index);             -- 合計
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_message);
      END LOOP reserve_period_loop;
    END IF;
--
    -- **************************************************
    -- 配送区分存在なしメッセージ出力ループ
    -- **************************************************
    -- 運賃アドオンIDが存在する場合
    IF (d_deliv_cls_id_tab.EXISTS(1)) THEN
--
      -- 終了ステータスを警告に設定
      ov_retcode := gv_status_warn;
--
      -- タイトルの出力
      lv_message := '     ';
      lv_message := lv_message || xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                                           gv_wip_msg_73e_305);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_message);
--
      <<delivery_classe_loop>>
      FOR ln_index IN d_deliv_cls_id_tab.FIRST .. d_deliv_cls_id_tab.LAST LOOP
        lv_message := '     ' || ln_index || ' ';
        lv_message := lv_message || d_deliv_cls_id_tab(ln_index) || ',';          -- 運賃アドオンID
        lv_message := lv_message || d_deliv_cls_ptn_flg_tab(ln_index) || ',';     -- パターン区分
        lv_message := lv_message || d_deliv_cls_com_cd_tab(ln_index) || ',';      -- 運送業者
        lv_message := lv_message || d_deliv_cls_no_tab(ln_index) || ',';          -- 配送No
        lv_message := lv_message || d_deliv_cls_invoice_no_tab(ln_index) || ',';  -- 送り状No
        lv_message := lv_message || d_deliv_cls_p_b_cls_tab(ln_index) || ',';     -- 支払請求区分
        lv_message := lv_message || d_deliv_cls_deliv_cls_tab(ln_index) || ',';   -- 配送区分
        lv_message := lv_message || d_deliv_cls_chrg_amt_tab(ln_index) || ',';    -- 請求運賃
        lv_message := lv_message || d_deliv_cls_qty1_tab(ln_index) || ',';        -- 個数1
        lv_message := lv_message || d_deliv_cls_qty2_tab(ln_index) || ',';        -- 個数2
        lv_message := lv_message || d_deliv_cls_deliv_wht1_tab(ln_index) || ',';  -- 重量1
        lv_message := lv_message || d_deliv_cls_deliv_wht2_tab(ln_index) || ',';  -- 重量2
        lv_message := lv_message || d_deliv_cls_distance_tab(ln_index) || ',';    -- 距離
        lv_message := lv_message || d_deliv_cls_many_rt_tab(ln_index) || ',';     -- 諸料金
        lv_message := lv_message || d_deliv_cls_cng_chrg_tab(ln_index) || ',';    -- 通行料
        lv_message := lv_message || d_deliv_cls_pic_chrg_tab(ln_index) || ',';    -- ピッキング料
        lv_message := lv_message || d_deliv_cls_cns_srchrg_tab(ln_index) || ',';  -- 混載割増金額
        lv_message := lv_message || d_deliv_cls_ttl_amt_tab(ln_index);             -- 合計
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_message);
      END LOOP delivery_classe_loop;
    END IF;
--
    -- **************************************************
    -- 運賃更新不可能メッセージ出力ループ
    -- **************************************************
    -- 運賃アドオンIDが存在する場合
    IF (d_not_upd_id_tab.EXISTS(1)) THEN
--
      -- 終了ステータスを警告に設定
      ov_retcode := gv_status_warn;
--
      -- タイトルの出力
      lv_message := '     ';
      lv_message := lv_message || xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                                           gv_wip_msg_73e_304);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_message);
--
      <<not_update_loop>>
      FOR ln_index IN d_not_upd_id_tab.FIRST .. d_not_upd_id_tab.LAST LOOP
        lv_message := '     ' || ln_index || ' ';
        lv_message := lv_message || d_not_upd_id_tab(ln_index) || ',';          -- 運賃アドオンID
        lv_message := lv_message || d_not_upd_ptn_flg_tab(ln_index) || ',';     -- パターン区分
        lv_message := lv_message || d_not_upd_com_cd_tab(ln_index) || ',';      -- 運送業者
        lv_message := lv_message || d_not_upd_no_tab(ln_index) || ',';          -- 配送No
        lv_message := lv_message || d_not_upd_invoice_no_tab(ln_index) || ',';  -- 送り状No
        lv_message := lv_message || d_not_upd_p_b_cls_tab(ln_index) || ',';     -- 支払請求区分
        lv_message := lv_message || d_not_upd_deliv_cls_tab(ln_index) || ',';   -- 配送区分
        lv_message := lv_message || d_not_upd_chrg_amt_tab(ln_index) || ',';    -- 請求運賃
        lv_message := lv_message || d_not_upd_qty1_tab(ln_index) || ',';        -- 個数1
        lv_message := lv_message || d_not_upd_qty2_tab(ln_index) || ',';        -- 個数2
        lv_message := lv_message || d_not_upd_deliv_wht1_tab(ln_index) || ',';  -- 重量1
        lv_message := lv_message || d_not_upd_deliv_wht2_tab(ln_index) || ',';  -- 重量2
        lv_message := lv_message || d_not_upd_distance_tab(ln_index) || ',';    -- 距離
        lv_message := lv_message || d_not_upd_many_rt_tab(ln_index) || ',';     -- 諸料金
        lv_message := lv_message || d_not_upd_cng_chrg_tab(ln_index) || ',';    -- 通行料
        lv_message := lv_message || d_not_upd_pic_chrg_tab(ln_index) || ',';    -- ピッキング料
        lv_message := lv_message || d_not_upd_cns_srchrg_tab(ln_index) || ',';  -- 混載割増金額
        lv_message := lv_message || d_not_upd_ttl_amt_tab(ln_index);             -- 合計
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_message);
      END LOOP not_update_loop;
    END IF;
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
  END out_message;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
-- ##### Ver.1.8 E_本稼動_13659対応 START #####
    iv_prod_div   IN  VARCHAR2,     --   商品区分
-- ##### Ver.1.8 E_本稼動_13659対応 END   #####
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- グローバル・ユーザー定義変数の初期化
    gn_deliv_head_cnt       := 0;
    gn_upd_deliv_head_cnt   := 0;
    gn_deliv_cls_cnt        := 0;
    gn_rsv_prd_cnt          := 0;
    gn_not_upd_cnt          := 0;
    gn_bil_deliv_no_cnt     := 0;
    gn_deliv_if_del_cnt     := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =========================================
    -- 関連データ取得(E-1)
    -- =========================================
    get_related_date(
-- ##### Ver.1.8 E_本稼動_13659対応 START #####
      iv_prod_div,       -- 商品区分
-- ##### Ver.1.8 E_本稼動_13659対応 END   #####
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ロック取得(E-2)
    -- =========================================
    get_lock(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 運賃アドオンインタフェースデータ取得(E-3)
    -- =========================================
    get_deliv_if_date(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_normal) THEN
--
      -- ****************************************************
      -- チェックループ
      -- ****************************************************
      <<chech_loop>>
      FOR ln_index IN gt_deliv_if_tbl.FIRST .. gt_deliv_if_tbl.LAST LOOP
--
        -- =========================================
        -- 更新対象チェック(E-4)
        -- =========================================
        chk_object(
          gt_deliv_if_tbl(ln_index),   -- 運賃アドオンインタフェースレコード
          lv_errbuf,                   -- エラー・メッセージ           --# 固定 #
          lv_retcode,                  -- リターン・コード             --# 固定 #
          lv_errmsg);                  -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- リターン・コードが正常の場合
        ELSIF (lv_retcode = gv_status_normal) THEN
--
          -- =========================================
          -- 運賃計算用データ取得(E-5)
          -- =========================================
          get_deliv_cal_date(
            gt_deliv_if_tbl(ln_index),   -- 運賃アドオンインタフェースレコード
            lv_errbuf,                   -- エラー・メッセージ           --# 固定 #
            lv_retcode,                  -- リターン・コード             --# 固定 #
            lv_errmsg);                  -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- =========================================
          -- データ設定(E-6)
          -- =========================================
          set_date(
            gt_deliv_if_tbl(ln_index),   -- 運賃アドオンインタフェースレコード
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF; -- E-4の処理にてリターン・コードが警告の場合、後処理をスキップ
--
      END LOOP chech_loop;
--
      -- =========================================
      -- 運賃ヘッダーアドオン更新(E-7)
      -- =========================================
      upd_deliv_head(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 運賃ヘッダーアドオン削除(E-8)
      -- =========================================
      del_deliv_head(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 運賃アドオンインタフェース削除(E-9)
      -- =========================================
      del_deliv_if(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- メッセージ出力(E-10)
      -- =========================================
      out_message(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
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
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
-- ##### Ver.1.8 E_本稼動_13659対応 START #####
--    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_prod_div   IN  VARCHAR2       --   商品区分
-- ##### Ver.1.8 E_本稼動_13659対応 END   #####
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
-- ##### Ver.1.8 E_本稼動_13659対応 START #####
      iv_prod_div, -- 商品区分
-- ##### Ver.1.8 E_本稼動_13659対応 END   #####
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
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
END xxwip730003c;
/
