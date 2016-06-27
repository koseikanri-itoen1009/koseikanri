CREATE OR REPLACE PACKAGE BODY xxwsh620002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620002c(body)
 * Description      : 出庫配送依頼表
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_620
 * MD.070           : 出庫配送依頼表 T_MD070_BPO_62C
 * Version          : 1.22
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  prc_initialize         PROCEDURE : 初期処理(F-1,F-2,F-3)
 *  prc_get_report_data    PROCEDURE : 帳票データ取得処理(F-4)
 *  prc_create_xml_data    PROCEDURE : XML生成処理(F-5)
 *  fnc_convert_into_xml   FUNCTION  : XMLデータ変換(F-5)
 *  submain                PROCEDURE : メイン処理プロシージャ
 *  main                   PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/30    1.0   Yoshitomo Kawasaki 新規作成
 *  2008/06/04    1.1   Jun Nakada       出力担当部署の値をコードから名称に修正。GLOBAL変数名整理
 *                                       運送依頼元の名称を 部署=>会社名 から 会社名 => 部署に修正
 *  2008/06/12    1.2   Kazuo Kumamoto   パラメータ.業務種別によって抽出対象を選択
 *  2008/06/18    1.3   Kazuo Kumamoto   結合テスト障害対応
 *                                       (配送No未設定の場合は数量合計、混在重量、混載体積を出力しない)
 *  2008/06/23    1.4   Yoshikatsu Shindou 配送区分情報VIEWのリレーションを外部結合に変更
 *                                         (システムテスト不具合#229)
 *                                         小口区分が取得できない場合,重量容積合計をNULLとする。
 *  2008/07/02    1.5   Satoshi Yunba    禁則文字対応
 *  2008/07/04    1.6   Naoki Fukuda     ST不具合対応#394
 *  2008/07/04    1.7   Naoki Fukuda     ST不具合対応#409
 *  2008/07/07    1.8   Naoki Fukuda     ST不具合対応#337
 *  2008/07/09    1.9   Satoshi Takemoto 変更要求対応#92,#98
 *  2008/07/17    1.10  Kazuo Kumamoto   結合テスト障害対応
 *                                       1.10.1 パラメータ.品目区分未指定時の品目区分名を空欄とする。
 *                                       1.10.2 支給の配送先等の情報取得先を変更。
 *                                       1.10.3 配送先が混載している場合は全ての配送先を出力する。
 *  2008/07/17    1.11  Satoshi Takemoto 結合テスト不具合対応(変更要求対応#92,#98)
 *  2008/08/04    1.12  Takao Ohashi     結合出荷テスト(出荷追加_18,19,20)修正
 *  2008/10/27    1.13  Masayoshi Uehara 統合指摘297、T_TE080_BPO_620 指摘35指摘45指摘47
 *                                       T_S_501T_S_601T_S_607、T_TE110_BPO_230-001 指摘440
 *                                       課題#32 単位/入数換算の処理ロジック
 *  2008/11/07    1.14  Y.Yamamoto       統合指摘#143対応(数量0のデータを対象外とする)
 *  2008/11/13    1.15  Y.Yamamoto       統合指摘#595対応、内部変更#168
 *  2008/11/20    1.16  Y.Yamamoto       統合指摘#464、#686対応
 *  2008/11/27    1.17  A.Shiina         本番#185対応
 *  2009/01/23    1.18  N.Yoshida        本番#765対応
 *  2009/02/04    1.19  Y.Kanami         本番#41対応
 *                                       重量容積の計算でパレット重量加算を削除する
 *  2009/04/24    1.20  H.Itou           本番#1398対応
 *  2009/12/15    1.21  H.Itou           本稼動障害#XXXX対応
 *  2016/06/01    1.22  K.Kiriu          E_本稼動_13659対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ###############################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
--################################  固定部 END   ###############################
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
--###########################  固定部 END   ############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** 処理部共通例外 ***
  no_data_expt       EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gc_pkg_name                 CONSTANT  VARCHAR2(100) := 'xxwsh620002c' ;   -- パッケージ名
  gc_report_id                CONSTANT  VARCHAR2(12)  := 'XXWSH620002T' ;   -- 帳票ID
  -- 帳票タイトル
  gc_rpt_title_haisou_yotei   CONSTANT  VARCHAR2(10)  := '配送予定表' ;     -- 配送予定表
  gc_rpt_title_haisou_irai    CONSTANT  VARCHAR2(10)  := '配送依頼表' ;     -- 配送依頼表
  gc_rpt_title_shukko_yotei   CONSTANT  VARCHAR2(10)  := '出庫予定表' ;     -- 出庫予定表
  gc_rpt_title_shukko_irai    CONSTANT  VARCHAR2(10)  := '出庫依頼表' ;     -- 出庫依頼表
  -- 予定確定区分
  gc_plan_decide_p            CONSTANT  VARCHAR2(1)   := '1' ;              -- 予定
  gc_plan_decide_d            CONSTANT  VARCHAR2(1)   := '2' ;              -- 確定
  -- 出庫配送区分
  gc_shukko_haisou_kbn_p      CONSTANT  VARCHAR2(1)   := '1' ;              -- 出庫
  gc_shukko_haisou_kbn_d      CONSTANT  VARCHAR2(1)   := '2' ;              -- 配送
  -- 出力タグ
  gc_tag_type_tag             CONSTANT  VARCHAR2(1)   := 'T' ;              -- グループタグ
  gc_tag_type_data            CONSTANT  VARCHAR2(1)   := 'D' ;              -- データタグ
  -- 日付フォーマット
  gc_date_fmt_all             CONSTANT  VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS' ;  -- 年月日時分秒
  gc_date_fmt_ymd             CONSTANT  VARCHAR2(10)  := 'YYYY/MM/DD' ;             -- 年月日
  gc_date_fmt_hh24mi          CONSTANT  VARCHAR2(10)  := 'HH24:MI' ;                -- 時分
  gc_date_fmt_ymd_ja          CONSTANT  VARCHAR2(20)  := 'YYYY"年"MM"月"DD"日' ;    -- 時分
  -- 文書タイプ
  gc_doc_type_code_syukka     CONSTANT  VARCHAR2(2)   := '10' ;             -- 出荷依頼
  gc_doc_type_code_mv         CONSTANT  VARCHAR2(2)   := '20' ;             -- 移動
  gc_doc_type_code_shikyu     CONSTANT  VARCHAR2(2)   := '30' ;             -- 支給指示
  -- レコードタイプ
  gc_rec_type_code_ins        CONSTANT  VARCHAR2(2)   := '10' ;             -- 指示
  -- 新規修正フラグ
  gc_new_modify_flg_mod       CONSTANT  VARCHAR2(1)   := 'M' ;              -- 修正
  gc_asterisk                 CONSTANT  VARCHAR2(1)   := '*' ;              -- 固定値「*」
  -- 商品区分
  gc_prod_cd_leaf             CONSTANT  VARCHAR2(1)   := '1' ;              -- リーフ   --v1.13追加
  gc_prod_cd_drink            CONSTANT  VARCHAR2(1)   := '2' ;              -- ドリンク
  gc_item_cd_prdct            CONSTANT  VARCHAR2(1)   := '5' ;              -- 製品
  gc_item_cd_material         CONSTANT  VARCHAR2(1)   := '1' ;              -- 原料
  gc_item_cd_prdct_half       CONSTANT  VARCHAR2(1)   := '4' ;              -- 半製品
-- 2008/11/20 Y.Yamamoto v1.16 add start
  gc_item_cd_shizai           CONSTANT  VARCHAR2(1)   := '2' ;              -- 資材
-- 2008/11/20 Y.Yamamoto v1.16 add end
  -- 小口区分
  gc_small_amount_enabled     CONSTANT VARCHAR2(1)    := '1' ;              -- 小口区分が対象
  -- ユーザー区分
  gc_user_kbn_inside          CONSTANT  VARCHAR2(1)   := '1' ;              -- 内部
  gc_user_kbn_outside         CONSTANT  VARCHAR2(1)   := '2' ;              -- 外部
  -- 重量容積区分
  gc_wei_cap_kbn_w            CONSTANT  VARCHAR2(1)   := '1' ;              -- 重量
  gc_wei_cap_kbn_c            CONSTANT  VARCHAR2(1)   := '2' ;              -- 容積
  -- 出荷依頼ステータス
  gc_ship_status_close        CONSTANT  VARCHAR2(2)   := '03' ;             -- 締め済み
  gc_req_status_juryozumi     CONSTANT  VARCHAR2(2)   := '07' ;             -- 受領済
  gc_ship_status_delete       CONSTANT  VARCHAR2(2)   := '99' ;             -- 取消
  -- 出荷支給区分
  gc_ship_pro_kbn_shu         CONSTANT  VARCHAR2(1)   := '1' ;              -- 出荷依頼
  gc_ship_pro_kbn_sik         CONSTANT  VARCHAR2(1)   := '2' ;              -- 支給依頼
  -- 受注カテゴリ
  gc_order_cate_ret           CONSTANT  VARCHAR2(10)  := 'RETURN' ;         -- 返品（受注のみ）
  -- 通知ステータス
  gc_fixa_notif_yet           CONSTANT  VARCHAR2(2)   := '10' ;             -- 未通知
  gc_fixa_notif_re            CONSTANT  VARCHAR2(2)   := '20' ;             -- 再通知要
  gc_fixa_notif_end           CONSTANT  VARCHAR2(2)   := '40' ;             -- 確定通知済
  -- 移動ステータス
  gc_move_status_ordered      CONSTANT  VARCHAR2(2)   := '02' ;             -- 依頼済
  gc_move_status_not          CONSTANT  VARCHAR2(2)   := '99' ;             -- 取消
  -- 移動タイプ
  gc_mov_type_not_ship        CONSTANT  VARCHAR2(5)   := '2' ;              -- 積送なし
  -- 業務種別
  gc_biz_type_cd_ship         CONSTANT  VARCHAR2(1)   := '1' ;              -- 出荷
  gc_biz_type_cd_shikyu       CONSTANT  VARCHAR2(1)   := '2' ;              -- 支給
  gc_biz_type_cd_move         CONSTANT  VARCHAR2(1)   := '3' ;              -- 移動
-- 2008/07/09 add S.Takemoto start
  gc_biz_type_cd_etc          CONSTANT  VARCHAR2(1)   := '4' ;              -- その他
-- 2008/07/09 add S.Takemoto end
  gc_biz_type_nm_ship         CONSTANT  VARCHAR2(4)   := '出荷' ;           -- 出荷
  gc_biz_type_nm_shik         CONSTANT  VARCHAR2(4)   := '支給' ;           -- 支給
  gc_biz_type_nm_move         CONSTANT  VARCHAR2(4)   := '移動' ;           -- 移動
-- 2008/07/09 add S.Takemoto start
  gc_biz_type_nm_etc          CONSTANT  VARCHAR2(6)   := 'その他' ;              -- その他
-- 2008/07/09 add S.Takemoto end
  -- 最新フラグ
  gc_latest_external_flag     CONSTANT  VARCHAR2(1)   := 'Y' ;
  -- 削除・取消フラグ
  gc_delete_flg               CONSTANT  VARCHAR2(1)   := 'Y' ;
  -- 運送依頼元印字区分
  gc_trans_req_prt_enable     CONSTANT  VARCHAR2(1)   := '1' ;              -- 印字あり
--
  -- 締め実施時間
  gc_shime_time_from_def      CONSTANT  VARCHAR2(5)   := '00:00' ;
  gc_shime_time_to_def        CONSTANT  VARCHAR2(5)   := '23:59' ;
-- 2008/07/09 add S.Takemoto start
  gc_non_slip_class_2         CONSTANT  VARCHAR2(1)   := '2' ;              -- 2:伝票なし配車
  gc_deliver_to_class_1       CONSTANT  VARCHAR2(1)   := '1' ;              -- 1:拠点
  gc_deliver_to_class_4       CONSTANT  VARCHAR2(1)   := '4' ;              -- 4:移動
  gc_deliver_to_class_10      CONSTANT  VARCHAR2(2)   := '10' ;             -- 10:顧客
  gc_deliver_to_class_11      CONSTANT  VARCHAR2(2)   := '11' ;             -- 11:支給先
  gc_freight_charge_code_1    CONSTANT  VARCHAR2(1)   := '1' ;              -- 1:対象
  gc_output_code_1            CONSTANT  VARCHAR2(1)   := '1' ;              -- 1:対象
-- 2008/07/09 add S.Takemoto end
-- 2008/11/13 Y.Yamamoto v1.15 add start
  gc_no_instr_actual_class_y  CONSTANT  VARCHAR2(1)   := 'Y' ;              -- 指示なし実績区分
-- 2008/11/13 Y.Yamamoto v1.15 add end
-- 2009/02/04 Y.Kanami 本番#41対応 Start --
  -- ロット管理
  gc_lot_ctl_manage          CONSTANT  VARCHAR2(1)  := '1' ;                -- ロット管理されている
-- 2009/02/04 Y.Kanami 本番#41対応 End ----
-- 2009/04/24 H.Itou   本番#1398対応 START --
  -- マスタステータス
  gc_status_active        CONSTANT VARCHAR2(1) := 'A' ;     -- 有効
  gc_status_inactive      CONSTANT VARCHAR2(1) := 'I' ;     -- 無効
-- 2009/04/24 H.Itou   本番#1398対応 END ----
  ------------------------------
  -- プロファイル関連
  ------------------------------
-- 2016/06/01 K.Kiriu v1.22 del start
--  -- 事業所コード（伊藤園産業）
--  gc_prof_loc_cd_sg           CONSTANT VARCHAR2(22)   := 'XXWSH_LOCATION_CODE_SG' ;
-- 2016/06/01 K.Kiriu v1.22 del end
  -- 会社名（伊藤園）
  gc_prof_company_nm          CONSTANT VARCHAR2(18)   := 'XXWSH_COMPANY_NAME' ;
  -- 出荷重量単位
  gc_prof_weight_uom          CONSTANT VARCHAR2(16)   := 'XXWSH_WEIGHT_UOM' ;
  -- 出荷容積単位
  gc_prof_capacity_uom        CONSTANT VARCHAR2(18)   := 'XXWSH_CAPACITY_UOM' ;
  -- 商品区分
  gc_prof_name_item_div       CONSTANT VARCHAR2(30)   := 'XXCMN_ITEM_DIV_SECURITY' ;
-- 2016/06/01 K.Kiriu v1.22 add start
  -- 事業所コード62C_01_ドリンク(運送発注元)
  gc_prof_62c01_loc_cd_dr     CONSTANT VARCHAR2(28)   := 'XXWSH_62C01_LOCATION_CODE_DR';
  -- 事業所コード62C_01_リーフ(運送発注元)
  gc_prof_62c01_loc_cd_lf     CONSTANT VARCHAR2(28)   := 'XXWSH_62C01_LOCATION_CODE_LF';
  -- 事業所コード62C_02_ドリンク(運送依頼元)
  gc_prof_62c02_loc_cd_dr     CONSTANT VARCHAR2(28)   := 'XXWSH_62C02_LOCATION_CODE_DR';
  -- 事業所コード62C_02_リーフ(運送依頼元)
  gc_prof_62c02_loc_cd_lf     CONSTANT VARCHAR2(28)   := 'XXWSH_62C02_LOCATION_CODE_LF';
-- 2016/06/01 K.Kiriu v1.22 add end
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  --アプリケーション名
  gc_application_wsh          CONSTANT  VARCHAR2(5)    := 'XXWSH' ;         -- ｱﾄﾞｵﾝ:出荷･引当･配車
  gc_application_cmn          CONSTANT  VARCHAR2(5)    := 'XXCMN' ;         -- ｱﾄﾞｵﾝ:
  --メッセージID
  gc_msg_id_required          CONSTANT  VARCHAR2(15)  := 'APP-XXWSH-12102' ;  -- ﾊﾟﾗﾒｰﾀ未入力ｴﾗｰ
  gc_msg_id_not_get_prof      CONSTANT  VARCHAR2(15)  := 'APP-XXWSH-12301' ;  -- ﾌﾟﾛﾌｧｲﾙ取得ｴﾗｰ
  gc_msg_id_no_data           CONSTANT  VARCHAR2(15)  := 'APP-XXCMN-10122' ;  -- 帳票0件エラー
  gc_msg_id_shime_time        COnSTANT  VARCHAR2(15)  := 'APP-XXWSH-12256' ;  -- 締め日付未入力
-- 2016/06/01 K.Kiriu v1.22 add start
  gc_mst_prof_value           CONSTANT  VARCHAR2(15)  := 'APP-XXWSH-13191' ;  -- プロファイル値不正エラー
  gc_msg_62c01_loc_cd_dr      CONSTANT  VARCHAR2(15)  := 'APP-XXWSH-33309' ;  -- 文言(XXWSH:事業所コード62C_01_ドリンク)
  gc_msg_62c01_loc_cd_lf      CONSTANT  VARCHAR2(15)  := 'APP-XXWSH-33310' ;  -- 文言(XXWSH:事業所コード62C_01_リーフ)
  gc_msg_62c02_loc_cd_dr      CONSTANT  VARCHAR2(15)  := 'APP-XXWSH-33311' ;  -- 文言(XXWSH:事業所コード62C_02_ドリンク)
  gc_msg_62c02_loc_cd_lf      CONSTANT  VARCHAR2(15)  := 'APP-XXWSH-33312' ;  -- 文言(XXWSH:事業所コード62C_02_リーフ)
-- 2016/06/01 K.Kiriu v1.22 add end
  --メッセージ-トークン名
  gc_msg_tkn_nm_parmeta       CONSTANT  VARCHAR2(10)  := 'PARMETA' ;          -- パラメータ名
  gc_msg_tkn_nm_prof          CONSTANT  VARCHAR2(10)  := 'PROF_NAME' ;        -- プロファイル名
  --メッセージ-トークン値
  gc_msg_tkn_val_parmeta1     CONSTANT  VARCHAR2(20)  := '運送業者' ;
  gc_msg_tkn_val_parmeta2     CONSTANT  VARCHAR2(20)  := '確定通知実施日' ;
-- 2016/06/01 K.Kiriu v1.22 del start
--  gc_msg_tkn_val_prof_prod1   CONSTANT  VARCHAR2(30)  := 'XXWSH:事業所コード(伊藤園産業)' ;
-- 2016/06/01 K.Kiriu v1.22 del end
  gc_msg_tkn_val_prof_prod2   CONSTANT  VARCHAR2(30)  := '会社名(伊藤園)' ;
  gc_msg_tkn_val_prof_prod3   CONSTANT  VARCHAR2(30)  := 'XXWSH:出荷重量単位' ;
  gc_msg_tkn_val_prof_prod4   CONSTANT  VARCHAR2(30)  := 'XXWSH:出荷容積単位' ;
  gc_msg_tkn_val_prof_prod5   CONSTANT  VARCHAR2(30)  := 'XXCMN：商品区分(セキュリティ)' ;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  ------------------------------
  -- 出力データ関連
  ------------------------------
  -- レコード宣言用
  xcs         xxwsh_carriers_schedule%ROWTYPE ;         -- 配車配送計画(アドオン)
  xoha        xxwsh_order_headers_all%ROWTYPE ;         -- 受注ヘッダアドオン
  xott2v      xxwsh_oe_transaction_types2_v%ROWTYPE ;   -- 受注タイプ情報VIEW2
  xola        xxwsh_order_lines_all%ROWTYPE ;           -- 受注明細アドオン
  xmld        xxinv_mov_lot_details%ROWTYPE ;           -- 移動ロット詳細(アドオン)
  ilm         ic_lots_mst%ROWTYPE ;                     -- OPMロットマスタ
  xil2v       xxcmn_item_locations2_v%ROWTYPE ;         -- OPM保管場所情報VIEW2
  xcas2v      xxcmn_cust_acct_sites2_v%ROWTYPE ;        -- 顧客サイト情報VIEW2
  xc2v        xxcmn_carriers2_v%ROWTYPE ;               -- 運送業者情報VIEW2
  xim2v       xxcmn_item_mst2_v%ROWTYPE ;               -- OPM品目情報VIEW2
  xic4v       xxcmn_item_categories4_v%ROWTYPE ;        -- OPM品目カテゴリ割当情報VIEW4
  xtc         xxwsh_tightening_control%ROWTYPE ;        -- 出荷依頼締め管理(アドオン)
  xl2v        xxcmn_locations2_v%ROWTYPE ;              -- 事業所情報VIEW2
  fu          fnd_user%ROWTYPE ;                        -- ユーザーマスタ
  xsm2v       xxwsh_ship_method2_v%ROWTYPE ;            -- 配送区分情報VIEW2
--
  xca2v       xxcmn_cust_accounts2_v%ROWTYPE ;          -- 顧客情報VIEW2
  xmrih       xxinv_mov_req_instr_headers%ROWTYPE ;     -- 移動依頼 指示ヘッダ(アドオン)
--
  ------------------------------
  -- 入力パラメータ関連
  ------------------------------
  -- 入力パラメータ格納用レコード
  TYPE rec_param_data IS RECORD(
     iv_dept                    VARCHAR2(10)                    --  01 : 部署
    ,iv_plan_decide_kbn         VARCHAR2(1)                     --  02 : 予定/確定区分
    ,iv_ship_from               DATE                            --  03 : 出庫日From
    ,iv_ship_to                 DATE                            --  04 : 出庫日To
    ,iv_shukko_haisou_kbn       VARCHAR2(1)                     --  05 : 出庫/配送区分
    ,iv_gyoumu_shubetsu         VARCHAR2(1)                     --  06 : 業務種別
    ,iv_notif_date              DATE                            --  07 : 確定通知実施日
    ,iv_notif_time_from         VARCHAR2(5)                     --  08 : 確定通知実施時間From
    ,iv_notif_time_to           VARCHAR2(5)                     --  09 : 確定通知実施時間To
    --,iv_freight_carrier_code    xoha.career_id%TYPE             --  10 : 運送業者    --2008/07/04 ST不具合対応#409
    ,iv_freight_carrier_code    xoha.freight_carrier_code%TYPE  --  10 : 運送業者      --2008/07/04 ST不具合対応#409
    ,iv_block1                  VARCHAR2(5)                     --  11 : ブロック1
    ,iv_block2                  VARCHAR2(5)                     --  12 : ブロック2
    ,iv_block3                  VARCHAR2(5)                     --  13 : ブロック3
    ,iv_shipped_locat_code      VARCHAR2(4)                     --  14 : 出庫元
    ,iv_mov_num                 VARCHAR2(12)                    --  15 : 依頼No/移動No
    ,iv_shime_date              DATE                            --  16 : 締め実施日
    ,iv_shime_time_from         VARCHAR2(5)                     --  17 : 締め実施時間From
    ,iv_shime_time_to           VARCHAR2(5)                     --  18 : 締め実施時間To
    ,iv_online_kbn              VARCHAR2(1)                     --  19 : オンライン対象区分
    ,iv_item_kbn                VARCHAR2(1)                     --  20 : 品目区分
    ,iv_shukko_keitai           VARCHAR2(240)                   --  21 : 出庫形態
    ,iv_unsou_irai_inzi_kbn     VARCHAR2(1)                     --  22 : 運送依頼元印字区分
  );
  type_rec_param_data   rec_param_data ;
--
  -- 出力データ格納用レコード
  TYPE rec_report_data IS RECORD
  (
-- 2008/07/09 mod S.Takemoto start
--     gyoumu_shubetsu            VARCHAR2(4)                           -- 業務種別
     gyoumu_shubetsu            VARCHAR2(6)                           -- 業務種別
-- 2008/07/09 mod S.Takemoto end
    ,gyoumu_shubetsu_code       VARCHAR2(1)                           -- 業務種別コード
    ,freight_carrier_code       xoha.freight_carrier_code%TYPE        -- 運送業者
    ,carrier_full_name          xc2v.party_name%TYPE                  -- 運送業者(名称)
    ,deliver_from               xoha.deliver_from%TYPE                -- 出庫元
    ,description                xil2v.description%TYPE                -- 出庫元(名称)
    ,schedule_ship_date         xoha.schedule_ship_date%TYPE          -- 出庫日
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620指摘47 ソート順変更
    ,item_class_code            xic4v.item_class_code%TYPE            -- 品目区分
-- 2008/10/27 mod end 1.13 
    ,item_class_name            xic4v.item_class_name%TYPE            -- 品目区分名
    ,new_modify_flg             xoha.new_modify_flg%TYPE              -- 新規修正フラグ
    ,schedule_arrival_date      xoha.schedule_arrival_date%TYPE       -- 着日
    ,delivery_no                xoha.delivery_no%TYPE                 -- 配送No
    ,shipping_method_code       xoha.shipping_method_code%TYPE        -- 配送区分
    ,ship_method_meaning        xsm2v.ship_method_meaning%TYPE        -- 配送区分名称
    ,head_sales_branch          xoha.head_sales_branch%TYPE           -- 管轄拠点
    ,party_name                 xca2v.party_name%TYPE                 -- 管轄拠点(名称)
    ,deliver_to                 xoha.deliver_to%TYPE                  -- 配送先
    ,party_site_full_name       xcas2v.party_site_full_name%TYPE      -- 配送先(正式名)
    ,address_line1              xxcmn_locations2_v.address_line1%TYPE -- 配送先(住所1)
    ,address_line2              xcas2v.address_line2%TYPE             -- 配送先(住所2)
    ,phone                      xcas2v.phone%TYPE                     -- 配送先(電話番号)
    ,arrival_time_from          xoha.arrival_time_from%TYPE           -- 時間指定From
    ,arrival_time_to            xoha.arrival_time_to%TYPE             -- 時間指定To
    ,sum_loading_capacity       xcs.sum_loading_capacity%TYPE         -- 混載体積
    ,sum_loading_weight         xcs.sum_loading_weight%TYPE           -- 混載重量
    ,req_mov_no                 xoha.request_no%TYPE                  -- 依頼No/移動No
    ,sum_weightm_capacity       NUMBER                                -- 重量体積(依頼No.単位)
    ,sum_weightm_capacity_t     VARCHAR2(240)                         -- 単位
    ,tehai_no                   xmrih.batch_no%TYPE                   -- 手配No
    ,prev_delivery_no           xoha.prev_delivery_no%TYPE            -- 前回配送No
-- 2009/12/15 H.Itou Mod Start 本稼動障害#XXXX
--    ,po_no                      xoha.po_no%TYPE                       -- PoNo
    ,po_no                      xoha.cust_po_number%TYPE              -- PoNo
-- 2009/12/15 H.Itou Mod End
    ,jpr_user_code              xcas2v.jpr_user_code%TYPE             -- JPRユーザコード
    ,collected_pallet_qty       xoha.collected_pallet_qty%TYPE        -- パレット回収枚数
    ,shipping_instructions      xoha.shipping_instructions%TYPE       -- 摘要
    ,slip_number                xoha.slip_number%TYPE                 -- 送り状No
    ,small_quantity             xoha.small_quantity%TYPE              -- 個数
    ,item_code                  xola.shipping_item_code%TYPE          -- 品目(コード)
    ,item_name                  xim2v.item_short_name%TYPE            -- 品目(名称)
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620指摘47 ソート順変更
    ,lot_id                     xmld.lot_id%TYPE                      -- ロットID
-- 2008/10/27 mod end 1.13 
    ,lot_no                     xmld.lot_no%TYPE                      -- ロットNo
    ,attribute1                 ilm.attribute1%TYPE                   -- 製造日
    ,attribute3                 ilm.attribute3%TYPE                   -- 賞味期限
    ,attribute2                 ilm.attribute2%TYPE                   -- 固有記号
    ,num_of_cases               xim2v.num_of_cases%TYPE               -- 入数
    ,net                        xim2v.net%TYPE                        -- 重量(NET)
    ,qty                        xmld.actual_quantity%TYPE             -- 数量
    ,conv_unit                  xim2v.conv_unit%TYPE                  -- 入出庫換算単位
    
  );
  type_report_data      rec_report_data;
  TYPE list_report_data IS TABLE OF rec_report_data INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
-- 2016/06/01 K.Kiriu v1.22 del start
--  gv_loc_cd_sg          VARCHAR2(20);                               -- 伊藤園産業事業所コード
-- 2016/06/01 K.Kiriu v1.22 del end
  gv_company_nm         VARCHAR2(20);                               -- 会社名
  gv_uom_weight         VARCHAR2(3);                                -- 出荷重量単位
  gv_uom_capacity       VARCHAR2(3);                                -- 出荷容積単位
--
  gt_report_data        list_report_data ;                          -- 出力データ
  gv_report_title       VARCHAR2(20) ;                              -- 帳票タイトル
  gt_xml_data_table     XML_DATA ;                                  -- XMLデータ
  gt_param              rec_param_data ;                            -- 入力パラメータ情報
-- 2016/06/01 K.Kiriu v1.22 del start
--  gv_dept_cd            VARCHAR2(10) ;                              -- 担当部署
-- 2016/06/01 K.Kiriu v1.22 del end
  -- MOD START 2008/06/04 NAKADA gv_user_nmを新規に追加。gv_dept_nmを担当部署名用とし、桁数変更
  gv_dept_nm            VARCHAR2(20) ;                              -- 担当部署名
  gv_user_nm            VARCHAR2(14) ;                              -- 担当者
  -- MOD END   2008/06/04 NAKADA
  -- 運送発注元
  gv_hchu_postal_code        xxcmn_locations_all.zip%TYPE ;           -- 郵便番号
  gv_hchu_address_value      xxcmn_locations_all.address_line1%TYPE ; -- 住所
  gv_hchu_tel_value          xxcmn_locations_all.phone%TYPE ;         -- 電話番号
  gv_hchu_fax_value          xxcmn_locations_all.fax%TYPE ;           -- FAX番号
  gv_hchu_cat_value          xxcmn_locations_all.location_name%TYPE ; -- 部署名称
  -- 運送依頼元
  gv_irai_postal_code        xxcmn_locations_all.zip%TYPE ;           -- 郵便番号
  gv_irai_address_value      xxcmn_locations_all.address_line1%TYPE ; -- 住所
  gv_irai_tel_value          xxcmn_locations_all.phone%TYPE ;         -- 電話番号
  gv_irai_fax_value          xxcmn_locations_all.fax%TYPE ;           -- FAX番号
  gv_irai_cat_value          xxcmn_locations_all.location_name%TYPE ; -- 部署名称
  gv_irai_cat_value_full     VARCHAR2(74);                            -- 部署名称＋会社名
-- 2016/06/01 K.Kiriu v1.22 add start
  gv_62c01_loc_cd            fnd_profile_option_values.profile_option_value%TYPE;  --運送発注元事業所コード
  gv_62c02_loc_cd            fnd_profile_option_values.profile_option_value%TYPE;  --運送依頼元事業所コード
-- 2016/06/01 K.Kiriu v1.22 add end
--
  gv_prod_kbn           VARCHAR2(1);                                  -- 商品区分
--
  gd_common_sysdate     DATE;                                         -- システム日付
--
  gv_papf_attribute3  per_all_people_f.attribute3%TYPE ; -- ユーザーが内部倉庫:"1" 外部倉庫:"2" 2008/07/04 ST不具合対応#394
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 初期処理(F-1,F-2,F-3)
   ***********************************************************************************/
  PROCEDURE prc_initialize(
    ov_errbuf     OUT  VARCHAR2         -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT  VARCHAR2         -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT  VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT  VARCHAR2(100) := 'prc_initialize' ;  -- プログラム名
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
-- 2016/06/01 K.Kiriu v1.22 add start
    lv_tkn_msg         VARCHAR2(2000); -- トークン取得用
-- 2016/06/01 K.Kiriu v1.22 add end
    -- *** ローカル・例外処理 ***
    prm_check_expt     EXCEPTION ;     -- パラメータチェック例外
    get_prof_expt      EXCEPTION ;     -- プロファイル取得例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- 変数初期設定
    -- ===============================================
    gd_common_sysdate :=  SYSDATE ;   -- システム日付
--
    -- ====================================================
    -- プロファイル値取得(F-1)
    -- ====================================================
-- 2016/06/01 K.Kiriu v1.22 del start
--    -- 「XXWSH:事業所コード（伊藤園産業）」
--    gv_loc_cd_sg := FND_PROFILE.VALUE(gc_prof_loc_cd_sg) ;
--    IF (gv_loc_cd_sg IS NULL) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
--                                            ,gc_msg_id_not_get_prof
--                                            ,gc_msg_tkn_nm_prof
--                                            ,gc_msg_tkn_val_prof_prod1
--                                           ) ;
--      RAISE get_prof_expt ;
--    END IF ;
-- 2016/06/01 K.Kiriu v1.22 del end
--
    -- 「XXWSH:会社名（伊藤園）」
    gv_company_nm := FND_PROFILE.VALUE(gc_prof_company_nm) ;
    IF (gv_company_nm IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_prod2
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- 「XXWSH:出荷重量単位」
    gv_uom_weight := FND_PROFILE.VALUE(gc_prof_weight_uom) ;
    IF (gv_uom_weight IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_prod3
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- 「XXWSH:出荷容積単位」
    gv_uom_capacity := FND_PROFILE.VALUE(gc_prof_capacity_uom) ;
    IF (gv_uom_capacity IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_prod4
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
-- 2008/11/20 Y.Yamamoto v1.16 delete start
    -- 内部ユーザーでのみ取得するため、下の従業員区分の取得後に移動
    -- 職責：商品区分(セキュリティ)取得
--    gv_prod_kbn := FND_PROFILE.VALUE(gc_prof_name_item_div) ;
--    IF (gv_prod_kbn IS NULL) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
--                                            ,gc_msg_id_not_get_prof
--                                            ,gc_msg_tkn_nm_prof
--                                            ,gc_msg_tkn_val_prof_prod5
--                                           ) ;
--      RAISE get_prof_expt ;
--    END IF ;
-- 2008/11/20 Y.Yamamoto v1.16 delete end
--
    -- ====================================================
    -- パラメータチェック(F-2)
    -- ====================================================
    -- 2008/07/07 ST不具合対応#337 配送の場合でもパラメータ運送業者を必須としない
    ---- パラメータ出庫/配送区分の値が、配送の場合にパラメータ運送業者を必須とします。
    --IF ( gt_param.iv_shukko_haisou_kbn = gc_shukko_haisou_kbn_d ) THEN
    --  IF ( gt_param.iv_freight_carrier_code IS NULL ) THEN
    --    -- メッセージセット
    --    lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
    --                                          ,gc_msg_id_required
    --                                          ,gc_msg_tkn_nm_parmeta
    --                                          ,gc_msg_tkn_val_parmeta1
    --                                         ) ;
    --    RAISE prm_check_expt ;
    --  END IF ;
    --END IF ;
    --
--
    -- パラメータ予定/確定区分が確定の場合、確定通知実施日を必須とします。
    --2008/07/04 ST不具合対応#394 但しユーザーが内部倉庫の場合だけ必須チェックする（外部倉庫の場合は行わない）
    SELECT
      NVL(papf.attribute3,gc_user_kbn_inside)  --NULLのユーザーは内部倉庫扱い
    INTO
      gv_papf_attribute3
    FROM fnd_user fu 
        ,per_all_people_f papf
    WHERE fu.user_id     = FND_GLOBAL.USER_ID
-- 2008/11/07 Y.Yamamoto v1.14 update start
--      AND fu.employee_id = papf.person_id;
      AND fu.employee_id = papf.person_id
      AND TRUNC( SYSDATE ) BETWEEN papf.effective_start_date 
                               AND NVL(papf.effective_end_date,TRUNC( SYSDATE ))
    ;
-- 2008/11/07 Y.Yamamoto v1.14 update end
    --2008/07/04 ST不具合対応#394
-- 2008/11/20 Y.Yamamoto v1.16 add start
    -- 内部ユーザーの場合、取得する
    -- 職責：商品区分(セキュリティ)取得
    IF (gv_papf_attribute3 = gc_user_kbn_inside) THEN
      gv_prod_kbn := FND_PROFILE.VALUE(gc_prof_name_item_div) ;
      IF (gv_prod_kbn IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                              ,gc_msg_id_not_get_prof
                                              ,gc_msg_tkn_nm_prof
                                              ,gc_msg_tkn_val_prof_prod5
                                             ) ;
        RAISE get_prof_expt ;
      END IF ;
    END IF;
-- 2008/11/20 Y.Yamamoto v1.16 add end
--
-- 2008/10/27 del start1.13 統合指摘297 確定実施日は必須から任意に変更する。
--    IF ( gv_papf_attribute3 = gc_user_kbn_inside ) THEN  --2008/07/04 ST不具合対応#394
--      IF ( gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN -- パラメータ予定/確定区分が確定の場合
--        IF ( gt_param.iv_notif_date IS NULL ) THEN
--          -- メッセージセット
--          lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
--                                                ,gc_msg_id_required
--                                                ,gc_msg_tkn_nm_parmeta
--                                                ,gc_msg_tkn_val_parmeta2
--                                               ) ;
--          RAISE prm_check_expt ;
--        END IF ;
--      END IF ;
--    END IF ;
-- 2008/10/27 del end 1.13
-- 2016/06/01 K.Kiriu v1.22 add start
    -- パラメータ運送依頼元印字区分が印字あり(内部ユーザ)の場合
    IF ( gt_param.iv_unsou_irai_inzi_kbn = gc_trans_req_prt_enable ) THEN
      -- 職責：商品区分(セキュリティ)がリーフの場合
      IF ( gv_prod_kbn = gc_prod_cd_leaf ) THEN
        --「XXWSH:事業所コード62C_01_リーフ」(運送発注元事業所)
        gv_62c01_loc_cd := FND_PROFILE.VALUE(gc_prof_62c01_loc_cd_lf) ;
        IF (gv_62c01_loc_cd IS NULL) THEN
          -- トークン取得
          lv_tkn_msg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                                 ,gc_msg_62c01_loc_cd_lf
                                                ) ;
          -- メッセージ生成
          lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                                ,gc_msg_id_not_get_prof
                                                ,gc_msg_tkn_nm_prof
                                                ,lv_tkn_msg
                                               ) ;
          RAISE get_prof_expt ;
        END IF ;
        --「XXWSH:事業所コード62C_02_リーフ」(運送依頼元事業所)
        gv_62c02_loc_cd := FND_PROFILE.VALUE(gc_prof_62c02_loc_cd_lf) ;
        IF (gv_62c02_loc_cd IS NULL) THEN
          -- トークン取得
          lv_tkn_msg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                                 ,gc_msg_62c02_loc_cd_lf
                                                ) ;
          -- メッセージ生成
          lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                                ,gc_msg_id_not_get_prof
                                                ,gc_msg_tkn_nm_prof
                                                ,lv_tkn_msg
                                               ) ;
          RAISE get_prof_expt ;
        END IF ;
      -- 職責：商品区分(セキュリティ)がドリンクの場合
      ELSIF ( gv_prod_kbn = gc_prod_cd_drink) THEN
        --「XXWSH:事業所コード62C_01_ドリンク」(運送発注元事業所)
        gv_62c01_loc_cd := FND_PROFILE.VALUE(gc_prof_62c01_loc_cd_dr) ;
        IF (gv_62c01_loc_cd IS NULL) THEN
          -- トークン取得
          lv_tkn_msg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                                 ,gc_msg_62c01_loc_cd_dr
                                                ) ;
          -- メッセージ生成
          lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                                ,gc_msg_id_not_get_prof
                                                ,gc_msg_tkn_nm_prof
                                                ,lv_tkn_msg
                                               ) ;
          RAISE get_prof_expt ;
        END IF ;
        --「XXWSH:事業所コード62C_02_ドリンク」(運送依頼元事業所)
        gv_62c02_loc_cd := FND_PROFILE.VALUE(gc_prof_62c02_loc_cd_dr) ;
        IF (gv_62c02_loc_cd IS NULL) THEN
          -- トークン取得
          lv_tkn_msg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                                 ,gc_msg_62c02_loc_cd_dr
                                                ) ;
          -- メッセージ生成
          lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                                ,gc_msg_id_not_get_prof
                                                ,gc_msg_tkn_nm_prof
                                                ,lv_tkn_msg
                                               ) ;
          RAISE get_prof_expt ;
        END IF ;
      -- 職責：商品区分(セキュリティ)がリーフでもドリンクでもない場合
      ELSE
        -- 職責：商品区分(セキュリティ)不正エラー
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                              ,gc_mst_prof_value
                                              ,gc_msg_tkn_nm_prof
                                              ,gc_msg_tkn_val_prof_prod5
                                             ) ;
        RAISE get_prof_expt ;
      END IF;
    END IF;
-- 2016/06/01 K.Kiriu v1.22 add end
    -- パラメータ締め実施日が未入力の場合に、締め実施時間FromかToに入力があった場合、
    -- エラーとする。
    IF ( gt_param.iv_shime_date IS NULL ) THEN
      IF  ( ( gt_param.iv_shime_time_from IS NOT NULL )
        OR  ( gt_param.iv_shime_time_to   IS NOT NULL ) ) THEN
        -- メッセージセット
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                              ,gc_msg_id_shime_time
                                             ) ;
        RAISE prm_check_expt ;
      END IF ;
    ELSE
      -- パラメータ締め実施日が入力されており、締め実施時間FromかToに入力がなかった場合、
      -- デフォルト値が設定される。
      IF ( gt_param.iv_shime_time_from IS NULL ) THEN
        gt_param.iv_shime_time_from :=  gc_shime_time_from_def ;
      END IF ;
--
      IF ( gt_param.iv_shime_time_to IS NULL ) THEN
        gt_param.iv_shime_time_to :=  gc_shime_time_to_def ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- ヘッダ情報抽出(F-3)
    -- ====================================================
    -- ====================================================
    -- 担当者情報取得
    -- ====================================================
-- 2016/06/01 K.Kiriu v1.22 del start
--    -- 担当部署コード
--    gv_dept_cd := SUBSTRB(xxcmn_common_pkg.get_user_dept_code(FND_GLOBAL.USER_ID), 1, 10) ;
-- 2016/06/01 K.Kiriu v1.22 del end
--
    --担当部署名
    -- ADD START 2008/06/04 NAKADA
    gv_dept_nm := SUBSTRB(xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID), 1, 10) ;
    -- ADD END   2008/06/04 NAKADA
--
    -- 担当者
    gv_user_nm := SUBSTRB(xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID), 1, 14) ;
--
    IF ( gt_param.iv_unsou_irai_inzi_kbn = gc_trans_req_prt_enable ) THEN
      ----------------------------------------------------------------------
      -- 運送発注元
      ----------------------------------------------------------------------
      -- 住所、電話番号、部署正式名取得
      xxcmn_common_pkg.get_dept_info
      (
-- 2016/06/01 K.Kiriu v1.22 mod start
--         iv_dept_cd           =>  gv_loc_cd_sg          -- プロファイルより伊藤園産業の事業所コード
         iv_dept_cd           =>  gv_62c01_loc_cd         -- プロファイルより事業所コード(職責による)
-- 2016/06/01 K.Kiriu v1.22 mod end
        ,id_appl_date         =>  SYSDATE               -- 基準日
        ,ov_postal_code       =>  gv_hchu_postal_code   -- 郵便番号
        ,ov_address           =>  gv_hchu_address_value -- 住所
        ,ov_tel_num           =>  gv_hchu_tel_value     -- 電話番号
        ,ov_fax_num           =>  gv_hchu_fax_value     -- FAX番号
        ,ov_dept_formal_name  =>  gv_hchu_cat_value     -- 部署正式名
        ,ov_errbuf            =>  lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,ov_retcode           =>  lv_retcode            -- リターン・コード             --# 固定 #
        ,ov_errmsg            =>  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
      ----------------------------------------------------------------------
--
      ----------------------------------------------------------------------
      -- 運送依頼元
      ----------------------------------------------------------------------
      -- 住所、電話番号、部署正式名取得
      xxcmn_common_pkg.get_dept_info
      (
-- 2016/06/01 K.Kiriu v1.22 mod start
--         iv_dept_cd           =>  gv_dept_cd            -- 担当部署
         iv_dept_cd           =>  gv_62c02_loc_cd       -- プロファイルより事業所コード(職責による)
-- 2016/06/01 K.Kiriu v1.22 mod end
        ,id_appl_date         =>  SYSDATE               -- 基準日
        ,ov_postal_code       =>  gv_irai_postal_code   -- 郵便番号
        ,ov_address           =>  gv_irai_address_value -- 住所
        ,ov_tel_num           =>  gv_irai_tel_value     -- 電話番号
        ,ov_fax_num           =>  gv_irai_fax_value     -- FAX番号
        ,ov_dept_formal_name  =>  gv_irai_cat_value     -- 部署正式名
        ,ov_errbuf            =>  lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,ov_retcode           =>  lv_retcode            -- リターン・コード             --# 固定 #
        ,ov_errmsg            =>  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
--
      -- 部署正式名には会社名が含まれていないので、文字列連結を行う。
      -- MOD START 2008/06/04 NAKADA 文字結合の順序を会社名 部署名の順に修正
      gv_irai_cat_value_full  :=  SUBSTRB(gv_company_nm || gv_irai_cat_value, 1, 74) ;
      -- MOD END 2008/06/04 NAKADA
--
      ----------------------------------------------------------------------
    ELSE
      gv_hchu_postal_code     :=  NULL ;
      gv_hchu_address_value   :=  NULL ;
      gv_hchu_tel_value       :=  NULL ;
      gv_hchu_fax_value       :=  NULL ;
      gv_hchu_cat_value       :=  NULL ;
--
      gv_irai_postal_code     :=  NULL ;
      gv_irai_address_value   :=  NULL ;
      gv_irai_tel_value       :=  NULL ;
      gv_irai_fax_value       :=  NULL ;
      gv_irai_cat_value       :=  NULL ;
    END IF ;
--
  EXCEPTION
    --*** パラメータチェック例外ハンドラ ***
    WHEN prm_check_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
    --*** プロファイル取得例外ハンドラ ***
    WHEN get_prof_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_initialize;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : 帳票データ取得処理(F-4)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
     ov_errbuf      OUT   VARCHAR2      --   エラー・メッセージ           --# 固定 #
    ,ov_retcode     OUT   VARCHAR2      --   リターン・コード             --# 固定 #
    ,ov_errmsg      OUT   VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data' ;  -- プログラム名
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
    -- *** ローカル・カーソル ***
    -- カーソル宣言
    -- カーソルタイプ
    TYPE  cur_typ IS  ref CURSOR;
    -- カーソル定義
    c_cur   cur_typ;
    -- 動的SQL格納変数
    lv_sql_head           VARCHAR2(32767);
    lv_sql_shu_sel_from1  VARCHAR2(32767);
    lv_sql_shu_sel_from2  VARCHAR2(32767);
    lv_sql_shu_where1     VARCHAR2(32767);
    lv_sql_shu_where2     VARCHAR2(32767);
    lv_sql_sik_sel_from1  VARCHAR2(32767);
    lv_sql_sik_sel_from2  VARCHAR2(32767);
    lv_sql_sik_where1     VARCHAR2(32767);
    lv_sql_sik_where2     VARCHAR2(32767);
    lv_sql_ido_sel_from1  VARCHAR2(32767);
    lv_sql_ido_sel_from2  VARCHAR2(32767);
    lv_sql_ido_where1     VARCHAR2(32767);
    lv_sql_ido_where2     VARCHAR2(32767);
-- 2008/07/09 add S.Takemoto start
    lv_sql_etc_sel_from1  VARCHAR2(32767);
    lv_sql_etc_sel_from2  VARCHAR2(32767);
    lv_sql_etc_where1     VARCHAR2(32767);
    lv_sql_etc_where2     VARCHAR2(32767);
-- 2008/07/09 add S.Takemoto end
    lv_sql_tail           VARCHAR2(32767);
--add start 1.2
    lb_union              BOOLEAN := FALSE;
--add end 1.2
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 帳票タイトル判定
    -- ====================================================
    -- 出庫/配送区分が「配送」の場合
    IF ( gt_param.iv_shukko_haisou_kbn = gc_shukko_haisou_kbn_d ) THEN
--
      -- 予定/確定区分が「予定」の場合
      IF ( gt_param.iv_plan_decide_kbn = gc_plan_decide_p ) THEN
        gv_report_title := gc_rpt_title_haisou_yotei;
      -- 予定/確定区分が「確定」の場合
      ELSE
        gv_report_title := gc_rpt_title_haisou_irai;
      END IF ;
--
    -- 出庫/配送区分が「出庫」の場合
    ELSE
--
      -- 予定/確定区分が「予定」の場合
      IF ( gt_param.iv_plan_decide_kbn = gc_plan_decide_p ) THEN
        gv_report_title := gc_rpt_title_shukko_yotei;
--
      -- 予定/確定区分が「確定」の場合
      ELSE
        gv_report_title := gc_rpt_title_shukko_irai;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- 帳票データ取得
    -- ====================================================
    -- 動的SQL
    lv_sql_head := lv_sql_head 
    || ' SELECT ' 
    || ' gyoumu_shubetsu '          -- 業務種別
    || ' ,gyoumu_shubetsu_code '    -- 業務種別コード
    || ' ,freight_carrier_code '    -- 運送業者
    || ' ,carrier_full_name '       -- 運送業者(名称)
    || ' ,deliver_from '            -- 出庫元
    || ' ,description '             -- 出庫元(名称)
    || ' ,schedule_ship_date '      -- 出庫日
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620指摘47 ソート順変更
    || ' ,item_class_code '         -- 品目区分
-- 2008/10/27 mod end 1.13 
    || ' ,item_class_name '         -- 品目区分名
    || ' ,new_modify_flg '          -- 新規修正フラグ
    || ' ,schedule_arrival_date '   -- 着日
    || ' ,delivery_no '             -- 配送No
    || ' ,shipping_method_code '    -- 配送区分
    || ' ,ship_method_meaning '     -- 配送区分名称
    || ' ,head_sales_branch '       -- 管轄拠点
    || ' ,party_name '              -- 管轄拠点(名称)
    || ' ,deliver_to '              -- 配送先
    || ' ,party_site_full_name '    -- 配送先(正式名)
    || ' ,address_line1 '           -- 配送先(住所1)
    || ' ,address_line2 '           -- 配送先(住所2)
    || ' ,phone '                   -- 配送先(電話番号)
    || ' ,arrival_time_from '       -- 時間指定From
    || ' ,arrival_time_to '         -- 時間指定To
    || ' ,TRUNC(sum_loading_capacity + 0.9) AS sum_loading_capacity ' -- 混載体積 2008/07/07 ST不具合対応#337
    || ' ,TRUNC(sum_loading_weight + 0.9) AS sum_loading_weight ' --混載重量 2008/07/07 ST不具合対応#337
    || ' ,req_mov_no '              -- 依頼No/移動No
    || ' ,TRUNC(sum_weightm_capacity + 0.9) AS sum_weightm_capacity' --重量体積(依頼No.単位) 2008/07/07 ST不具合対応#337
    || ' ,sum_weightm_capacity_t '  -- 単位
    || ' ,tehai_no '                -- 手配No
    || ' ,prev_delivery_no '        -- 前回配送No
    || ' ,po_no '                   -- PoNo
    || ' ,jpr_user_code '           -- JPRユーザコード
    || ' ,collected_pallet_qty '    -- パレット回収枚数
    || ' ,shipping_instructions '   -- 摘要
    || ' ,slip_number '             -- 送り状No
    || ' ,small_quantity '          -- 個数
    || ' ,item_code '               -- 品目(コード)
    || ' ,item_name '               -- 品目(名称)
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620指摘47 ソート順変更
    || ' ,lot_id '                  -- ロットID
-- 2008/10/27 mod end 1.13 
    || ' ,lot_no '                  -- ロットNo
    || ' ,attribute1 '              -- 製造日
    || ' ,attribute3 '              -- 賞味期限
    || ' ,attribute2 '              -- 固有記号
    || ' ,num_of_cases '            -- 入数
    || ' ,net '                     -- 重量(NET)
    || ' ,qty '                     -- 数量
    || ' ,conv_unit '               -- 入出庫換算単位
    || ' FROM ' 
    || ' ( ' ;
--
    -- ====================================================
    -- 出荷情報
    -- ====================================================
--add start 1.2
  IF (NVL(gt_param.iv_gyoumu_shubetsu,gc_biz_type_cd_ship) = gc_biz_type_cd_ship) THEN
--add end 1.2
    lv_sql_shu_sel_from1  :=  lv_sql_shu_sel_from1
    || ' SELECT ' 
    || ' '''|| gc_biz_type_nm_ship ||''' AS gyoumu_shubetsu ' 
    || ' ,'''|| gc_biz_type_cd_ship ||''' AS gyoumu_shubetsu_code ' 
    || ' ,xil2v.distribution_block AS dist_block ' 
    || ' ,xoha.freight_carrier_code AS freight_carrier_code ' 
    || ' ,xc2v.party_name AS carrier_full_name '
    || ' ,xoha.deliver_from AS deliver_from ' 
    || ' ,xil2v.description AS description ' 
    || ' ,xoha.schedule_ship_date AS schedule_ship_date ' 
-- 2008/10/27 ADD start 1.13 T_TE080_BPO_620指摘47 ソート順変更
    || ' ,xic4v.item_class_code AS item_class_code ' 
-- 2008/10/27 ADD end 1.13 
    || ' ,xic4v.item_class_name AS item_class_name ' 
    || ' ,DECODE(xoha.new_modify_flg, ''' 
      || gc_new_modify_flg_mod ||''', '''
      || gc_asterisk ||''') AS new_modify_flg ' 
    || ' ,xoha.schedule_arrival_date AS schedule_arrival_date' 
    || ' ,xoha.delivery_no AS delivery_no ' 
    || ' ,xoha.shipping_method_code AS shipping_method_code ' 
    || ' ,xsm2v.ship_method_meaning AS ship_method_meaning ' 
    || ' ,xoha.head_sales_branch AS head_sales_branch ' 
    || ' ,xca2v.party_name AS party_name ' 
    || ' ,xoha.deliver_to AS deliver_to ' 
    || ' ,xcas2v.party_site_full_name AS party_site_full_name ' 
    || ' ,xcas2v.address_line1 AS address_line1 ' 
    || ' ,xcas2v.address_line2 AS address_line2 ' 
    || ' ,xcas2v.phone AS phone ' 
    || ' ,xoha.arrival_time_from AS arrival_time_from ' 
    || ' ,xoha.arrival_time_to AS arrival_time_to ' 
    || ' ,xcs.sum_loading_capacity AS sum_loading_capacity ' 
    || ' ,xcs.sum_loading_weight AS sum_loading_weight ' 
    || ' ,xoha.request_no AS req_mov_no ' 
    || ' ,CASE' 
    || ' WHEN ( xsm2v.small_amount_class = '''|| gc_small_amount_enabled ||''' ) THEN' 
    || ' CASE ' 
    || ' WHEN ( xoha.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''' ) THEN' 
    || ' xoha.sum_weight' 
    || ' WHEN ( xoha.weight_capacity_class = '''|| gc_wei_cap_kbn_c ||''' ) THEN'    
    || ' xoha.sum_capacity' 
    || ' END' 
    || ' WHEN xsm2v.small_amount_class IS NULL THEN'   -- 6/23 追加
    || ' NULL'
    || ' ELSE' 
    || ' CASE ' 
    || ' WHEN ( xoha.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''' ) THEN' 
-- 2009/01/23 v1.18 N.Yoshida UPDATE START
--    || ' xola.pallet_weight + xoha.sum_weight' 
    || ' NVL(xoha.sum_pallet_weight, 0) + xoha.sum_weight' 
    || ' WHEN ( xoha.weight_capacity_class = '''|| gc_wei_cap_kbn_c ||''' ) THEN' 
--    || ' xola.pallet_weight + xoha.sum_capacity' 
-- 2009/02/04 Y.Kanami 本番#41対応 Start --
    || ' xoha.sum_capacity' 
--    || ' NVL(xoha.sum_pallet_weight, 0) + xoha.sum_capacity' 
-- 2009/02/04 Y.Kanami 本番#41対応 End   --
-- 2009/01/23 v1.18 N.Yoshida UPDATE END
    || ' END' 
    || ' END AS sum_weightm_capacity' 
    || ' ,CASE' 
    || ' WHEN ( xoha.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''' ) THEN' 
    || ' '''|| gv_uom_weight ||''' ' 
    || ' ELSE' 
    || ' '''|| gv_uom_capacity ||''' ' 
    || ' END AS sum_weightm_capacity_t ' 
    || ' ,NULL AS tehai_no ' 
    || ' ,xoha.prev_delivery_no AS prev_delivery_no ' 
    || ' ,xoha.cust_po_number AS po_no ' ;
--
    lv_sql_shu_sel_from2  :=  lv_sql_shu_sel_from2
    || ' ,xcas2v.jpr_user_code AS jpr_user_code ' 
    || ' ,xoha.collected_pallet_qty AS collected_pallet_qty ' 
    || ' ,xoha.shipping_instructions AS shipping_instructions ' 
    || ' ,xoha.slip_number AS slip_number ' 
    || ' ,xoha.small_quantity AS small_quantity ' 
    || ' ,xola.shipping_item_code AS item_code ' 
    || ' ,xim2v.item_short_name AS item_name ' 
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620指摘47 ソート順変更
    || ' ,xmld.lot_id AS lot_id ' 
-- 2008/10/27 mod end 1.13 
    || ' ,xmld.lot_no AS lot_no ' 
    || ' ,ilm.attribute1 AS attribute1 ' 
    || ' ,ilm.attribute3 AS attribute3 ' 
    || ' ,ilm.attribute2 AS attribute2 ' 
    || ' ,CASE' 
    || ' WHEN ( xic4v.item_class_code = '''|| gc_item_cd_prdct ||''' ) THEN' 
    || ' xim2v.num_of_cases' 
-- 2009/02/04 Y.Kanami 本番#41対応 Start
    || ' WHEN ( ( xic4v.item_class_code = '''|| gc_item_cd_material ||''' '
    || ' OR xic4v.item_class_code = '''|| gc_item_cd_prdct_half ||''' )' 
    || ' AND ilm.attribute6 IS NOT NULL ) THEN' 
--    || ' WHEN ( ilm.attribute6 IS NOT NULL ) THEN' 
-- 2009/02/04 Y.Kanami 本番#41対応 End ----
    || ' ilm.attribute6' 
-- 2009/02/04 Y.Kanami 本番#41対応 Start
    || ' WHEN (( ilm.attribute6 IS NULL )'
    || ' OR (xim2v.lot_ctl <> '''|| gc_lot_ctl_manage ||''')) THEN'     -- ロット管理されていない
--    || ' WHEN ( ilm.attribute6 IS NULL ) THEN' 
-- 2009/02/04 Y.Kanami 本番#41対応 End ----
    || ' xim2v.frequent_qty' 
    || ' END  AS num_of_cases' 
    || ' ,xim2v.net AS net' 
    || ' ,CASE  ' 
    || ' WHEN ( xola.reserved_quantity > 0 ) THEN' 
    || ' CASE ' 
    || ' WHEN ( ( xic4v.item_class_code = '''|| gc_item_cd_prdct ||''' )' 
    || ' AND ( xim2v.conv_unit IS NOT NULL ) ) THEN' 
    || ' xmld.actual_quantity / TO_NUMBER(' 
    || ' CASE' 
    || ' WHEN ( xim2v.num_of_cases > 0 ) THEN' 
    || ' xim2v.num_of_cases' 
    || ' ELSE' 
    || ' TO_CHAR(1)' 
    || ' END)' 
    || ' ELSE' 
    || ' xmld.actual_quantity' 
    || ' END' 
    || ' WHEN ( ( xola.reserved_quantity IS NULL ) ' 
    || ' OR ( xola.reserved_quantity = 0 ) ) THEN' 
    || ' CASE ' 
    || ' WHEN ( ( xic4v.item_class_code = '''|| gc_item_cd_prdct ||''' )' 
    || ' AND ( xim2v.conv_unit IS NOT NULL ) ) THEN' 
    || ' xola.quantity / TO_NUMBER(' 
    || ' CASE' 
    || '  WHEN ( xim2v.num_of_cases > 0 ) THEN' 
    || '  xim2v.num_of_cases' 
    || '  ELSE' 
    || '  TO_CHAR(1)' 
    || ' END' 
    || ' )' 
    || ' ELSE' 
    || ' xola.quantity' 
    || ' END' 
    || ' END  AS qty' 
    || ' ,CASE' 
    || ' WHEN ( xic4v.item_class_code = '|| gc_item_cd_prdct ||' )' 
-- 2008/10/27 add start 1.13 課題32 単位/入数換算ロジック修正
    || ' AND ( xim2v.num_of_cases > 0 ) ' 
-- 2008/10/27 add end 1.13 
    || ' AND ( xim2v.conv_unit IS NOT NULL ) THEN' 
    || ' xim2v.conv_unit' 
    || ' ELSE' 
    || ' xim2v.item_um' 
    || ' END  AS conv_unit' 
    || ' FROM' 
    || ' xxwsh_carriers_schedule xcs '            -- 配車配送計画(アドオン)
    || ' ,xxwsh_order_headers_all xoha '          -- 受注ヘッダアドオン
    || ' ,xxwsh_oe_transaction_types2_v xott2v '  -- 受注タイプ情報VIEW2
    || ' ,xxwsh_order_lines_all xola '            -- 受注明細アドオン
    || ' ,xxinv_mov_lot_details xmld '            -- 移動ロット詳細(アドオン)
    || ' ,ic_lots_mst ilm '                       -- OPMロットマスタ
    || ' ,xxcmn_item_locations2_v xil2v '         -- OPM保管場所情報VIEW2
    || ' ,xxcmn_cust_acct_sites2_v xcas2v '       -- 顧客サイト情報VIEW2
    || ' ,xxcmn_cust_accounts2_v xca2v '          -- 顧客情報VIEW2
    || ' ,xxcmn_carriers2_v xc2v '                -- 運送業者情報VIEW2
    || ' ,xxcmn_item_mst2_v xim2v '               -- OPM品目情報VIEW2
    || ' ,xxcmn_item_categories4_v xic4v '        -- OPM品目カテゴリ割当情報VIEW4
    || ' ,xxwsh_tightening_control xtc '          -- 出荷依頼締め管理(アドオン)
    || ' ,fnd_user fu '                           -- ユーザーマスタ
    || ' ,per_all_people_f papf '                 -- 従業員マスタ
    || ' ,xxwsh_ship_method2_v xsm2v ' ;          -- 配送区分情報VIEW2
--
    lv_sql_shu_where1 :=  lv_sql_shu_where1
    || ' WHERE' ;
    -------------------------------------------------------------------------------
    -- 受注ヘッダアドオン
    -------------------------------------------------------------------------------
    IF ( gt_param.iv_mov_num IS NOT NULL ) THEN
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
      || ' ( xoha.request_no = '''|| gt_param.iv_mov_num ||''') AND ' ;
    END IF ;
    lv_sql_shu_where1 :=  lv_sql_shu_where1 
    || ' xoha.req_status >= '''|| gc_ship_status_close ||'''' 
    || ' AND xoha.req_status <> '''|| gc_ship_status_delete ||'''' 
-- 2008/11/13 Y.Yamamoto v1.15 add start
    || ' AND xoha.schedule_ship_date IS NOT NULL' 
-- 2008/11/13 Y.Yamamoto v1.15 add end
    || ' AND xoha.schedule_ship_date >= '''|| TRUNC(gt_param.iv_ship_from) ||'''' 
    || ' AND xoha.schedule_ship_date <= '''|| TRUNC(gt_param.iv_ship_to) ||'''' ;
    IF ( gt_param.iv_freight_carrier_code IS NOT NULL ) THEN
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
      || ' AND ( xoha.freight_carrier_code = '''|| gt_param.iv_freight_carrier_code ||''')' ;
    END IF ;
-- 2008/10/27 mod start1.13 統合指摘297 予定依頼区分が確定の時、確定通知実施日、時間を条件とする
--    IF ( gt_param.iv_notif_date IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_date IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
      || ' AND ( TRUNC(TO_DATE(xoha.notif_date,'''|| gc_date_fmt_all ||'''))' 
      || ' = TRUNC(TO_DATE('''|| TRUNC(gt_param.iv_notif_date) ||''', '''
                              || gc_date_fmt_all ||''')) )' ;
    END IF ;
-- 2008/10/27 mod start1.13 統合指摘297 予定依頼区分が確定の時、確定通知実施日、時間を条件とする
--    IF ( gt_param.iv_notif_time_from IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_time_from IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
      || ' AND ( TO_CHAR(xoha.notif_date, '''
      || gc_date_fmt_hh24mi ||''') >= '''|| gt_param.iv_notif_time_from ||''')' ;
    END IF ;
-- 2008/10/27 mod start1.13 統合指摘297 予定依頼区分が確定の時、確定通知実施日、時間を条件とする
--    IF ( gt_param.iv_notif_time_to IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_time_to IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_shu_where1 :=  lv_sql_shu_where1
      || ' AND ( TO_CHAR(xoha.notif_date, '''
      || gc_date_fmt_hh24mi ||''') <= '''|| gt_param.iv_notif_time_to ||''')' ;
    END IF ;
    IF ( gt_param.iv_dept IS NOT NULL ) THEN
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
      || ' AND ( xoha.instruction_dept = '''|| gt_param.iv_dept ||''')' ;
    END IF ;
    lv_sql_shu_where1 :=  lv_sql_shu_where1 
    || ' AND (' 
    || ' (' 
    || ' ( '''|| gt_param.iv_plan_decide_kbn ||''' = '''|| gc_plan_decide_p ||''' )'
    || ' AND' 
    || ' ( xoha.notif_status IN ('''|| gc_fixa_notif_yet ||''', '''|| gc_fixa_notif_re ||''') )'
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' ( '''|| gt_param.iv_plan_decide_kbn ||''' = '''|| gc_plan_decide_d ||''' )' 
    || ' AND' 
    || ' ( xoha.notif_status = '''|| gc_fixa_notif_end ||''')' 
    || ' )' 
    || ' )' 
    || ' AND xoha.latest_external_flag = ''' || gc_latest_external_flag ||''''
    -------------------------------------------------------------------------------
    -- 配車配送計画(アドオン)
    -------------------------------------------------------------------------------
    || ' AND xoha.delivery_no = xcs.delivery_no(+)' 
    -------------------------------------------------------------------------------
    -- 配送区分情報VIEW2
    -------------------------------------------------------------------------------
    || ' AND xoha.shipping_method_code = xsm2v.ship_method_code(+)'  -- 6/23 外部結合追加
    ------------------------------------------------
    -- 受注タイプ情報VIEW2
    ------------------------------------------------
    || ' AND xoha.order_type_id = xott2v.transaction_type_id' ;
    IF ( gt_param.iv_shukko_keitai IS NOT NULL ) THEN
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
      || ' AND xott2v.transaction_type_id = '''|| gt_param.iv_shukko_keitai ||'''' ;
    END IF ;
    lv_sql_shu_where1 :=  lv_sql_shu_where1 
    || ' AND xott2v.shipping_shikyu_class = '''|| gc_ship_pro_kbn_shu || ''''
    || ' AND xott2v.order_category_code <> '''|| gc_order_cate_ret ||'''' 
    ------------------------------------------------
    -- OPM保管場所情報VIEW2
    ------------------------------------------------
    || ' AND xoha.deliver_from_id = xil2v.inventory_location_id';
    IF ( gt_param.iv_online_kbn IS NOT NULL ) THEN
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
      || ' AND xil2v.eos_control_type = '''|| gt_param.iv_online_kbn ||'''' ;
    END IF ;
-- 2008/10/27 add start 1.13 T_TE080_BPO_620指摘47 出庫配送区分が出庫の場合、倉庫兼運送業者を除外
    IF ( gt_param.iv_shukko_haisou_kbn = gc_shukko_haisou_kbn_d ) THEN
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
-- 2008/11/27 v1.17 UPDATE START
--      || ' AND ( xil2v.eos_detination <> xc2v.eos_detination ) ' ;
      || ' AND ( '
      || '       ( xil2v.eos_detination IS NULL ) '
      || '       OR '
      || '       ( xc2v.eos_detination IS NULL ) '
      || '       OR '
      || '       ( xil2v.eos_detination <> xc2v.eos_detination ) '
      || '     ) ' ;
-- 2008/11/27 v1.17 UPDATE END
    END IF ;
-- 2008/10/27 add end 1.13 
    lv_sql_shu_where1 :=  lv_sql_shu_where1
    || ' AND (' 
    || ' xil2v.distribution_block IN ( '''|| gt_param.iv_block1 ||'''' 
    || '  , '''|| gt_param.iv_block2 ||'''' 
    || '  , '''|| gt_param.iv_block3 ||''' )' 
    || ' OR' 
    || ' xoha.deliver_from = '''|| gt_param.iv_shipped_locat_code ||''' '
    || ' OR' 
    || ' (' 
    || ' '''|| gt_param.iv_block1 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_block2 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_block3 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_shipped_locat_code ||''' IS NULL' 
    || ' )' 
    || ' )' 
    ------------------------------------------------
    -- 顧客サイト情報VIEW2
    ------------------------------------------------
-- 2009/04/24 H.Itou   本番#1398対応 START --
--    || ' AND xoha.deliver_to_id = xcas2v.party_site_id' 
    || ' AND xoha.deliver_to = xcas2v.party_site_number' 
    || ' AND xcas2v.party_site_status = ''' || gc_status_active || ''''
-- 2009/04/24 H.Itou   本番#1398対応 END   --
    || ' AND xcas2v.start_date_active <= xoha.schedule_ship_date' 
    || ' AND (' 
    || ' xcas2v.end_date_active >= xoha.schedule_ship_date' 
    || ' OR' 
    || ' xcas2v.end_date_active IS NULL' 
    || ' )' ;
    -------------------------------------------------------------------------------
    -- 顧客情報VIEW2
    -------------------------------------------------------------------------------
    ----------------------------------------------------------------------
    -- 管轄拠点
    -- 管轄拠点（名称）
--
    lv_sql_shu_where2 :=  lv_sql_shu_where2
    || ' AND xoha.head_sales_branch = xca2v.party_number' 
    || ' AND xca2v.start_date_active <= xoha.schedule_ship_date' 
    || ' AND (' 
    || ' xca2v.end_date_active >= xoha.schedule_ship_date' 
    || ' OR' 
    || ' xca2v.end_date_active IS NULL' 
    || ' )' 
    ----------------------------------------------------------------------
    ------------------------------------------------
    -- 運送業者情報VIEW2
    ------------------------------------------------
    ----------------------------------------------------------------------
    -- 運送業者
    -- 運送業者（名称）
    || ' AND xoha.career_id = xc2v.party_id(+)' 
    || ' AND (' 
    || ' xc2v.start_date_active IS NULL' 
    || ' OR' 
    || ' xc2v.start_date_active <= xoha.schedule_ship_date' 
    || ' )' 
    || ' AND (' 
    || ' xc2v.end_date_active IS NULL' 
    || ' OR' 
    || ' xc2v.end_date_active >= xoha.schedule_ship_date' 
    || ' )' 
    ----------------------------------------------------------------------
    || ' AND (' 
    || ' (' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_d ||''' '
    || ' AND' 
    || ' xoha.freight_carrier_code <> xoha.deliver_from' 
    || ' )' 
    || ' OR' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_p ||''' '
    || ' )' 
    ------------------------------------------------
    -- 出荷依頼締め管理(アドオン)
    ------------------------------------------------
    || ' AND xoha.tightening_program_id = xtc.concurrent_id(+)' ;
-- 2008/10/27 mod start1.13仕様不備T_S_601 予定依頼区分が予定の時、締め実施日、時間を条件とする
--    IF ( gt_param.iv_shime_date IS NOT NULL ) THEN
    IF ( gt_param.iv_shime_date IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_p ) THEN
-- 2008/10/27 mod end
      lv_sql_shu_where2 :=  lv_sql_shu_where2
      || ' AND TRUNC(xtc.tightening_date) = ' 
      || ' TRUNC(TO_DATE('''|| TRUNC(gt_param.iv_shime_date) ||'''))' ;
    END IF ;
-- 2008/10/27 mod start1.13仕様不備T_S_601 予定依頼区分が予定の時、締め実施日、時間を条件とする
--    IF ( gt_param.iv_shime_time_from IS NOT NULL ) THEN
    IF ( gt_param.iv_shime_time_from IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_p ) THEN
-- 2008/10/27 mod end
      lv_sql_shu_where2 :=  lv_sql_shu_where2
      || ' AND TO_CHAR(xtc.tightening_date, '''
      || gc_date_fmt_hh24mi ||''') '||' >= '''|| gt_param.iv_shime_time_from ||''' ' ;
    END IF ;
-- 2008/10/27 mod start1.13仕様不備T_S_601 予定依頼区分が予定の時、締め実施日、時間を条件とする
--    IF ( gt_param.iv_shime_time_to IS NOT NULL ) THEN
    IF ( gt_param.iv_shime_time_to IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_p ) THEN
-- 2008/10/27 mod end
      lv_sql_shu_where2 :=  lv_sql_shu_where2
      || ' AND TO_CHAR(xtc.tightening_date, '''
      || gc_date_fmt_hh24mi ||''') ' 
      || ' <= '''|| gt_param.iv_shime_time_to ||''' ' ;
    END IF ;
    ------------------------------------------------
    -- 受注明細アドオン
    ------------------------------------------------
--
    lv_sql_shu_where2 :=  lv_sql_shu_where2
    || ' AND xoha.order_header_id = xola.order_header_id' ;
    lv_sql_shu_where2 :=  lv_sql_shu_where2
    || ' AND xola.delete_flag <> '''|| gc_delete_flg ||'''' 
-- 2008/11/07 Y.Yamamoto v1.14 add start
    || ' AND xola.quantity     > 0'
-- 2008/11/07 Y.Yamamoto v1.14 add end
    ------------------------------------------------
    -- OPM品目情報VIEW2
    ------------------------------------------------
    || ' AND xola.shipping_inventory_item_id = xim2v.inventory_item_id' 
    || ' AND xim2v.start_date_active <= xoha.schedule_ship_date' 
    || ' AND (' 
    || ' xim2v.end_date_active IS NULL' 
    || ' OR' 
    || ' xim2v.end_date_active >= xoha.schedule_ship_date' 
    || ' )' 
    ------------------------------------------------
    -- OPM品目カテゴリ割当情報VIEW4
    ------------------------------------------------
-- 2008/11/20 Y.Yamamoto v1.16 update start
--    || ' AND xim2v.item_id = xic4v.item_id' 
    || ' AND xim2v.item_id = xic4v.item_id' ;
    IF (gv_papf_attribute3 = gc_user_kbn_inside) THEN
      -- 商品区分セキュリティのチェックは内部ユーザーのみ行うように修正
      lv_sql_shu_where2 :=   lv_sql_shu_where2 
    || ' AND xic4v.prod_class_code = '''|| gv_prod_kbn ||''' ' ;
    END IF;
-- 2008/11/20 Y.Yamamoto v1.16 update end
    IF ( gt_param.iv_item_kbn IS NOT NULL ) THEN
     lv_sql_shu_where2 :=   lv_sql_shu_where2 
     || ' AND xic4v.item_class_code = '''|| gt_param.iv_item_kbn ||''' ' ;
    END IF ;
    ------------------------------------------------
    -- 移動ロット詳細(アドオン)
    ------------------------------------------------
    lv_sql_shu_where2 :=  lv_sql_shu_where2 
    || ' AND xola.order_line_id = xmld.mov_line_id(+)' 
    || ' AND xmld.document_type_code(+) = ' || gc_doc_type_code_syukka 
    || ' AND xmld.record_type_code(+)   = ' || gc_rec_type_code_ins
    -------------------------------------------------------------------------------
    -- OPMロットマスタ
    -------------------------------------------------------------------------------
    || ' AND xmld.lot_id = ilm.lot_id(+) ' 
    || ' AND xmld.item_id = ilm.item_id(+) ' 
    ------------------------------------------------
    -- ユーザ情報
    ------------------------------------------------
    || ' AND fu.user_id = '''|| FND_GLOBAL.USER_ID ||'''' 
    || ' AND fu.employee_id = papf.person_id ' 
-- 2008/11/13 Y.Yamamoto v1.15 add start
    || ' AND xoha.schedule_ship_date   BETWEEN papf.effective_start_date' 
    || ' AND NVL(papf.effective_end_date, xoha.schedule_ship_date)' 
-- 2008/11/13 Y.Yamamoto v1.15 add end
    || ' AND (' 
    || ' NVL(papf.attribute3, '''|| gc_user_kbn_inside ||''') = '
    || gc_user_kbn_inside ||' ' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute3 = '''|| gc_user_kbn_outside ||''' ' 
    || ' AND' 
    || ' (' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NULL ' 
    || ' AND' 
    || ' xil2v.purchase_code = papf.attribute4 ' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' (' 
    || ' xil2v.purchase_code = papf.attribute4 ' 
    || ' OR' 
    || ' xoha.freight_carrier_code = papf.attribute5 ' 
    || ' )' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' xoha.freight_carrier_code = papf.attribute5 '
-- 2008/07/09 add S.Takemoto start
    -- 従業員区分が'外部'で、｢運賃区分＝対象｣または｢強制出力フラグ＝対象｣の場合、出力対象外
    || ' AND' 
    || ' xoha.freight_charge_class =''' || gc_freight_charge_code_1 || ''''       -- 運賃区分
-- 2008/11/20 Y.Yamamoto v1.16 update start
--    || ' AND' 
    || ' OR' 
-- 2008/11/20 Y.Yamamoto v1.16 update end
    || ' xc2v.complusion_output_code =''' || gc_freight_charge_code_1|| ''''      -- 強制出力区分
-- 2008/07/09 add S.Takemoto end
    || ' )' 
    || ' )' 
    || ' )' 
    || ' )' 
--mod start 1.2
--    || ' UNION ALL' ;
    ;
    lb_union := true;
  END IF;
--mod end 1.2
--
--add start 1.2
  IF (NVL(gt_param.iv_gyoumu_shubetsu,gc_biz_type_cd_shikyu) = gc_biz_type_cd_shikyu) THEN
    IF (lb_union) THEN
      lv_sql_sik_sel_from1 := ' UNION ALL' ;
    END IF;
--add end 1.2
    lv_sql_sik_sel_from1  :=  lv_sql_sik_sel_from1
    --=====================================================================
    -- 支給情報
    --=====================================================================
    || ' SELECT' 
    || ' '''|| gc_biz_type_nm_shik ||''' AS gyoumu_shubetsu ' 
    || ' ,'''|| gc_biz_type_cd_shikyu ||''' AS gyoumu_shubetsu_code ' 
    || ' ,xil2v.distribution_block AS dist_block' 
    || ' ,xoha.freight_carrier_code AS freight_carrier_code ' 
    || ' ,xc2v.party_name AS carrier_full_name '
    || ' ,xoha.deliver_from AS deliver_from ' 
    || ' ,xil2v.description AS description ' 
    || ' ,xoha.schedule_ship_date AS schedule_ship_date ' 
-- 2008/10/27 ADD start 1.13 T_TE080_BPO_620指摘47 ソート順変更
    || ' ,xic4v.item_class_code AS item_class_code ' 
-- 2008/10/27 ADD end 1.13 
    || ' ,xic4v.item_class_name AS item_class_name ' 
    || ' ,DECODE(xoha.new_modify_flg, '''
      || gc_new_modify_flg_mod ||''', '''
      || gc_asterisk ||''') AS new_modify_flg ' 
    || ' ,xoha.schedule_arrival_date AS schedule_arrival_date' 
    || ' ,xoha.delivery_no AS delivery_no ' 
    || ' ,xoha.shipping_method_code AS shipping_method_code ' 
    || ' ,xsm2v.ship_method_meaning AS ship_method_meaning ' 
--mod start 1.10.2
--    || ' ,xoha.head_sales_branch AS head_sales_branch ' 
    || ' ,xoha.vendor_code AS head_sales_branch ' 
--mod end 1.10.2
    || ' ,xv2v.vendor_full_name AS party_name ' 
--mod start 1.10.2
--    || ' ,xoha.deliver_to AS deliver_to ' 
    || ' ,xoha.vendor_site_code AS deliver_to ' 
--mod end 1.10.2
    || ' ,xvs2v.vendor_site_name AS party_site_full_name ' 
    || ' ,xvs2v.address_line1 AS address_line1 ' 
    || ' ,xvs2v.address_line2 AS address_line2 ' 
    || ' ,xvs2v.phone AS phone ' 
    || ' ,xoha.arrival_time_from AS arrival_time_from ' 
    || ' ,xoha.arrival_time_to AS arrival_time_to ' 
    || ' ,xcs.sum_loading_capacity AS sum_loading_capacity ' 
    || ' ,xcs.sum_loading_weight AS sum_loading_weight ' 
    || ' ,xoha.request_no AS req_mov_no ' 
    || ' ,CASE' 
    || ' WHEN ( xoha.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''' ) THEN' 
    || ' xoha.sum_weight' 
    || ' ELSE' 
    || ' xoha.sum_capacity' 
    || ' END AS sum_weightm_capacity' 
    || ' ,CASE' 
    || ' WHEN ( xoha.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''' ) THEN' 
    || ' '''|| gv_uom_weight ||'''' 
    || ' ELSE' 
    || ' '''|| gv_uom_capacity ||'''' 
    || ' END AS sum_weightm_capacity_t' 
    || ' ,NULL AS tehai_no ' 
    || ' ,xoha.prev_delivery_no AS prev_delivery_no ' ;
--
    lv_sql_sik_sel_from2  :=  lv_sql_sik_sel_from2
    || ' ,xoha.cust_po_number AS po_no ' 
    || ' ,NULL AS jpr_user_code ' 
    || ' ,xoha.collected_pallet_qty AS collected_pallet_qty ' 
    || ' ,xoha.shipping_instructions AS shipping_instructions ' 
    || ' ,xoha.slip_number AS slip_number ' 
    || ' ,xoha.small_quantity AS small_quantity ' 
    || ' ,xola.shipping_item_code AS item_code ' 
    || ' ,xim2v.item_short_name AS item_name ' 
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620指摘47 ソート順変更
    || ' ,xmld.lot_id AS lot_id ' 
-- 2008/10/27 mod end 1.13 
    || ' ,xmld.lot_no AS lot_no ' 
    || ' ,ilm.attribute1 AS attribute1 ' 
    || ' ,ilm.attribute3 AS attribute3 ' 
    || ' ,ilm.attribute2 AS attribute2 ' 
    || ' ,CASE' 
    || ' WHEN ( xic4v.item_class_code = '''|| gc_item_cd_prdct ||''' ) THEN' 
    || ' xim2v.num_of_cases' 
    || ' WHEN ( ( xic4v.item_class_code = '''|| gc_item_cd_material ||''' ' 
    || ' OR xic4v.item_class_code = '''|| gc_item_cd_prdct_half ||''' )' 
    || ' AND ilm.attribute6 IS NOT NULL ) THEN' 
    || ' ilm.attribute6' 
-- 2009/02/04 Y.Kanami 本番#41対応 Start --
    || ' WHEN ((ilm.attribute6 IS NULL)'
    || ' OR (xim2v.lot_ctl <> '''|| gc_lot_ctl_manage ||''')) THEN'     -- ロット管理されていない
--    || ' WHEN ilm.attribute6 IS NULL THEN' 
-- 2009/02/04 Y.Kanami 本番#41対応 End ----    
    || ' xim2v.frequent_qty' 
    || ' END  AS num_of_cases' 
    || ' ,xim2v.net  AS net' 
    || ' ,CASE ' 
    || ' WHEN (xola.reserved_quantity > 0) THEN ' 
    || ' xmld.actual_quantity ' 
    || ' WHEN ( ( xola.reserved_quantity IS NULL ) ' 
    || ' OR ( xola.reserved_quantity = 0 ) ) THEN ' 
    || ' xola.quantity ' 
    || ' END AS qty ' 
-- 2008/10/27 mod start 1.13 課題32 単位/入数換算ロジック修正
--    || ' ,xim2v.item_um AS conv_unit '
    || ' ,CASE' 
    || ' WHEN ( xic4v.item_class_code = '|| gc_item_cd_prdct ||' )' 
    || ' AND ( xim2v.num_of_cases > 0 ) ' 
    || ' AND ( xim2v.conv_unit IS NOT NULL ) THEN' 
    || ' xim2v.conv_unit' 
    || ' ELSE' 
    || ' xim2v.item_um' 
    || ' END  AS conv_unit' 
-- 2008/10/27 mod end 1.13 
    || ' FROM' 
    || ' xxwsh_carriers_schedule xcs '            -- 配車配送計画(アドオン)
    || ' ,xxwsh_order_headers_all xoha '          -- 受注ヘッダアドオン
    || ' ,xxwsh_oe_transaction_types2_v xott2v '  -- 受注タイプ情報VIEW2
    || ' ,xxwsh_order_lines_all xola '            -- 受注明細アドオン
    || ' ,xxinv_mov_lot_details xmld '            -- 移動ロット詳細(アドオン)
    || ' ,ic_lots_mst ilm '                       -- OPMロットマスタ
    || ' ,xxcmn_item_locations2_v xil2v '         -- OPM保管場所情報VIEW2
    || ' ,xxcmn_vendor_sites2_v xvs2v '           -- 仕入先サイト情報VIEW2
    || ' ,xxcmn_vendors2_v xv2v '                 -- 仕入先情報VIEW2
    || ' ,xxcmn_carriers2_v xc2v '                -- 運送業者情報VIEW2
    || ' ,xxcmn_item_mst2_v xim2v '               -- OPM品目情報VIEW2
    || ' ,xxcmn_item_categories4_v xic4v '        -- OPM品目カテゴリ割当情報VIEW4
    || ' ,fnd_user fu '                           -- ユーザーマスタ
    || ' ,per_all_people_f papf '                 -- 従業員マスタ
    || ' ,xxwsh_ship_method2_v xsm2v ' ;          -- 配送区分情報VIEW2
--
    lv_sql_sik_where1 :=  lv_sql_sik_where1
    || ' WHERE' ;
    -------------------------------------------------------------------------------
    -- 受注ヘッダアドオン
    -------------------------------------------------------------------------------
    IF ( gt_param.iv_mov_num IS NOT NULL ) THEN
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' xoha.request_no = '''|| gt_param.iv_mov_num ||''' AND ' ;
    END IF ;
    lv_sql_sik_where1 :=  lv_sql_sik_where1
    || '     xoha.req_status >= '''|| gc_req_status_juryozumi ||'''' 
    || ' AND xoha.req_status <> '''|| gc_ship_status_delete ||'''' 
    || ' AND xoha.schedule_ship_date >= '''|| TRUNC(gt_param.iv_ship_from) ||'''' 
    || ' AND xoha.schedule_ship_date <= '''|| TRUNC(gt_param.iv_ship_to) ||'''' ;
    IF ( gt_param.iv_freight_carrier_code IS NOT NULL ) THEN
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' AND xoha.freight_carrier_code = '''|| gt_param.iv_freight_carrier_code||'''' ;
    END IF ;
-- 2008/10/27 mod start1.13 統合指摘297 予定依頼区分が確定の時、確定通知実施日、時間を条件とする
--    IF ( gt_param.iv_notif_date IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_date IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' AND TRUNC(TO_DATE(xoha.notif_date, '''|| gc_date_fmt_all ||'''))' 
      || ' = TRUNC(TO_DATE('''|| TRUNC(gt_param.iv_notif_date) ||''', '''
                              || gc_date_fmt_all ||'''))' ;
    END IF ;
-- 2008/10/27 mod start1.13 統合指摘297 予定依頼区分が確定の時、確定通知実施日、時間を条件とする
--    IF ( gt_param.iv_notif_time_from IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_time_from IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' AND TO_CHAR(xoha.notif_date, '''|| gc_date_fmt_hh24mi ||''') >= '''
      || gt_param.iv_notif_time_from ||'''' ;
    END IF ;
-- 2008/10/27 mod start1.13 統合指摘297 予定依頼区分が確定の時、確定通知実施日、時間を条件とする
--    IF ( gt_param.iv_notif_time_to IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_time_to IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' AND TO_CHAR(xoha.notif_date, '''|| gc_date_fmt_hh24mi ||''') <= '''
      || gt_param.iv_notif_time_to ||'''' ;
    END IF ;
-- 2008/07/09 mod S.Takemoto start
--    lv_sql_sik_where1 :=  lv_sql_sik_where1
--    || ' AND xoha.instruction_dept = '''|| gt_param.iv_dept ||'''' 
    IF ( gt_param.iv_dept IS NOT NULL ) THEN
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' AND xoha.instruction_dept = '''|| gt_param.iv_dept ||'''' ;
    END IF;
--
    lv_sql_sik_where1 :=  lv_sql_sik_where1
-- 2008/07/09 mod S.Takemoto end
    || ' AND (' 
    || ' (' 
    || ' '''|| gt_param.iv_plan_decide_kbn ||''' = '''|| gc_plan_decide_p ||'''' 
    || ' AND' 
    || ' xoha.notif_status IN ('''|| gc_fixa_notif_yet ||''', '''|| gc_fixa_notif_re ||''')' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' '''|| gt_param.iv_plan_decide_kbn ||''' = '''|| gc_plan_decide_d ||'''' 
    || ' AND' 
    || ' xoha.notif_status = '''|| gc_fixa_notif_end ||'''' 
    || ' )' 
    || ' )' 
    || ' AND xoha.latest_external_flag = '''|| gc_latest_external_flag ||''''
    -------------------------------------------------------------------------------
    -- 配車配送計画(アドオン)
    -------------------------------------------------------------------------------
    || ' AND xoha.delivery_no = xcs.delivery_no(+)' 
    -------------------------------------------------------------------------------
    -- 配送区分情報VIEW2
    -------------------------------------------------------------------------------
    || ' AND xoha.shipping_method_code = xsm2v.ship_method_code(+)'  -- 6/23 外部結合追加
    ------------------------------------------------
    -- 受注タイプ情報VIEW2
    ------------------------------------------------
    || ' AND xoha.order_type_id = xott2v.transaction_type_id' ;
    IF ( gt_param.iv_shukko_keitai IS NOT NULL ) THEN
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' AND xott2v.transaction_type_id = '''|| gt_param.iv_shukko_keitai ||'''' ;
    END IF ;
    lv_sql_sik_where1 :=  lv_sql_sik_where1
    || ' AND xott2v.shipping_shikyu_class = '''|| gc_ship_pro_kbn_sik ||'''' 
    || ' AND xott2v.order_category_code <> '''|| gc_order_cate_ret ||'''' 
    ------------------------------------------------
    -- OPM保管場所情報VIEW2
    ------------------------------------------------
    || ' AND xoha.deliver_from_id = xil2v.inventory_location_id' ;
    IF ( gt_param.iv_online_kbn IS NOT NULL ) THEN
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' AND xil2v.eos_control_type = '''
      || gt_param.iv_online_kbn ||'''' ;
    END IF ;
-- 2008/10/27 add start 1.13 T_TE080_BPO_620指摘47 出庫配送区分が出庫の場合、倉庫兼運送業者を除外
    IF ( gt_param.iv_shukko_haisou_kbn = gc_shukko_haisou_kbn_d ) THEN
      lv_sql_sik_where1 :=  lv_sql_sik_where1 
-- 2008/11/27 v1.17 UPDATE START
--      || ' AND ( xil2v.eos_detination <> xc2v.eos_detination ) ' ;
      || ' AND ( '
      || '       ( xil2v.eos_detination IS NULL ) '
      || '       OR '
      || '       ( xc2v.eos_detination IS NULL ) '
      || '       OR '
      || '       ( xil2v.eos_detination <> xc2v.eos_detination ) '
      || '     ) ' ;
-- 2008/11/27 v1.17 UPDATE END
    END IF ;
-- 2008/10/27 add end 1.13 
    lv_sql_sik_where1 :=  lv_sql_sik_where1
    || ' AND (' 
    || ' xil2v.distribution_block IN ('''|| gt_param.iv_block1 ||''', '''
      || gt_param.iv_block2 ||''', '''
      || gt_param.iv_block3 ||''')' 
    || ' OR' 
    || ' xoha.deliver_from = '''|| gt_param.iv_shipped_locat_code ||'''' 
    || ' OR' 
    || ' (' 
    || ' '''|| gt_param.iv_block1 ||''' IS NULL ' 
    || ' AND' 
    || ' '''|| gt_param.iv_block2 ||''' IS NULL ' 
    || ' AND' 
    || ' '''|| gt_param.iv_block3 ||''' IS NULL ' 
    || ' AND' 
    || ' '''|| gt_param.iv_shipped_locat_code ||''' IS NULL' 
    || ' )' 
    || ' )' 
    -------------------------------------------------------------------------------
    -- 仕入先サイト情報VIEW2
    -------------------------------------------------------------------------------
    || ' AND xoha.vendor_site_id = xvs2v.vendor_site_id' 
    || ' AND xvs2v.start_date_active <= xoha.schedule_ship_date' 
    || ' AND (' 
    || ' xvs2v.end_date_active >= xoha.schedule_ship_date' 
    || ' OR' 
    || ' xvs2v.end_date_active IS NULL' 
    || ' )' ;
    -------------------------------------------------------------------------------
    -- 仕入先情報VIEW2
    -------------------------------------------------------------------------------
    ----------------------------------------------------------------------
    -- 管轄拠点
    -- 管轄拠点（名称）
--
    lv_sql_sik_where2 :=  lv_sql_sik_where2
    || ' AND xoha.vendor_id = xv2v.vendor_id' 
    || ' AND xv2v.start_date_active <= xoha.schedule_ship_date' 
    || ' AND (' 
    || ' xv2v.end_date_active >= xoha.schedule_ship_date' 
    || ' OR' 
    || ' xv2v.end_date_active IS NULL' 
    || ' )' 
    ----------------------------------------------------------------------
    ------------------------------------------------
    -- 運送業者情報VIEW2
    ------------------------------------------------
    ----------------------------------------------------------------------
    -- 運送業者
    -- 運送業者（名称）
    || ' AND xoha.career_id = xc2v.party_id(+)' 
    || ' AND (' 
    || ' xc2v.start_date_active <= xoha.schedule_ship_date' 
    || ' OR' 
    || ' xc2v.start_date_active IS NULL' 
    || ' )' 
    || ' AND (' 
    || ' xc2v.end_date_active >= xoha.schedule_ship_date' 
    || ' OR' 
    || ' xc2v.end_date_active IS NULL' 
    || ' )' 
    ----------------------------------------------------------------------
    || ' AND (' 
    || ' (' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_d ||''' ' 
    || ' AND' 
    || ' xoha.freight_carrier_code <> xoha.deliver_from' 
    || ' )' 
    || ' OR' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_p ||''' ' 
    || ' )' 
    ------------------------------------------------
    -- 受注明細アドオン
    ------------------------------------------------
    || ' AND xoha.order_header_id = xola.order_header_id' 
    || ' AND xola.delete_flag <> '''|| gc_delete_flg ||'''' 
-- 2008/11/07 Y.Yamamoto v1.14 add start
    || ' AND xola.quantity     > 0'
-- 2008/11/07 Y.Yamamoto v1.14 add end
    ------------------------------------------------
    -- OPM品目情報VIEW2
    ------------------------------------------------
    || ' AND xola.shipping_inventory_item_id = xim2v.inventory_item_id '
    || ' AND xim2v.start_date_active <= xoha.schedule_ship_date' 
    || ' AND (' 
    || ' xim2v.end_date_active >= xoha.schedule_ship_date' 
    || ' OR' 
    || ' xim2v.end_date_active IS NULL' 
    || ' )' 
    ------------------------------------------------
    -- OPM品目カテゴリ割当情報VIEW4
    ------------------------------------------------
-- 2008/11/20 Y.Yamamoto v1.16 update start
--    || ' AND xim2v.item_id = xic4v.item_id' 
    || ' AND xim2v.item_id = xic4v.item_id' ;
    IF (gv_papf_attribute3 = gc_user_kbn_inside) THEN
      -- 商品区分セキュリティのチェックは内部ユーザーのみ行うように修正
      lv_sql_sik_where2 :=  lv_sql_sik_where2
    || ' AND xic4v.prod_class_code = ''' || gv_prod_kbn ||'''' ;
    END IF;
-- 2008/11/20 Y.Yamamoto v1.16 update start
    IF ( gt_param.iv_item_kbn IS NOT NULL ) THEN
      lv_sql_sik_where2 :=  lv_sql_sik_where2
      || ' AND xic4v.item_class_code = '''|| gt_param.iv_item_kbn ||'''' ;
    END IF ;
    lv_sql_sik_where2 :=  lv_sql_sik_where2
    ------------------------------------------------
    -- 移動ロット詳細(アドオン)
    ------------------------------------------------
    || ' AND xola.order_line_id = xmld.mov_line_id(+)' 
    || ' AND xmld.document_type_code(+) = ' || gc_doc_type_code_shikyu
    || ' AND xmld.record_type_code(+)   = ' || gc_rec_type_code_ins
    -------------------------------------------------------------------------------
    -- OPMロットマスタ
    -------------------------------------------------------------------------------
    || ' AND xmld.lot_id = ilm.lot_id(+) ' 
    || ' AND xmld.item_id = ilm.item_id(+) ' 
    ------------------------------------------------
    -- ユーザ情報
    ------------------------------------------------
    || ' AND fu.user_id = '''|| FND_GLOBAL.USER_ID ||'''' 
    || ' AND fu.employee_id = papf.person_id' 
-- 2008/11/13 Y.Yamamoto v1.15 add start
    || ' AND xoha.schedule_ship_date   BETWEEN papf.effective_start_date' 
    || ' AND NVL(papf.effective_end_date, xoha.schedule_ship_date)' 
-- 2008/11/13 Y.Yamamoto v1.15 add end
    || ' AND (' 
    || ' NVL(papf.attribute3, '''|| gc_user_kbn_inside ||''') = '''|| gc_user_kbn_inside ||'''' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute3 = '''|| gc_user_kbn_outside ||'''' 
    || ' AND' 
    || ' (' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NULL ' 
    || ' AND' 
    || ' xil2v.purchase_code = papf.attribute4 ' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' (' 
    || ' xil2v.purchase_code = papf.attribute4 ' 
    || ' OR' 
    || ' xoha.freight_carrier_code = papf.attribute5 ' 
    || ' )' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' xoha.freight_carrier_code = papf.attribute5 ' 
-- 2008/07/09 add S.Takemoto start
    -- 従業員区分が'外部'で、｢運賃区分＝対象｣または｢強制出力フラグ＝対象｣の場合、出力対象外
    || ' AND'
    || ' xoha.freight_charge_class =''' || gc_freight_charge_code_1 || ''''       -- 運賃区分
-- 2008/11/20 Y.Yamamoto v1.16 update start
--    || ' AND'
    || ' OR'
-- 2008/11/20 Y.Yamamoto v1.16 update end
    || ' xc2v.complusion_output_code =''' || gc_freight_charge_code_1|| ''''      -- 強制出力区分
-- 2008/07/09 add S.Takemoto end
    || ' )' 
    || ' )' 
    || ' )' 
    || ' )' 
--mod start 1.2
--    || ' UNION ALL' ;
    ;
    lb_union := true;
  END IF;
--mod end 1.2
--
--add start 1.2
  IF (NVL(gt_param.iv_gyoumu_shubetsu,gc_biz_type_cd_move) = gc_biz_type_cd_move) THEN
    IF (lb_union) THEN
      lv_sql_ido_sel_from1 := ' UNION ALL' ;
    END IF;
--add end 1.2
    lv_sql_ido_sel_from1  :=  lv_sql_ido_sel_from1
    --=====================================================================
    -- 移動情報
    --=====================================================================
    || ' SELECT' 
    || ' '''|| gc_biz_type_nm_move ||''' AS gyoumu_shubetsu ' 
    || ' ,'''|| gc_biz_type_cd_move ||''' AS gyoumu_shubetsu_code ' 
    || ' ,xil2v1.distribution_block AS dist_block' 
    || ' ,xmrih.freight_carrier_code AS freight_carrier_code ' 
    || ' ,xc2v.party_name AS carrier_full_name '
    || ' ,xmrih.shipped_locat_code AS deliver_from ' 
    || ' ,xil2v1.description AS description ' 
    || ' ,xmrih.schedule_ship_date AS schedule_ship_date ' 
-- 2008/10/27 ADD start 1.13 T_TE080_BPO_620指摘47 ソート順変更
    || ' ,xic4v.item_class_code AS item_class_code ' 
-- 2008/10/27 ADD end 1.13 
    || ' ,xic4v.item_class_name AS item_class_name ' 
    || ' ,DECODE(xmrih.new_modify_flg, '''
      || gc_new_modify_flg_mod ||''', '''
      || gc_asterisk ||''', NULL) AS new_modify_flg ' 
    || ' ,xmrih.schedule_arrival_date AS schedule_arrival_date' 
    || ' ,xmrih.delivery_no AS delivery_no ' 
    || ' ,xmrih.shipping_method_code AS shipping_method_code ' 
    || ' ,xsm2v.ship_method_meaning AS ship_method_meaning ' 
    || ' ,NULL AS head_sales_branch ' 
    || ' ,NULL AS party_name ' 
    || ' ,xmrih.ship_to_locat_code AS deliver_to ' 
    || ' ,xil2v2.description AS party_site_full_name ' 
    || ' ,xl2v.address_line1 AS address_line1 ' 
    || ' ,NULL AS address_line2 ' 
    || ' ,xl2v.phone AS phone ' 
    || ' ,xmrih.arrival_time_from AS arrival_time_from ' 
    || ' ,xmrih.arrival_time_to AS arrival_time_to ' 
    || ' ,xcs.sum_loading_capacity AS sum_loading_capacity ' 
    || ' ,xcs.sum_loading_weight AS sum_loading_weight ' 
    || ' ,xmrih.mov_num AS req_mov_no ' 
    || ' ,CASE' 
    || ' WHEN ( xsm2v.small_amount_class = '''|| gc_small_amount_enabled ||''' ) THEN' 
    || ' CASE ' 
    || ' WHEN ( xmrih.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''' ) THEN' 
    || ' xmrih.sum_weight' 
    || ' WHEN ( xmrih.weight_capacity_class = '''|| gc_wei_cap_kbn_c ||''' ) THEN' 
    || ' xmrih.sum_capacity' 
    || ' END'
    || ' WHEN  xsm2v.small_amount_class IS NULL THEN'   -- 6/23 追加
    || ' NULL'
    || ' ELSE' 
    || ' CASE ' 
    || ' WHEN ( xmrih.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''' ) THEN' 
-- 2009/01/23 v1.18 N.Yoshida UPDATE START
--    || ' xmril.pallet_weight + xmrih.sum_weight' 
    || ' NVL(xmrih.sum_pallet_weight, 0) + xmrih.sum_weight' 
    || ' WHEN ( xmrih.weight_capacity_class = '''|| gc_wei_cap_kbn_c ||''' ) THEN' 
--    || ' xmril.pallet_weight + xmrih.sum_capacity' 
-- 2009/02/04 Y.Kanami 本番#41対応 Start --
    || ' xmrih.sum_capacity' 
--    || ' NVL(xmrih.sum_pallet_weight, 0) + xmrih.sum_capacity' 
-- 2009/02/04 Y.Kanami 本番#41対応 End   --
-- 2009/01/23 v1.18 N.Yoshida UPDATE END
    || ' END' 
    || ' END AS sum_weightm_capacity' 
    || ' ,CASE' 
    || ' WHEN (xmrih.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''') THEN' 
    || ' '''|| gv_uom_weight ||'''' 
    || ' ELSE' 
    || ' '''|| gv_uom_capacity ||'''' 
    || ' END AS sum_weightm_capacity_t ' 
    || ' ,xmrih.batch_no AS tehai_no ' 
    || ' ,xmrih.prev_delivery_no AS prev_delivery_no ' 
    || ' ,NULL AS po_no ' 
    || ' ,NULL AS jpr_user_code ' ;
--
    lv_sql_ido_sel_from2  :=  lv_sql_ido_sel_from2
    || ' ,xmrih.collected_pallet_qty AS collected_pallet_qty ' 
    || ' ,xmrih.description AS shipping_instructions ' 
    || ' ,xmrih.slip_number AS slip_number ' 
    || ' ,xmrih.small_quantity AS small_quantity ' 
    || ' ,xmril.item_code AS item_code ' 
    || ' ,xim2v.item_short_name AS item_name ' 
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620指摘47 ソート順変更
    || ' ,xmld.lot_id AS lot_id ' 
-- 2008/10/27 mod end 1.13 
    || ' ,xmld.lot_no AS lot_no ' 
    || ' ,ilm.attribute1 AS attribute1 ' 
    || ' ,ilm.attribute3 AS attribute3 ' 
    || ' ,ilm.attribute2 AS attribute2 ' 
    || ' ,CASE' 
    || ' WHEN ( xic4v.item_class_code = '''|| gc_item_cd_prdct ||''' ) THEN' 
    || ' xim2v.num_of_cases' 
    || ' WHEN ( ( xic4v.item_class_code = '''|| gc_item_cd_material ||'''' 
    || ' OR xic4v.item_class_code = '''|| gc_item_cd_prdct_half ||''' )' 
    || ' AND ilm.attribute6 IS NOT NULL ) THEN' 
    || ' ilm.attribute6' 
-- 2009/02/04 Y.Kanami 本番#41対応 Start --
    || ' WHEN ((ilm.attribute6 IS NULL)'
    || ' OR (xim2v.lot_ctl <> '''|| gc_lot_ctl_manage ||''' )) THEN'     -- ロット管理されていない
--    || ' WHEN ( ilm.attribute6 IS NULL ) THEN' 
-- 2009/02/04 Y.Kanami 本番#41対応 End ----
    || ' xim2v.frequent_qty' 
    || ' END AS num_of_cases' 
    || ' ,xim2v.net AS net' 
    || ' ,CASE' 
    || ' WHEN ( xmril.reserved_quantity > 0 ) THEN' 
    || ' CASE ' 
    || ' WHEN ( xic4v.prod_class_code = '''|| gc_prod_cd_drink ||'''' 
-- mod start 1.12
--    || ' AND xic4v.item_class_code = '''|| gc_item_cd_prdct ||''' ) THEN' 
    || ' AND xic4v.item_class_code = '''|| gc_item_cd_prdct ||'''' 
    || ' AND xim2v.conv_unit IS NOT NULL ) THEN' 
    || ' xmld.actual_quantity / TO_NUMBER( '
    || ' CASE WHEN xim2v.num_of_cases > 0 '
    || ' THEN  xim2v.num_of_cases '
    || ' ELSE TO_CHAR(1) '
    || ' END)' 
    || ' ELSE' 
    || ' xmld.actual_quantity' 
    || ' END' 
    || ' WHEN ( ( xmril.reserved_quantity IS NULL )' 
    || ' OR (xmril.reserved_quantity = 0 ) ) THEN' 
    || ' CASE ' 
    || ' WHEN ( xic4v.prod_class_code = '''|| gc_prod_cd_drink ||'''' 
--    || ' AND xic4v.item_class_code = '''|| gc_item_cd_prdct ||''' ) THEN' 
    || ' AND xic4v.item_class_code = '''|| gc_item_cd_prdct ||'''' 
    || ' AND xim2v.conv_unit IS NOT NULL ) THEN' 
-- mod end 1.12
    || ' xmril.instruct_qty / TO_NUMBER( '
    || ' CASE WHEN xim2v.num_of_cases > 0 '
    || ' THEN  xim2v.num_of_cases '
    || ' ELSE TO_CHAR(1) '
    || ' END)' 
    || ' ELSE' 
    || ' xmril.instruct_qty' 
    || ' END' 
    || ' END AS qty' 
    || ' ,CASE' 
    || ' WHEN ( xic4v.prod_class_code = '''|| gc_prod_cd_drink ||'''' 
    || ' AND xic4v.item_class_code = '''|| gc_item_cd_prdct ||'''' 
-- 2008/10/27 add start 1.13 課題32 単位/入数換算ロジック修正
    || ' AND xim2v.num_of_cases > 0 ' 
-- 2008/10/27 add end 1.13 
    || ' AND xim2v.conv_unit IS NOT NULL ) THEN' 
    || ' xim2v.conv_unit' 
    || ' ELSE' 
    || ' xim2v.item_um' 
    || ' END AS conv_unit'
    || ' FROM' 
    || ' xxinv_mov_req_instr_headers xmrih '  -- 移動依頼/指示ヘッダ(アドオン)
    || ' ,xxinv_mov_req_instr_lines xmril '   -- 移動依頼/指示明細(アドオン)
    || ' ,xxwsh_carriers_schedule xcs '       -- 配車配送計画（アドオン）
    || ' ,xxcmn_item_locations2_v xil2v1 '    -- OPM保管場所情報VIEW2(出)
    || ' ,xxcmn_item_locations2_v xil2v2 '    -- OPM保管場所情報VIEW2(入)
    || ' ,xxcmn_locations2_v xl2v '           -- 事業所情報VIEW2
    || ' ,xxcmn_carriers2_v xc2v '            -- 運送業者情報VIEW2
    || ' ,xxcmn_item_mst2_v xim2v '           -- OPM品目情報VIEW2
    || ' ,xxcmn_item_categories4_v xic4v '    -- OPM品目カテゴリ割当情報VIEW4
    || ' ,xxinv_mov_lot_details xmld '        -- 移動ロット詳細(アドオン)
    || ' ,ic_lots_mst ilm '                   -- OPMロットマスタ
    || ' ,fnd_user fu '                       -- ユーザーマスタ
    || ' ,per_all_people_f papf '             -- 従業員情報VIEW2
    || ' ,xxwsh_ship_method2_v xsm2v ' ;      -- 配送区分情報VIEW2
--
    lv_sql_ido_where1 :=  lv_sql_ido_where1
    || ' WHERE' ;
    -------------------------------------------------------------------------------
    -- 移動依頼/指示ヘッダ(アドオン)
    -------------------------------------------------------------------------------
    IF ( gt_param.iv_mov_num IS NOT NULL ) THEN
      lv_sql_ido_where1 :=  lv_sql_ido_where1
      || ' xmrih.mov_num = '''|| gt_param.iv_mov_num ||''' AND ' ;
    END IF ;
    lv_sql_ido_where1 :=  lv_sql_ido_where1
    || '     xmrih.mov_type <> '''|| gc_mov_type_not_ship ||''' ' 
    || ' AND xmrih.status >= '''|| gc_move_status_ordered ||'''' 
    || ' AND xmrih.status <> '''|| gc_move_status_not ||'''' 
    || ' AND xmrih.schedule_ship_date >= '''|| TRUNC(gt_param.iv_ship_from) ||'''' 
    || ' AND xmrih.schedule_ship_date <= '''|| TRUNC(gt_param.iv_ship_to) ||'''' ;
-- 2008/10/27 mod start1.13 統合指摘297 予定依頼区分が確定の時、確定通知実施日、時間を条件とする
--    IF ( gt_param.iv_notif_date IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_date IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_ido_where1 :=  lv_sql_ido_where1
      || ' AND TRUNC(TO_DATE(xmrih.notif_date, '''|| gc_date_fmt_all ||'''))' 
      || ' = TRUNC(TO_DATE('''|| TRUNC(gt_param.iv_notif_date) ||''', '''
      || gc_date_fmt_all ||'''))' ;
    END IF ;
-- 2008/10/27 mod start1.13 統合指摘297 予定依頼区分が確定の時、確定通知実施日、時間を条件とする
--    IF ( gt_param.iv_notif_time_from IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_time_from IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_ido_where1 :=  lv_sql_ido_where1
      || ' AND TO_CHAR(xmrih.notif_date, '''|| gc_date_fmt_hh24mi ||''') >= '''
      || gt_param.iv_notif_time_from ||'''' ;
    END IF ;
-- 2008/10/27 mod start1.13 統合指摘297 予定依頼区分が確定の時、確定通知実施日、時間を条件とする
--    IF ( gt_param.iv_notif_time_to IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_time_to IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_ido_where1 :=  lv_sql_ido_where1
      || ' AND TO_CHAR(xmrih.notif_date, '''|| gc_date_fmt_hh24mi ||''') <= '''
      || gt_param.iv_notif_time_to ||'''' ;
    END IF ;
-- 2008/07/09 mod S.Takemoto start
--    lv_sql_ido_where1 :=  lv_sql_ido_where1
--    || ' AND xmrih.instruction_post_code = '''|| gt_param.iv_dept ||'''' ;
    IF ( gt_param.iv_dept IS NOT NULL ) THEN
      lv_sql_ido_where1 :=  lv_sql_ido_where1
      || ' AND xmrih.instruction_post_code = '''|| gt_param.iv_dept ||'''' ;
    END IF;
-- 2008/07/09 mod S.Takemoto end
    IF ( gt_param.iv_freight_carrier_code IS NOT NULL ) THEN
      --2008/07/04 ST不具合対応#409
      --lv_sql_ido_where1 :=  lv_sql_ido_where1
      --|| ' AND xmrih.career_id = '''|| gt_param.iv_freight_carrier_code ||'''' ;
      lv_sql_ido_where1 :=  lv_sql_ido_where1
      || ' AND xmrih.freight_carrier_code = '''|| gt_param.iv_freight_carrier_code ||'''' ;
      --2008/07/04 ST不具合対応#409
    END IF ;
    lv_sql_ido_where1 :=  lv_sql_ido_where1
    || ' AND (' 
    || ' (' 
    || ' '''|| gt_param.iv_plan_decide_kbn ||''' = '''
    || gc_plan_decide_p ||'''' 
    || ' AND' 
    || ' xmrih.notif_status IN ('''|| gc_fixa_notif_yet ||''', '''
      || gc_fixa_notif_re ||''')' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' '''|| gt_param.iv_plan_decide_kbn ||''' = '''|| gc_plan_decide_d ||'''' 
    || ' AND' 
    || ' xmrih.notif_status = '''|| gc_fixa_notif_end ||'''' 
    || ' )' 
    || ' )' 
-- 2008/11/13 Y.Yamamoto v1.15 add start
    || ' AND ((xmrih.no_instr_actual_class IS NULL)' 
    || ' OR (xmrih.no_instr_actual_class <> ''' || gc_no_instr_actual_class_y ||'''))' 
-- 2008/11/13 Y.Yamamoto v1.15 add end
    -------------------------------------------------------------------------------
    -- 配車配送計画(アドオン)
    -------------------------------------------------------------------------------
    || ' AND xmrih.delivery_no = xcs.delivery_no(+)' 
    -------------------------------------------------------------------------------
    -- 配送区分情報VIEW2
    -------------------------------------------------------------------------------
    || ' AND xmrih.shipping_method_code = xsm2v.ship_method_code(+)'  -- 6/23 外部結合追加
    -------------------------------------------------------------------------------
    -- OPM保管場所マスタ（出）
    -------------------------------------------------------------------------------
    || ' AND xmrih.shipped_locat_id = xil2v1.inventory_location_id' ;
    IF ( gt_param.iv_online_kbn IS NOT NULL ) THEN
      lv_sql_ido_where1 :=  lv_sql_ido_where1
      || ' AND xil2v1.eos_control_type = '''|| gt_param.iv_online_kbn ||'''' ;
    END IF ;
    lv_sql_ido_where1 :=  lv_sql_ido_where1
    || ' AND (' 
    || ' xil2v1.distribution_block IN ('''|| gt_param.iv_block1 ||''', '''
      || gt_param.iv_block2 ||''', '''
      || gt_param.iv_block3 ||''')' 
    || ' OR' 
    || ' xmrih.shipped_locat_code = '''
    || gt_param.iv_shipped_locat_code ||'''' 
    || ' OR' 
    || ' (' 
    || ' '''|| gt_param.iv_block1 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_block2 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_block3 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_shipped_locat_code ||''' IS NULL' 
    || ' )' 
    || ' )' 
    -------------------------------------------------------------------------------
    -- OPM保管場所マスタ（入）
    -------------------------------------------------------------------------------
    || ' AND xmrih.ship_to_locat_id = xil2v2.inventory_location_id' 
-- 2008/10/27 add start 1.13 T_TE080_BPO_620指摘47 出庫配送区分が出庫の場合、倉庫兼運送業者を除外
    ;
    IF ( gt_param.iv_shukko_haisou_kbn = gc_shukko_haisou_kbn_d ) THEN
      lv_sql_ido_where1 :=  lv_sql_ido_where1 
-- 2008/11/27 v1.17 UPDATE START
--      || ' AND ( xil2v1.eos_detination <> xc2v.eos_detination ) ' ;
      || ' AND ( '
      || '       ( xil2v1.eos_detination IS NULL ) '
      || '       OR '
      || '       ( xc2v.eos_detination IS NULL ) '
      || '       OR '
      || '       ( xil2v1.eos_detination <> xc2v.eos_detination ) '
      || '     ) ' ;
-- 2008/11/27 v1.17 UPDATE END
    END IF ;
    lv_sql_ido_where1 :=  lv_sql_ido_where1 
-- 2008/10/27 add end 1.13 
    -------------------------------------------------------------------------------
    -- 事業所情報VIEW2
    -------------------------------------------------------------------------------
    || ' AND xil2v2.location_id = xl2v.location_id' 
    || ' AND xl2v.start_date_active <= xmrih.schedule_ship_date' 
    || ' AND (' 
    || ' xl2v.end_date_active >= xmrih.schedule_ship_date' 
    || ' OR' 
    || ' xl2v.end_date_active IS NULL' 
    || ' )' ;
    -------------------------------------------------------------------------------
    -- 運送業者情報VIEW2
    -------------------------------------------------------------------------------
    ----------------------------------------------------------------------
    -- 運送業者
    -- 運送業者（名称）
--
    lv_sql_ido_where2 :=  lv_sql_ido_where2 
    || ' AND xmrih.career_id = xc2v.party_id(+)' 
    || ' AND (' 
    || ' xc2v.start_date_active IS NULL' 
    || ' OR' 
    || ' xc2v.start_date_active <= xmrih.schedule_ship_date' 
    || ' )' 
    || ' AND (' 
    || ' xc2v.end_date_active >= xmrih.schedule_ship_date' 
    || ' OR' 
    || ' xc2v.end_date_active IS NULL' 
    || ' )' 
    ----------------------------------------------------------------------
    || ' AND (' 
    || ' (' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_d ||'''' 
    || ' AND' 
    || ' xmrih.freight_carrier_code <> xmrih.shipped_locat_code' 
    || ' )' 
    || ' OR' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_p ||'''' 
    || ' )' 
    -------------------------------------------------------------------------------
    -- 移動依頼/指示明細(アドオン)
    -------------------------------------------------------------------------------
    || ' AND xmrih.mov_hdr_id = xmril.mov_hdr_id' 
    || ' AND xmril.delete_flg <> '''|| gc_delete_flg ||'''' 
-- 2008/11/07 Y.Yamamoto v1.14 add start
    || ' AND xmril.instruct_qty > 0'
-- 2008/11/07 Y.Yamamoto v1.14 add end
    -------------------------------------------------------------------------------
    -- OPM品目情報VIEW2
    -------------------------------------------------------------------------------
    || ' AND xmril.item_id = xim2v.item_id' 
    || ' AND xim2v.start_date_active <= xmrih.schedule_ship_date' 
    || ' AND (' 
    || ' xim2v.end_date_active IS NULL' 
    || ' OR' 
    || ' xim2v.end_date_active >= xmrih.schedule_ship_date' 
    || ' )' 
--
    -------------------------------------------------------------------------------
    -- OPM品目カテゴリ割当情報VIEW4
    -------------------------------------------------------------------------------
-- 2008/11/20 Y.Yamamoto v1.16 update start
--    || ' AND xim2v.item_id = xic4v.item_id' 
    || ' AND xim2v.item_id = xic4v.item_id' ;
    IF (gv_papf_attribute3 = gc_user_kbn_inside) THEN
      -- 商品区分セキュリティのチェックは内部ユーザーのみ行うように修正
      lv_sql_ido_where2 :=  lv_sql_ido_where2
    || ' AND xic4v.prod_class_code = '''|| gv_prod_kbn ||'''' ;
    END IF;
-- 2008/11/20 Y.Yamamoto v1.16 update end
    IF ( gt_param.iv_item_kbn IS NOT NULL ) THEN
      lv_sql_ido_where2 :=  lv_sql_ido_where2 
      || ' AND xic4v.item_class_code = '''
      || gt_param.iv_item_kbn ||'''' ;
    END IF ;
    -------------------------------------------------------------------------------
    -- 移動ロット詳細(アドオン)
    -------------------------------------------------------------------------------
    lv_sql_ido_where2 :=  lv_sql_ido_where2
    || ' AND xmril.mov_line_id = xmld.mov_line_id(+)' 
    || ' AND xmld.document_type_code(+) = ' || gc_doc_type_code_mv
    || ' AND xmld.record_type_code(+)   = ' || gc_rec_type_code_ins
    -------------------------------------------------------------------------------
    -- OPMロットマスタ
    -------------------------------------------------------------------------------
    || ' AND xmld.lot_id = ilm.lot_id(+) ' 
    || ' AND xmld.item_id = ilm.item_id(+) ' 
    -------------------------------------------------------------------------------
    -- ユーザ情報
    -------------------------------------------------------------------------------
    || ' AND fu.user_id = '''|| FND_GLOBAL.USER_ID ||'''' 
    || ' AND fu.employee_id = papf.person_id '
-- 2008/11/13 Y.Yamamoto v1.15 add start
    || ' AND xmrih.schedule_ship_date   BETWEEN papf.effective_start_date' 
    || ' AND NVL(papf.effective_end_date, xmrih.schedule_ship_date)' 
-- 2008/11/13 Y.Yamamoto v1.15 add end
    || ' AND (' 
    || ' NVL(papf.attribute3, '''|| gc_user_kbn_inside ||''') = '''|| gc_user_kbn_inside ||''''
    || ' OR' 
    || ' (' 
    || ' papf.attribute3 = '''|| gc_user_kbn_outside ||'''' 
    || ' AND' 
    || ' (' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NULL ' 
    || ' AND' 
    || ' xil2v1.purchase_code = papf.attribute4 ' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' (' 
    || ' xil2v1.purchase_code = papf.attribute4 '
    || ' OR' 
    || ' xmrih.freight_carrier_code = papf.attribute5 ' 
    || ' )' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' xmrih.freight_carrier_code = papf.attribute5 ' 
-- 2008/07/09 add S.Takemoto start
    -- 従業員区分が'外部'で、｢運賃区分＝対象｣または｢強制出力フラグ＝対象｣の場合、出力対象外
    || ' AND' 
    || ' xmrih.freight_charge_class =''' || gc_freight_charge_code_1 || ''''       -- 運賃区分
-- 2008/11/20 Y.Yamamoto v1.16 update start
--    || ' AND' 
    || ' OR' 
-- 2008/11/20 Y.Yamamoto v1.16 update end
    || ' xc2v.complusion_output_code =''' || gc_freight_charge_code_1|| ''''      -- 強制出力区分
-- 2008/07/09 add S.Takemoto end
    || ' )' 
    || ' )' 
    || ' )' 
    || ' )' ;
--add start 1.2
  END IF;
--add end 1.2
-- 2008/07/09 add S.Takemoto start
  IF (NVL(gt_param.iv_gyoumu_shubetsu,gc_biz_type_cd_etc) = gc_biz_type_cd_etc) THEN
    IF (lb_union) THEN
      lv_sql_etc_sel_from1 := ' UNION ALL' ;
    END IF;
--
    lv_sql_etc_sel_from1  :=  lv_sql_etc_sel_from1
    --=====================================================================
    -- その他情報
    --=====================================================================
    || ' SELECT' 
    || ' '''|| gc_biz_type_nm_etc ||''' AS gyoumu_shubetsu ' 
    || ' ,'''|| gc_biz_type_cd_etc ||''' AS gyoumu_shubetsu_code ' 
    || ' ,xil2v1.distribution_block AS dist_block' 
    || ' ,xcs.carrier_code AS freight_carrier_code ' 
    || ' ,xc2v.party_name AS carrier_full_name '
    || ' ,xcs.deliver_from AS deliver_from ' 
    || ' ,xil2v1.description AS description ' 
    || ' ,xcs.schedule_ship_date AS schedule_ship_date ' 
-- 2008/10/27 ADD start 1.13 T_TE080_BPO_620指摘47 ソート順変更
    || ' ,NULL AS item_class_code ' 
-- 2008/10/27 ADD end 1.13 
    || ' ,NULL AS item_class_name ' 
    || ' ,NULL AS new_modify_flg ' 
    || ' ,xcs.schedule_arrival_date AS schedule_arrival_date' 
    || ' ,xcs.delivery_no AS delivery_no ' 
    || ' ,xcs.delivery_type AS shipping_method_code ' 
    || ' ,xsm2v.ship_method_meaning AS ship_method_meaning ' 
    || ' ,NULL AS head_sales_branch ' 
    || ' ,NULL AS party_name ' 
    || ' ,xcs.deliver_to AS deliver_to ' 
    || ' ,CASE'
    || ' WHEN ( xcs.deliver_to_code_class IN ('''|| gc_deliver_to_class_1 ||''''         -- 1:拠点
                                       || ' ,''' || gc_deliver_to_class_10 ||''' )) THEN' -- 10:顧客
    || ' xcas2v.party_site_full_name'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_11 ||''' ) THEN'   -- 11:支給先
    || ' xvs2v.vendor_site_name'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_4 ||''' ) THEN'    -- 4:移動
    || ' xil2v2.description'
    || ' END AS party_site_full_name'
    || ' ,CASE'
    || ' WHEN ( xcs.deliver_to_code_class IN ('''|| gc_deliver_to_class_1 ||''''         -- 1:拠点
                                       || ' ,''' || gc_deliver_to_class_10 ||''' )) THEN' -- 10:顧客
    || ' xcas2v.address_line1'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_11 ||''' ) THEN'   -- 11:支給先
    || ' xvs2v.address_line1'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_4 ||''' ) THEN'    -- 4:移動
    || ' xl2v.address_line1'
    || ' END AS address_line1'
    || ' ,CASE'
    || ' WHEN ( xcs.deliver_to_code_class IN ('''|| gc_deliver_to_class_1 ||''''         -- 1:拠点
                                       || ' ,''' || gc_deliver_to_class_10 ||''' )) THEN' -- 10:顧客
    || ' xcas2v.address_line2'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_11 ||''' ) THEN'   -- 11:支給先
    || ' xvs2v.address_line2'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_4 ||''' ) THEN'    -- 4:移動
    || ' NULL'
    || ' END AS address_line2'
    || ' ,CASE'
    || ' WHEN ( xcs.deliver_to_code_class IN ('''|| gc_deliver_to_class_1 ||''''         -- 1:拠点
                                       || ' ,''' || gc_deliver_to_class_10 ||''' )) THEN' -- 10:顧客
    || ' xcas2v.phone'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_11 ||''' ) THEN'   -- 11:支給先
    || ' xvs2v.phone'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_4 ||''' ) THEN'    -- 4:移動
    || ' xl2v.phone'
    || ' END AS phone'
    || ' ,NULL AS arrival_time_from ' 
    || ' ,NULL AS arrival_time_to ' 
    || ' ,xcs.sum_loading_capacity AS sum_loading_capacity ' 
    || ' ,xcs.sum_loading_weight AS sum_loading_weight ' 
    || ' ,NULL AS req_mov_no ' 
    || ' ,NULL AS sum_weightm_capacity' 
    || ' ,NULL AS sum_weightm_capacity_t ' 
--
    || ' ,NULL AS tehai_no ' 
    || ' ,NULL AS prev_delivery_no ' 
    || ' ,NULL AS po_no ' 
    || ' ,NULL AS jpr_user_code ' ;
--
    lv_sql_etc_sel_from2  :=  lv_sql_etc_sel_from2
    || ' ,NULL AS collected_pallet_qty ' 
    || ' ,NULL AS shipping_instructions ' 
    || ' ,xcs.slip_number AS slip_number ' 
    || ' ,xcs.small_quantity AS small_quantity ' 
    || ' ,NULL AS item_code ' 
    || ' ,NULL AS item_name ' 
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620指摘47 ソート順変更
    || ' ,NULL AS lot_id ' 
-- 2008/10/27 mod end 1.13 
    || ' ,NULL AS lot_no ' 
    || ' ,NULL AS attribute1 ' 
    || ' ,NULL AS attribute3 ' 
    || ' ,NULL AS attribute2 ' 
    || ' ,NULL AS num_of_cases' 
    || ' ,NULL AS net' 
    || ' ,NULL AS qty' 
    || ' ,NULL AS conv_unit'
    || ' FROM' 
    || ' xxwsh_carriers_schedule xcs '        -- 配車配送計画（アドオン）
    || ' ,xxcmn_item_locations2_v xil2v1 '    -- OPM保管場所情報VIEW2(出)
    || ' ,xxcmn_cust_acct_sites2_v xcas2v '   -- 顧客サイト情報VIEW2
    || ' ,xxcmn_vendor_sites2_v xvs2v '       -- 仕入先サイト情報VIEW2
    || ' ,xxcmn_item_locations2_v xil2v2 '    -- OPM保管場所情報VIEW2(入)
    || ' ,xxcmn_locations2_v xl2v '           -- 事業所情報VIEW2
    || ' ,xxcmn_carriers2_v xc2v '            -- 運送業者情報VIEW2
    || ' ,fnd_user fu '                       -- ユーザーマスタ
    || ' ,per_all_people_f papf '             -- 従業員情報VIEW2
    || ' ,xxwsh_ship_method2_v xsm2v ' ;      -- 配送区分情報VIEW2
--
    lv_sql_etc_where1 :=  lv_sql_etc_where1
    || ' WHERE' ;
    -------------------------------------------------------------------------------
    -- 配車配送計画アドオン
    -------------------------------------------------------------------------------
    lv_sql_etc_where1 :=  lv_sql_etc_where1 
    || ' xcs.non_slip_class ='''|| gc_non_slip_class_2 ||''''            --伝票なし配車区分 2：伝票なし配車
    || ' AND xcs.deliver_to_code_class IN('''|| gc_deliver_to_class_1  ||'''' -- 1:拠点
                               || ' ,''' || gc_deliver_to_class_4  ||''''     -- 4:移動
                               || ' ,''' || gc_deliver_to_class_10 ||''''     -- 10:顧客
                               || ' ,''' || gc_deliver_to_class_11 ||''')'    -- 11:支給先
    || ' AND xcs.schedule_ship_date >= '''|| TRUNC(gt_param.iv_ship_from) ||'''' 
    || ' AND xcs.schedule_ship_date <= '''|| TRUNC(gt_param.iv_ship_to) ||'''' ;
    IF ( gt_param.iv_freight_carrier_code IS NOT NULL ) THEN
      lv_sql_etc_where1 :=  lv_sql_etc_where1 
      || ' AND ( xcs.carrier_code = '''|| gt_param.iv_freight_carrier_code ||''')' ;
    END IF ;
-- 2008/07/29 add S.Takemoto start
-- 2008/11/20 Y.Yamamoto v1.16 update start
    IF (gv_papf_attribute3 = gc_user_kbn_inside) THEN
      -- 商品区分セキュリティのチェックは内部ユーザーのみ行うように修正
    lv_sql_etc_where1 :=  lv_sql_etc_where1 
    || ' AND xcs.prod_class ='''|| gv_prod_kbn ||'''' ;
    END IF;
-- 2008/11/20 Y.Yamamoto v1.16 update end
-- 2008/07/29 add S.Takemoto end
    -------------------------------------------------------------------------------
    -- 配送区分情報VIEW2
    -------------------------------------------------------------------------------
    lv_sql_etc_where1 :=  lv_sql_etc_where1
    || ' AND xcs.delivery_type = xsm2v.ship_method_code'  -- 配送区分
    || ' AND xcs.schedule_ship_date'                 --適用開始日 <= 出荷日(出荷予定日) <= 適用終了日
    || ' BETWEEN xsm2v.start_date_active'
    || ' AND NVL(xsm2v.end_date_active , xcs.schedule_ship_date)'
    ------------------------------------------------
    -- OPM保管場所情報VIEW2
    ------------------------------------------------
    || ' AND xcs.deliver_from_id = xil2v1.inventory_location_id';
    IF ( gt_param.iv_online_kbn IS NOT NULL ) THEN
      lv_sql_etc_where1 :=  lv_sql_etc_where1
      || ' AND xil2v1.eos_control_type = '''|| gt_param.iv_online_kbn ||'''' ;
    END IF ;
-- 2008/10/27 add start 1.13 T_TE080_BPO_620指摘47 出庫配送区分が出庫の場合、倉庫兼運送業者を除外
    IF ( gt_param.iv_shukko_haisou_kbn = gc_shukko_haisou_kbn_d ) THEN
      lv_sql_etc_where1 :=  lv_sql_etc_where1 
-- 2008/11/27 v1.17 UPDATE START
--      || ' AND ( xil2v1.eos_detination <> xc2v.eos_detination ) ' ;
      || ' AND ( '
      || '       ( xil2v1.eos_detination IS NULL ) '
      || '       OR '
      || '       ( xc2v.eos_detination IS NULL ) '
      || '       OR '
      || '       ( xil2v1.eos_detination <> xc2v.eos_detination ) '
      || '     ) ' ;
-- 2008/11/27 v1.17 UPDATE END
    END IF ;
-- 2008/10/27 add end 1.13 
    lv_sql_etc_where1 :=  lv_sql_etc_where1
    || ' AND (' 
    || ' xil2v1.distribution_block IN ( '''|| gt_param.iv_block1 ||'''' 
    || '  , '''|| gt_param.iv_block2 ||'''' 
    || '  , '''|| gt_param.iv_block3 ||''' )' 
    || ' OR' 
    || ' xcs.deliver_from = '''|| gt_param.iv_shipped_locat_code ||''' '
    || ' OR' 
    || ' (' 
    || ' '''|| gt_param.iv_block1 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_block2 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_block3 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_shipped_locat_code ||''' IS NULL' 
    || ' )' 
    || ' )' 
    ------------------------------------------------
    -- 顧客サイト情報VIEW2
    ------------------------------------------------
-- 2009/04/24 H.Itou   本番#1398対応 START --
--    || ' AND xcs.deliver_to_id = xcas2v.party_site_id(+)' 
    || ' AND xcs.deliver_to = xcas2v.party_site_number(+)' 
    || ' AND xcas2v.party_site_status(+) = ''' || gc_status_active || ''''
-- 2009/04/24 H.Itou   本番#1398対応 END ----
    || ' AND xcas2v.start_date_active(+) <= xcs.schedule_ship_date' 
    || ' AND xcas2v.end_date_active(+) >= xcs.schedule_ship_date'
    -------------------------------------------------------------------------------
    -- 仕入先サイト情報VIEW2
    -------------------------------------------------------------------------------
    || ' AND xcs.deliver_to_id = xvs2v.vendor_site_id(+)' 
    || ' AND xvs2v.start_date_active(+) <= xcs.schedule_ship_date' 
    || ' AND xvs2v.end_date_active(+) >= xcs.schedule_ship_date' 
    -------------------------------------------------------------------------------
    -- OPM保管場所マスタ（入）
    -------------------------------------------------------------------------------
    || ' AND xcs.deliver_to_id = xil2v2.inventory_location_id(+)' 
    -------------------------------------------------------------------------------
    -- 事業所情報VIEW2
    -------------------------------------------------------------------------------
    || ' AND xil2v2.location_id = xl2v.location_id(+)' 
    || ' AND ( xcs.schedule_ship_date'                 --適用開始日 <= 出荷日(出荷予定日) <= 適用終了日
    || ' BETWEEN xl2v.start_date_active'
    || ' AND NVL(xl2v.end_date_active , xcs.schedule_ship_date)'
    || ' OR xil2v2.location_id IS NULL'  --または、事業所情報未存在 外部結合とするため
    || ' )' ;
    ------------------------------------------------
    -- 運送業者情報VIEW2
    ------------------------------------------------
    ----------------------------------------------------------------------
    -- 運送業者
    -- 運送業者（名称）
    lv_sql_etc_where2 :=  lv_sql_etc_where2
    || ' AND xcs.carrier_id = xc2v.party_id' 
    || ' AND (' 
    || ' xc2v.start_date_active IS NULL' 
    || ' OR' 
    || ' xc2v.start_date_active <= xcs.schedule_ship_date' 
    || ' )' 
    || ' AND (' 
    || ' xc2v.end_date_active IS NULL' 
    || ' OR' 
    || ' xc2v.end_date_active >= xcs.schedule_ship_date' 
    || ' )' 
    ----------------------------------------------------------------------
    || ' AND (' 
    || ' (' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_d ||''' '
    || ' AND' 
    || ' xcs.carrier_code <> xcs.deliver_from' 
    || ' )' 
    || ' OR' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_p ||''' '
    || ' )' 
    ------------------------------------------------
    -- ユーザ情報
    ------------------------------------------------
    || ' AND fu.user_id = '''|| FND_GLOBAL.USER_ID ||'''' 
    || ' AND fu.employee_id = papf.person_id' 
-- 2008/11/13 Y.Yamamoto v1.15 add start
    || ' AND xcs.schedule_ship_date   BETWEEN papf.effective_start_date' 
    || ' AND NVL(papf.effective_end_date, xcs.schedule_ship_date)' 
-- 2008/11/13 Y.Yamamoto v1.15 add end
    || ' AND (' 
    || ' NVL(papf.attribute3, '''|| gc_user_kbn_inside ||''') = '''|| gc_user_kbn_inside ||'''' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute3 = '''|| gc_user_kbn_outside ||'''' 
    || ' AND' 
    || ' (' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NULL ' 
    || ' AND' 
    || ' xil2v1.purchase_code = papf.attribute4 ' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' (' 
    || ' xil2v1.purchase_code = papf.attribute4 ' 
    || ' OR' 
    || ' xcs.carrier_code = papf.attribute5 ' 
    || ' )' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' xcs.carrier_code = papf.attribute5 '
    || ' AND' 
    -- 従業員区分が'外部'で、｢運賃区分＝対象｣または｢強制出力フラグ＝対象｣の場合、出力対象外
    || ' xc2v.complusion_output_code =''' || gc_freight_charge_code_1|| ''''      -- 強制出力区分
    || ' )' 
    || ' )' 
    || ' )' 
    || ' )' 
    ;
    lb_union := true;
  END IF;
-- 2008/07/09 add S.Takemoto end
--
    lv_sql_tail := lv_sql_tail
    || ' )' 
    || ' ORDER BY' 
    || ' dist_block ASC'              -- ブロック
    || ' ,deliver_from ASC'           -- 出庫元
    || ' ,freight_carrier_code ASC'   -- 運送業者
    || ' ,schedule_ship_date ASC'     -- 出庫予定日
    || ' ,gyoumu_shubetsu_code ASC'   -- 業務種別
    || ' ,schedule_arrival_date ASC'  -- 着日
    || ' ,delivery_no ASC'            -- 配送No
    || ' ,req_mov_no ASC'             -- 依頼No/移動No
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620指摘47 ソート順変更
--    || ' ,item_code ASC' ;            -- 商品コード
    || ' ,item_code ASC'              -- 商品コード
--    || ' ,DECODE(item_class_code, ''' || gc_item_cd_prdct     || ''', attribute1 )' -- 製造日
--    || ' ,DECODE(item_class_code, ''' || gc_item_cd_prdct     || ''', attribute2 )' -- 固有記号
-- 2008/11/20 Y.Yamamoto v1.16 update start
--    || ' ,DECODE(''' || gt_param.iv_item_kbn || ''', ''' || gc_item_cd_prdct || ''', attribute1 )' -- 製造日
--    || ' ,DECODE(''' || gt_param.iv_item_kbn || ''', ''' || gc_item_cd_prdct || ''', attribute2 )' -- 固有記号
--    || ' ,DECODE(xic4v.item_class_code, ''' || gc_item_cd_prdct     || ''', ''0'' , TO_NUMBER( DECODE( lot_id, 0 , ''0'', lot_no) ) )' -- ロットNO
--    || ' ,DECODE(''' || gt_param.iv_item_kbn || ''', ''' || gc_item_cd_prdct || ''', 0 , TO_NUMBER( DECODE( lot_id, 0 , ''0'', lot_no) ) )' -- ロットNO
    || ' ,DECODE(item_class_code, ''' || gc_item_cd_prdct || ''', attribute1 )' -- 製造日
    || ' ,DECODE(item_class_code, ''' || gc_item_cd_prdct || ''', attribute2 )' -- 固有記号
    || ' ,DECODE(item_class_code, ''' || gc_item_cd_material   || ''', TO_NUMBER( DECODE( lot_id, 0 , ''0'', lot_no) ) ' 
    || '                        , ''' || gc_item_cd_shizai     || ''', TO_NUMBER( DECODE( lot_id, 0 , ''0'', lot_no) ) ' 
    || '                        , ''' || gc_item_cd_prdct_half || ''', TO_NUMBER( DECODE( lot_id, 0 , ''0'', lot_no) ) )' -- ロットNO
-- 2008/11/20 Y.Yamamoto v1.16 update start
    ;
-- 2008/10/27 mod end 1.13 
--
    -- カーソルオープン
    OPEN c_cur FOR  lv_sql_head           || lv_sql_shu_sel_from1 || lv_sql_shu_sel_from2 || 
                    lv_sql_shu_where1     || lv_sql_shu_where2    || lv_sql_sik_sel_from1 || 
                    lv_sql_sik_sel_from2  || lv_sql_sik_where1    || lv_sql_sik_where2    || 
                    lv_sql_ido_sel_from1  || lv_sql_ido_sel_from2 || lv_sql_ido_where1    ||
-- 2008/07/09 add S.Takemoto start
--                    lv_sql_ido_where2     || lv_sql_tail ;
                    lv_sql_ido_where2     || lv_sql_etc_sel_from1 || lv_sql_etc_sel_from2 ||
                    lv_sql_etc_where1     || lv_sql_etc_where2    || lv_sql_tail ;
-- 2008/07/09 add S.Takemoto end
    -- バルクフェッチ
    FETCH c_cur BULK COLLECT INTO gt_report_data ;
    -- カーソルクローズ
    CLOSE c_cur ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( c_cur%ISOPEN ) THEN
        CLOSE c_cur;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_report_data;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : XML生成処理(F-5)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
    ov_errbuf     OUT  VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT  VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT  VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ;   -- プログラム名
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
    -- *** ローカル変数 ***
    -- 前回レコード格納用
    lv_tmp_deliver_from       type_report_data.deliver_from%TYPE ;          -- 出庫元毎情報
    lv_tmp_carrier_code       type_report_data.freight_carrier_code%TYPE ;  -- 運送業者毎情報
    lv_tmp_ship_date          type_report_data.schedule_ship_date%TYPE ;    -- 出庫予定日毎情報
    lv_tmp_gyoumu_shubetsu    type_report_data.gyoumu_shubetsu%TYPE ;       -- 業務種別毎情報
    lv_tmp_delivery_no        type_report_data.delivery_no%TYPE ;           -- 配送No毎情報
    lv_tmp_request_no         type_report_data.req_mov_no%TYPE ;            -- 依頼No/移動No毎情報
    lv_tmp_item_code          type_report_data.item_code%TYPE ;             -- 品目コード毎情報
--
    -- タグ出力判定フラグ
    lb_dispflg_ship_info          BOOLEAN := TRUE ;       -- 出庫元毎情報
    lb_dispflg_career_info        BOOLEAN := TRUE ;       -- 運送業者毎情報
    lb_dispflg_career_plan_info   BOOLEAN := TRUE ;       -- 出庫予定日毎情報
    lb_dispflg_bsns_kind_info     BOOLEAN := TRUE ;       -- 業務種別毎情報
    lb_dispflg_delivery_no        BOOLEAN := TRUE ;       -- 配送No毎情報
    lb_dispflg_irai               BOOLEAN := TRUE ;       -- 依頼No/移動No毎情報
    lb_dispflg_item_code          BOOLEAN := TRUE ;       -- 品目コード毎情報
--
    -- 合計数量
    lv_sum_quantity_deli          NUMBER ;
    lv_sum_quantity_req           NUMBER ;
    lv_total_quantity             NUMBER ;
--
    -- メッセージ
    lv_msg                        VARCHAR2(100);
--
    /**********************************************************************************
     * Procedure Name   : prcsub_set_xml_data
     * Description      : タグ情報設定処理
     ***********************************************************************************/
    PROCEDURE prcsub_set_xml_data(
       ivsub_tag_name       IN  VARCHAR2                 -- タグ名
      ,ivsub_tag_value      IN  VARCHAR2                 -- データ
      ,ivsub_tag_type       IN  VARCHAR2  DEFAULT NULL   -- データ
    )
    IS
      ln_data_index  NUMBER ;    -- XMLデータを設定するインデックス
    BEGIN
      ln_data_index := gt_xml_data_table.COUNT + 1 ;
--
      gt_xml_data_table(ln_data_index).tag_name := ivsub_tag_name ;
--
      IF ((ivsub_tag_value IS NULL) AND (ivsub_tag_type = gc_tag_type_tag)) THEN
        -- タグ出力
        gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_tag;
      ELSE
        -- データ出力
        gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_data;
        gt_xml_data_table(ln_data_index).tag_value := ivsub_tag_value;
      END IF;
    END prcsub_set_xml_data ;
--
    /**********************************************************************************
     * Procedure Name   : prcsub_set_xml_data
     * Description      : タグ情報設定処理(開始・終了タグ用)
     ***********************************************************************************/
    PROCEDURE prcsub_set_xml_data(
       ivsub_tag_name       IN  VARCHAR2  -- タグ名
    )
    IS
    BEGIN
      prcsub_set_xml_data(ivsub_tag_name, NULL, gc_tag_type_tag);
    END prcsub_set_xml_data ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- -----------------------------------------------------
    -- 変数初期設定
    -- -----------------------------------------------------
    gt_xml_data_table.DELETE ;
    lv_tmp_deliver_from       := NULL ;
    lv_tmp_carrier_code       := NULL ;
    lv_tmp_ship_date          := NULL ;
    lv_tmp_gyoumu_shubetsu    := NULL ;
    lv_tmp_delivery_no        := NULL ;
    lv_tmp_request_no         := NULL ;
    lv_tmp_item_code          := NULL ;
    lv_sum_quantity_deli      := 0 ;
    lv_sum_quantity_req       := 0 ;
    lv_total_quantity         := 0 ;
--
    -- -----------------------------------------------------
    -- ヘッダ情報設定
    -- -----------------------------------------------------
    prcsub_set_xml_data('root') ;
    prcsub_set_xml_data('data_info') ;
    prcsub_set_xml_data('lg_ship_info') ;
--
    -- -----------------------------------------------------
    -- 帳票0件用XMLデータ作成
    -- -----------------------------------------------------
    IF (gt_report_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
      lv_msg  := xxcmn_common_pkg.get_msg(gc_application_cmn, gc_msg_id_no_data) ;
      prcsub_set_xml_data('g_ship_info') ;
      prcsub_set_xml_data('head_title'          , gv_report_title) ;
      prcsub_set_xml_data('chohyo_id'           , gc_report_id) ;
      prcsub_set_xml_data('exec_time'           , TO_CHAR(gd_common_sysdate, gc_date_fmt_all)) ;
    -- MOD START 2008/06/04 NAKADA dep_cdにgv_dept_nm、dep_nmにgv_user_nmを割り当てる
      prcsub_set_xml_data('dep_cd'              , gv_dept_nm) ;
      prcsub_set_xml_data('dep_nm'              , gv_user_nm) ;
    -- MOD END   2008/06/04 NAKADA
      prcsub_set_xml_data('shukko_date_from'    , TO_CHAR(gt_param.iv_ship_from
                                                        , gc_date_fmt_ymd_ja)) ;
      prcsub_set_xml_data('shukko_date_to'      , TO_CHAR(gt_param.iv_ship_to
                                                        , gc_date_fmt_ymd_ja)) ;
      prcsub_set_xml_data('lg_career_info') ;
      prcsub_set_xml_data('g_career_info') ;
      prcsub_set_xml_data('lg_career_plan_info') ;
      prcsub_set_xml_data('g_career_plan_info') ;
      prcsub_set_xml_data('lg_bsns_kind_info') ;
      prcsub_set_xml_data('g_bsns_kind_info') ;
      prcsub_set_xml_data('lg_denpyo') ;
      prcsub_set_xml_data('g_denpyo') ;
      prcsub_set_xml_data('msg', lv_msg) ;
      prcsub_set_xml_data('/g_denpyo') ;
      prcsub_set_xml_data('/lg_denpyo') ;
      prcsub_set_xml_data('/g_bsns_kind_info') ;
      prcsub_set_xml_data('/lg_bsns_kind_info') ;
      prcsub_set_xml_data('/g_career_plan_info') ;
      prcsub_set_xml_data('/lg_career_plan_info') ;
      prcsub_set_xml_data('/g_career_info') ;
      prcsub_set_xml_data('/lg_career_info') ;
      prcsub_set_xml_data('/g_ship_info') ;
    END IF ;
--
    -- -----------------------------------------------------
    -- XMLデータ作成
    -- -----------------------------------------------------
    <<detail_data_loop>>
    FOR i IN 1..gt_report_data.COUNT LOOP
--
      -- ====================================================
      -- XMLデータ設定
      -- ====================================================
      -- 出庫元毎情報
      IF ( lb_dispflg_ship_info ) THEN
        prcsub_set_xml_data('g_ship_info') ;
        prcsub_set_xml_data('head_title'          , gv_report_title) ;
        prcsub_set_xml_data('chohyo_id'           , gc_report_id) ;
        prcsub_set_xml_data('exec_time'           , TO_CHAR(gd_common_sysdate, gc_date_fmt_all)) ;
    -- MOD START 2008/06/04 NAKADA dep_cdにgv_dept_nm、dep_nmにgv_user_nmを割り当てる
        prcsub_set_xml_data('dep_cd'              , gv_dept_nm) ;
        prcsub_set_xml_data('dep_nm'              , gv_user_nm) ;
    -- MOD END   2008/06/04 NAKADA
        prcsub_set_xml_data('shukko_date_from'    , TO_CHAR(gt_param.iv_ship_from
                                                          , gc_date_fmt_ymd_ja)) ;
        prcsub_set_xml_data('shukko_date_to'      , TO_CHAR(gt_param.iv_ship_to
                                                          , gc_date_fmt_ymd_ja)) ;
        prcsub_set_xml_data('shukko_moto'         , gt_report_data(i).deliver_from) ;
        prcsub_set_xml_data('shukko_moto_nm'      , gt_report_data(i).description) ;
        prcsub_set_xml_data('lg_career_info') ;
      END IF ;
--
      -- 運送業者毎情報
      IF ( lb_dispflg_career_info ) THEN
        prcsub_set_xml_data('g_career_info') ;
        prcsub_set_xml_data('career_id'             , gt_report_data(i).freight_carrier_code) ;
        prcsub_set_xml_data('career_nm'             , gt_report_data(i).carrier_full_name) ;
        prcsub_set_xml_data('lg_career_plan_info') ;
      END IF ;
--
      -- 出庫予定日毎情報
      IF ( lb_dispflg_career_plan_info ) THEN
        prcsub_set_xml_data('g_career_plan_info') ;
        prcsub_set_xml_data('career_date'           , TO_CHAR(gt_report_data(i).schedule_ship_date
                                                            , gc_date_fmt_ymd)) ;
        prcsub_set_xml_data('lg_bsns_kind_info') ;
      END IF ;
--
      -- 業務種別毎情報
      IF ( lb_dispflg_bsns_kind_info ) THEN
        prcsub_set_xml_data('g_bsns_kind_info') ;
        prcsub_set_xml_data('bsns_kind'             , gt_report_data(i).gyoumu_shubetsu) ;
--mod start 1.10.1
--        prcsub_set_xml_data('item_kbn'              , gt_report_data(i).item_class_name) ;
        IF (gt_param.iv_item_kbn IS NOT NULL) THEN
          prcsub_set_xml_data('item_kbn'              , gt_report_data(i).item_class_name) ;
        ELSE
          prcsub_set_xml_data('item_kbn'              , NULL) ;
        END IF;
--mod end 1.10.1
        -- 運送発注元
        prcsub_set_xml_data('career_order_nm'       , gv_hchu_cat_value) ;
        prcsub_set_xml_data('career_order_adr'      , gv_hchu_address_value) ;
        prcsub_set_xml_data('career_order_tel'      , gv_hchu_tel_value) ;
        -- 運送依頼元
        prcsub_set_xml_data('career_request_nm'     , gv_irai_cat_value_full) ;
        prcsub_set_xml_data('career_request_adr'    , gv_irai_address_value) ;
        prcsub_set_xml_data('career_request_tel'    , gv_irai_tel_value) ;
        prcsub_set_xml_data('lg_denpyo') ;
      END IF;
--
      -- 配送No毎情報
      IF ( lb_dispflg_delivery_no ) THEN
        prcsub_set_xml_data('g_denpyo') ;
        prcsub_set_xml_data('new_modify_flg'        , gt_report_data(i).new_modify_flg) ;
        prcsub_set_xml_data('shukko_date'           
                          , TO_CHAR(gt_report_data(i).schedule_arrival_date
                                  , gc_date_fmt_ymd)) ;
        prcsub_set_xml_data('delivery_no'           , gt_report_data(i).delivery_no) ;
        prcsub_set_xml_data('delivery_kbn'          , gt_report_data(i).shipping_method_code) ;
        prcsub_set_xml_data('delivery_nm'           , gt_report_data(i).ship_method_meaning) ;
--mod start 1.3
--        prcsub_set_xml_data('mixed_weight'          , gt_report_data(i).sum_loading_weight) ;
--        prcsub_set_xml_data('mixed_weight_tani'     , gv_uom_weight) ;
--        prcsub_set_xml_data('mixed_capacity'        , gt_report_data(i).sum_loading_capacity) ;
--        prcsub_set_xml_data('mixed_capacity_tani'   , gv_uom_capacity) ;
        IF (gt_report_data(i).delivery_no IS NOT NULL) THEN
          --配送Noが設定されている場合
          prcsub_set_xml_data('mixed_weight'          , gt_report_data(i).sum_loading_weight) ;
          prcsub_set_xml_data('mixed_weight_tani'     , gv_uom_weight) ;
          prcsub_set_xml_data('mixed_capacity'        , gt_report_data(i).sum_loading_capacity) ;
          prcsub_set_xml_data('mixed_capacity_tani'   , gv_uom_capacity) ;
        ELSE
          --配送Noが設定されていない場合
          prcsub_set_xml_data('mixed_weight'          , NULL) ;
          prcsub_set_xml_data('mixed_weight_tani'     , NULL) ;
          prcsub_set_xml_data('mixed_capacity'        , NULL) ;
          prcsub_set_xml_data('mixed_capacity_tani'   , NULL) ;
        END IF;
--mod end 1.3
--del start 1.10.3
--        prcsub_set_xml_data('knkt_base_cd'          , gt_report_data(i).head_sales_branch) ;
--        prcsub_set_xml_data('knkt_base_nm'          , gt_report_data(i).party_name) ;
--        prcsub_set_xml_data('delivery_ship'         , gt_report_data(i).deliver_to) ;
--        prcsub_set_xml_data('delivery_ship_nm'      , gt_report_data(i).party_site_full_name) ;
--        prcsub_set_xml_data('delivery_ship_adr'
--                          , gt_report_data(i).address_line1 || gt_report_data(i).address_line2) ;
--        prcsub_set_xml_data('jpr_user_cd'           , gt_report_data(i).jpr_user_code) ;
--        prcsub_set_xml_data('tel_no'                , gt_report_data(i).phone) ;
--del end 1.10.3
        prcsub_set_xml_data('lg_irai') ;
      END IF ;
--
      -- 依頼No/移動No毎情報
      IF ( lb_dispflg_irai ) THEN
        prcsub_set_xml_data('g_irai') ;
        prcsub_set_xml_data('irai_no'               , gt_report_data(i).req_mov_no) ;
        prcsub_set_xml_data('tehai_no'              , gt_report_data(i).tehai_no) ;
        prcsub_set_xml_data('zen_delivery_no'       , gt_report_data(i).prev_delivery_no) ;
        prcsub_set_xml_data('po_no'                 , gt_report_data(i).po_no) ;
        prcsub_set_xml_data('invoice_no'            , gt_report_data(i).slip_number) ;
        prcsub_set_xml_data('tekiyo'                , gt_report_data(i).shipping_instructions) ;
        prcsub_set_xml_data('sum_weight'            , gt_report_data(i).sum_weightm_capacity) ;
        prcsub_set_xml_data('sum_weight_tani'       , gt_report_data(i).sum_weightm_capacity_t) ;
        prcsub_set_xml_data('time_shitei_from'      , gt_report_data(i).arrival_time_from) ;
        prcsub_set_xml_data('time_shitei_to'        , gt_report_data(i).arrival_time_to) ;
        prcsub_set_xml_data('kosu'                  , gt_report_data(i).small_quantity) ;
        prcsub_set_xml_data('collected_pallet_qty'  , gt_report_data(i).collected_pallet_qty) ;
--add start 1.10.3
        prcsub_set_xml_data('knkt_base_cd'          , gt_report_data(i).head_sales_branch) ;
        prcsub_set_xml_data('knkt_base_nm'          , gt_report_data(i).party_name) ;
        prcsub_set_xml_data('delivery_ship'         , gt_report_data(i).deliver_to) ;
        prcsub_set_xml_data('delivery_ship_nm'      , gt_report_data(i).party_site_full_name) ;
        prcsub_set_xml_data('delivery_ship_adr'
                          , gt_report_data(i).address_line1 || gt_report_data(i).address_line2) ;
        prcsub_set_xml_data('jpr_user_cd'           , gt_report_data(i).jpr_user_code) ;
        prcsub_set_xml_data('tel_no'                , gt_report_data(i).phone) ;
--add end 1.10.3
        prcsub_set_xml_data('lg_dtl_info') ;
      END IF ;
--
      -- 品目コード毎情報
      prcsub_set_xml_data('g_dtl_info') ;
      prcsub_set_xml_data('item_cd'                 , gt_report_data(i).item_code) ;
      prcsub_set_xml_data('item_nm'                 , gt_report_data(i).item_name) ;
      prcsub_set_xml_data('net'                     , gt_report_data(i).net) ;
      prcsub_set_xml_data('lot_no'                  , gt_report_data(i).lot_no) ;
      prcsub_set_xml_data('lot_date'                , gt_report_data(i).attribute1) ;
      prcsub_set_xml_data('best_bfr_date'           , gt_report_data(i).attribute3) ;
      prcsub_set_xml_data('lot_sign'                , gt_report_data(i).attribute2) ;
      prcsub_set_xml_data('num_qty'                 , gt_report_data(i).num_of_cases) ;
      prcsub_set_xml_data('quantity'                , gt_report_data(i).qty) ;
      prcsub_set_xml_data('quantity_tani'           , gt_report_data(i).conv_unit) ;
      prcsub_set_xml_data('/g_dtl_info') ;
--
      IF ( gt_report_data(i).qty IS NOT NULL ) THEN
        -- 依頼No/移動No単位の数量合計
        lv_sum_quantity_deli  :=  lv_sum_quantity_deli  + gt_report_data(i).qty ;
        -- 配送No単位の数量合計
        lv_sum_quantity_req   :=  lv_sum_quantity_req   + gt_report_data(i).qty ;
        -- ヘッダー単位の数量合計
        lv_total_quantity     :=  lv_total_quantity     + gt_report_data(i).qty ;
      END IF ;
--
      -- ====================================================
      -- 現在処理中のデータを保持
      -- ====================================================
      lv_tmp_deliver_from       := gt_report_data(i).deliver_from ;
      lv_tmp_carrier_code       := gt_report_data(i).freight_carrier_code ;
      lv_tmp_ship_date          := gt_report_data(i).schedule_ship_date ;
      lv_tmp_gyoumu_shubetsu    := gt_report_data(i).gyoumu_shubetsu ;
      lv_tmp_delivery_no        := gt_report_data(i).delivery_no ;
      lv_tmp_request_no         := gt_report_data(i).req_mov_no ;
      lv_tmp_item_code          := gt_report_data(i).item_code ;
--
      -- ====================================================
      -- 出力判定
      -- ====================================================
      IF (i < gt_report_data.COUNT) THEN
        -- 依頼No/移動No
        IF ( lv_tmp_request_no = gt_report_data(i + 1).req_mov_no ) THEN
          lb_dispflg_irai               :=  FALSE ;
        ELSE
          lb_dispflg_irai               :=  TRUE ;
        END IF ;
--
        -- 配送No
-- mod start 1.12
--        IF ( lv_tmp_delivery_no = gt_report_data(i + 1).delivery_no ) THEN
        IF ( lv_tmp_delivery_no = gt_report_data(i + 1).delivery_no ) 
          OR (lv_tmp_delivery_no IS NULL) THEN
-- mod end 1.12
          lb_dispflg_delivery_no        :=  FALSE ;
        ELSE
          lb_dispflg_delivery_no        :=  TRUE ;
          lb_dispflg_irai               :=  TRUE ;
        END IF ;
--
        -- 業務種別
        IF ( lv_tmp_gyoumu_shubetsu = gt_report_data(i + 1).gyoumu_shubetsu ) THEN
          lb_dispflg_bsns_kind_info     :=  FALSE ;
        ELSE
          lb_dispflg_bsns_kind_info     :=  TRUE ;
          lb_dispflg_delivery_no        :=  TRUE ;
          lb_dispflg_irai               :=  TRUE ;
        END IF ;
--
        -- 出庫予定日
        IF ( lv_tmp_ship_date = gt_report_data(i + 1).schedule_ship_date ) THEN
          lb_dispflg_career_plan_info   :=  FALSE ;
        ELSE
          lb_dispflg_career_plan_info   :=  TRUE ;
          lb_dispflg_bsns_kind_info     :=  TRUE ;
          lb_dispflg_delivery_no        :=  TRUE ;
          lb_dispflg_irai               :=  TRUE ;
        END IF ;
--
        -- 運送業者
-- mod start 1.12
--        IF ( lv_tmp_carrier_code = gt_report_data(i + 1).freight_carrier_code ) THEN
        IF ( lv_tmp_carrier_code = gt_report_data(i + 1).freight_carrier_code ) 
          OR (lv_tmp_carrier_code IS NULL) THEN
-- mod end 1.12
          lb_dispflg_career_info        :=  FALSE ;
        ELSE
          lb_dispflg_career_info        :=  TRUE ;
          lb_dispflg_career_plan_info   :=  TRUE ;
          lb_dispflg_bsns_kind_info     :=  TRUE ;
          lb_dispflg_delivery_no        :=  TRUE ;
          lb_dispflg_irai               :=  TRUE ;
        END IF ;
--
        -- 出庫元
        IF ( lv_tmp_deliver_from = gt_report_data(i + 1).deliver_from ) THEN
          lb_dispflg_ship_info          :=  FALSE ;
        ELSE
          lb_dispflg_ship_info          :=  TRUE ;
          lb_dispflg_career_info        :=  TRUE ;
          lb_dispflg_career_plan_info   :=  TRUE ;
          lb_dispflg_bsns_kind_info     :=  TRUE ;
          lb_dispflg_delivery_no        :=  TRUE ;
          lb_dispflg_irai               :=  TRUE ;
        END IF ;
--
      ELSE
        lb_dispflg_ship_info          :=  TRUE ;
        lb_dispflg_career_info        :=  TRUE ;
        lb_dispflg_career_plan_info   :=  TRUE ;
        lb_dispflg_bsns_kind_info     :=  TRUE ;
        lb_dispflg_delivery_no        :=  TRUE ;
        lb_dispflg_irai               :=  TRUE ;
      END IF;
--
      -- ====================================================
      -- 終了タグ設定
      -- ====================================================
--
      IF (lb_dispflg_irai) THEN
        prcsub_set_xml_data('/lg_dtl_info') ;
--
        -- 配送No単位の合計数量
        prcsub_set_xml_data('sum_quantity_req'      , lv_sum_quantity_req) ;
        -- 配送No単位のクリア
        lv_sum_quantity_req   :=  0;
--
        IF ( lb_dispflg_delivery_no ) THEN
          -- 依頼No/移動No単位の合計数量
--add start 1.3
          --配送Noが未設定の場合は配送No単位の数量合計は空欄とする
          IF (gt_report_data(i).delivery_no IS NULL) THEN
            lv_sum_quantity_deli := NULL;
          END IF;
--add end 1.3
          prcsub_set_xml_data('sum_quantity_deli'     , lv_sum_quantity_deli) ;
          -- 依頼No/移動No単位のクリア
          lv_sum_quantity_deli  :=  0;
        END IF ;
--
        IF (lb_dispflg_bsns_kind_info) THEN
          -- ヘッダー単位の数量合計
          prcsub_set_xml_data('total_quantity'     , lv_total_quantity) ;
          lv_total_quantity :=  0;
        END IF;
--
        prcsub_set_xml_data('/g_irai') ;
      END IF;
--
      IF (lb_dispflg_delivery_no) THEN
        prcsub_set_xml_data('/lg_irai') ;
        prcsub_set_xml_data('/g_denpyo') ;
      END IF;
--
      IF (lb_dispflg_bsns_kind_info) THEN
        prcsub_set_xml_data('/lg_denpyo') ;
        prcsub_set_xml_data('/g_bsns_kind_info') ;
      END IF;
--
      IF (lb_dispflg_career_plan_info) THEN
        prcsub_set_xml_data('/lg_bsns_kind_info') ;
        prcsub_set_xml_data('/g_career_plan_info') ;
      END IF;
--
      IF (lb_dispflg_career_info) THEN
        prcsub_set_xml_data('/lg_career_plan_info') ;
        prcsub_set_xml_data('/g_career_info') ;
      END IF;
--
      IF (lb_dispflg_ship_info) THEN
        prcsub_set_xml_data('/lg_career_info') ;
        prcsub_set_xml_data('/g_ship_info') ;
      END IF;
    END LOOP detail_data_loop;
--
    -- ====================================================
    -- 終了タグ設定
    -- ====================================================
    prcsub_set_xml_data('/lg_ship_info') ;
    prcsub_set_xml_data('/data_info') ;
    prcsub_set_xml_data('/root') ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_create_xml_data;
--
  /**********************************************************************************
   * Function Name    : fnc_convert_into_xml
   * Description      : XMLデータ変換(F-5)
   ***********************************************************************************/
  FUNCTION fnc_convert_into_xml(
    iv_name  IN VARCHAR2
   ,iv_value IN VARCHAR2
   ,ic_type  IN CHAR
  ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_convert_data VARCHAR2(2000);
--
  BEGIN
--
    --データの場合
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF ;
--
    RETURN(lv_convert_data);
--
  END fnc_convert_into_xml;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT   VARCHAR2      -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT   VARCHAR2      -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT   VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain' ;  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(32767);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(32767);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_xml_string    VARCHAR2(32000) ;
    ln_retcode       NUMBER ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- 初期処理(F-1,F-2,F-3)
    -- ===============================================
    prc_initialize(
      ov_errbuf     => lv_errbuf       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode      -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ===============================================
    -- 帳票データ取得処理(F-4)
    -- ===============================================
    prc_get_report_data(
      ov_errbuf        => lv_errbuf       --エラー・メッセージ           --# 固定 #
     ,ov_retcode       => lv_retcode      --リターン・コード             --# 固定 #
     ,ov_errmsg        => lv_errmsg       --ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML生成処理(F-5)
    -- ==================================================
    prc_create_xml_data(
      ov_errbuf        => lv_errbuf       --エラー・メッセージ           --# 固定 #
     ,ov_retcode       => lv_retcode      --リターン・コード             --# 固定 #
     ,ov_errmsg        => lv_errmsg       --ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML出力処理(F-5)
    -- ==================================================
    -- XMLヘッダ部出力
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- XMLデータ部出力
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      lv_xml_string := fnc_convert_into_xml(
                         gt_xml_data_table(i).tag_name
                        ,gt_xml_data_table(i).tag_value
                        ,gt_xml_data_table(i).tag_type
                       ) ;
      -- XMLデータ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_xml_string) ;
    END LOOP xml_loop ;
--
    --XMLデータ削除
    gt_xml_data_table.DELETE ;
--
    IF ((lv_retcode = gv_status_warn) AND (gt_report_data.COUNT = 0)) THEN
      RAISE no_data_expt ;
    END IF ;
--
  EXCEPTION
    -- *** 帳票0件例外ハンドラ ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
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
     errbuf                     OUT    VARCHAR2         --  エラー・メッセージ  --# 固定 #
    ,retcode                    OUT    VARCHAR2         --  リターン・コード    --# 固定 #
    ,iv_dept                    IN     VARCHAR2         --  01 : 部署
    ,iv_plan_decide_kbn         IN     VARCHAR2         --  02 : 予定/確定区分
    ,iv_ship_from               IN     VARCHAR2         --  03 : 出庫日From
    ,iv_ship_to                 IN     VARCHAR2         --  04 : 出庫日To
    ,iv_shukko_haisou_kbn       IN     VARCHAR2         --  05 : 出庫/配送区分
    ,iv_gyoumu_shubetsu         IN     VARCHAR2         --  06 : 業務種別
    ,iv_notif_date              IN     VARCHAR2         --  07 : 確定通知実施日
    ,iv_notif_time_from         IN     VARCHAR2         --  08 : 確定通知実施時間From
    ,iv_notif_time_to           IN     VARCHAR2         --  09 : 確定通知実施時間To
    ,iv_freight_carrier_code    IN     VARCHAR2         --  10 : 運送業者
    ,iv_block1                  IN     VARCHAR2         --  11 : ブロック1
    ,iv_block2                  IN     VARCHAR2         --  12 : ブロック2
    ,iv_block3                  IN     VARCHAR2         --  13 : ブロック3
    ,iv_shipped_locat_code      IN     VARCHAR2         --  14 : 出庫元
    ,iv_mov_num                 IN     VARCHAR2         --  15 : 依頼No/移動No
    ,iv_shime_date              IN     VARCHAR2         --  16 : 締め実施日
    ,iv_shime_time_from         IN     VARCHAR2         --  17 : 締め実施時間From
    ,iv_shime_time_to           IN     VARCHAR2         --  18 : 締め実施時間To
    ,iv_online_kbn              IN     VARCHAR2         --  19 : オンライン対象区分
    ,iv_item_kbn                IN     VARCHAR2         --  20 : 品目区分
    ,iv_shukko_keitai           IN     VARCHAR2         --  21 : 出庫形態
    ,iv_unsou_irai_inzi_kbn     IN     VARCHAR2         --  22 : 運送依頼元印字区分
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main' ; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(32767);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(32767);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- 変数初期設定
    -- ===============================================
    -- 入力パラメータをグローバル変数に保持
    gt_param.iv_dept                    := iv_dept ;                  --  01 : 部署
    gt_param.iv_plan_decide_kbn         := iv_plan_decide_kbn ;       --  02 : 予定/確定区分
    --  03 : 出庫日From
    gt_param.iv_ship_from               := FND_DATE.CANONICAL_TO_DATE(iv_ship_from) ;
    --  04 : 出庫日To
    gt_param.iv_ship_to                 := FND_DATE.CANONICAL_TO_DATE(iv_ship_to) ;
    gt_param.iv_shukko_haisou_kbn       := iv_shukko_haisou_kbn ;     --  05 : 出庫/配送区分
    gt_param.iv_gyoumu_shubetsu         := iv_gyoumu_shubetsu ;       --  06 : 業務種別
    --  07 : 確定通知実施日
    gt_param.iv_notif_date              := FND_DATE.CANONICAL_TO_DATE(iv_notif_date) ;
    gt_param.iv_notif_time_from         := iv_notif_time_from ;       --  08 : 確定通知実施時間From
    gt_param.iv_notif_time_to           := iv_notif_time_to ;         --  09 : 確定通知実施時間To
    gt_param.iv_freight_carrier_code    := iv_freight_carrier_code ;  --  10 : 運送業者
    gt_param.iv_block1                  := iv_block1 ;                --  11 : ブロック1
    gt_param.iv_block2                  := iv_block2 ;                --  12 : ブロック2
    gt_param.iv_block3                  := iv_block3 ;                --  13 : ブロック3
    gt_param.iv_shipped_locat_code      := iv_shipped_locat_code ;    --  14 : 出庫元
    gt_param.iv_mov_num                 := iv_mov_num ;               --  15 : 依頼No/移動No
    --  16 : 締め実施日
    gt_param.iv_shime_date              := FND_DATE.CANONICAL_TO_DATE(iv_shime_date) ;
    gt_param.iv_shime_time_from         := iv_shime_time_from ;       --  17 : 締め実施時間From
    gt_param.iv_shime_time_to           := iv_shime_time_to ;         --  18 : 締め実施時間To
    gt_param.iv_online_kbn              := iv_online_kbn ;            --  19 : オンライン対象区分
    gt_param.iv_item_kbn                := iv_item_kbn ;              --  20 : 品目区分
    gt_param.iv_shukko_keitai           := iv_shukko_keitai ;         --  21 : 出庫形態
    gt_param.iv_unsou_irai_inzi_kbn     := iv_unsou_irai_inzi_kbn ;   --  22 : 運送依頼元印字区分
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      ov_errbuf    => lv_errbuf       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode      -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part|| SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part || SQLERRM ;
      retcode := gv_status_error ;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxwsh620002c;
/
