CREATE OR REPLACE PACKAGE APPS.XXCOS_COMMON2_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : XXCOS_COMMON2_PKG(spec)
 * Description            : 
 * MD.070                 : MD070_IPO_COS_共通関数
 * Version                : 1.10
 *
 * Program List
 *  --------------------          ---- ----- --------------------------------------------------
 *   Name                         Type  Ret   Description
 *  --------------------          ---- ----- --------------------------------------------------
 *  get_unit_price                  F  NUMBER   単価取得関数
 *  conv_ebs_cust_code              P           顧客コード変換（EDI→EBS)
 *  conv_edi_cust_code              P           顧客コード変換（EBS→EDI)
 *  conv_ebs_item_code              P           品目コード変換（EDI→EBS)
 *  conv_edi_item_code              P           品目コード変換（EBS→EDI)
 *  get_layout_info                 P           レイアウト定義情報取得
 *  makeup_data_record              P           データレコード編集
 *  convert_quantity                P           EDI帳票向け数量換算関数
 *  get_deliv_slip_flag             F           納品書発行フラグ取得関数
 *  get_deliv_slip_flag_area        F           納品書発行フラグ全体取得関数
 *  get_salesrep_id                 P           担当営業員取得関数
 *  get_reason_code                 F           事由コード取得関数
 *  get_reason_data                 P           事由コードマスタデータ取得関数
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/11/27    1.0  SCS              新規作成
 *  2009/02/24    1.1  H.Fujimoto       結合不具合No.129
 *  2009/03/11    1.2  K.Kumamoto       I_E_048(百貨店送り状)単体テスト障害対応 (SPEC修正)
 *  2009/03/31    1.3  T.Kitajima       [T1_0026]makeup_data_recordのNUMBER,DATE編集変更
 *  2009/04/16    1.4  T.Kitajima       [T1_0543]conv_edi_item_code ケースJAN、JANコードNULL対応
 *  2009/06/23    1.5  K.Kiriu          [T1_1359]EDI帳票向け数量換算関数の追加
 *  2009/10/02    1.6  M.Sano           [0001156]顧客品目抽出条件追加
 *                                      [0001344]顧客品目検索エラー,JANコード検索エラーのパラメータ追加
 *  2010/04/15    1.7  Y.Goto           [E_本稼動_01719]担当営業員取得関数追加
 *  2010/07/12    1.8  S.Niki           [E_本稼動_02637]品目コード変換（EBS→EDI)パラメータ追加
 *  2011/04/26    1.9  K.kiriu          [E_本稼動_07182]納品予定データ作成処理遅延対応
 *                                      [E_本稼動_07218]納品予定プルーフリスト作成処理遅延対応
 *  2011/09/07    1.10 K.kiriu          [E_本稼動_07906]流通ＢＭＳ対応
 *
 *****************************************************************************************/
--
--###############################  共通エリア定義  START  ###################################
--
  --レイアウト定義情報格納用レコードタイプ
  TYPE g_record_layout IS RECORD(
               lookup_code                             VARCHAR2(4)
              ,meaning                                 VARCHAR2(30)
              ,description                             VARCHAR2(40)
              ,attribute1                              VARCHAR2(7)
              ,attribute2                              VARCHAR2(10)
              );
  --レイアウト定義情報格納用テーブルタイプ
  TYPE g_record_layout_ttype IS TABLE OF g_record_layout INDEX BY BINARY_INTEGER;
  --
  --ファイル出力情報格納用テーブルタイプ
/* 2011/09/07 Ver1.10 Mod Start */
--  TYPE g_layout_ttype        IS TABLE OF varchar2(1000)   INDEX BY VARCHAR2(100);
  TYPE g_layout_ttype        IS TABLE OF varchar2(2000)   INDEX BY VARCHAR2(100);
/* 2011/09/07 Ver1.10 MOd End   */
  --
  --レイアウト区分定義
  gv_layout_class_order                       CONSTANT VARCHAR2(1) := '0';    --受注系
  gv_layout_class_stock                       CONSTANT VARCHAR2(1) := '1';    --在庫
/* 2011/09/07 Ver1.10 Add Start */
  gv_layout_class_order2                      CONSTANT VARCHAR2(1) := '2';    --受注系(流通ＢＭＳ以外)
/* 2011/09/07 Ver1.10 Add End   */
  --ファイル形式定義
  gv_file_type_fix                            CONSTANT VARCHAR2(1) := '0';    --固定長
  gv_file_type_variable                       CONSTANT VARCHAR2(1) := '1';    --可変長
--
--###############################  共通エリア定義  E N D  ###################################
--
  /************************************************************************
   * Function Name   : get_unit_price
   * Description     : 単価取得関数
   ************************************************************************/
  FUNCTION get_unit_price(
     in_inventory_item_id      IN           NUMBER                           -- Disc品目ID
    ,in_price_list_header_id   IN           NUMBER                           -- 価格表ヘッダID
    ,iv_uom_code               IN           VARCHAR2                         -- 単位コード
  ) RETURN  NUMBER;
--
  /************************************************************************
   * Procedure Name  : conv_ebs_cust_code
   * Description     : 顧客コード変換（EDI→EBS)
   ************************************************************************/
  PROCEDURE conv_ebs_cust_code(
               iv_edi_chain_code                   IN  VARCHAR2 DEFAULT NULL  --EDIチェーン店コード
              ,iv_store_code                       IN  VARCHAR2 DEFAULT NULL  --店コード
              ,ov_account_number                   OUT NOCOPY VARCHAR2        --顧客コード
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --エラー・メッセージエラー       #固定#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --リターン・コード               #固定#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --ユーザー・エラー・メッセージ   #固定#
              );
  --
--
  /************************************************************************
   * Procedure Name  : conv_edi_item_code
   * Description     : 品目コード変換（EBS→EDI)
   ************************************************************************/
  PROCEDURE conv_edi_item_code(
               iv_edi_chain_code                   IN  VARCHAR2 DEFAULT NULL  --EDIチェーン店コード
              ,iv_item_code                        IN  VARCHAR2 DEFAULT NULL  --品目コード
              ,iv_organization_id                  IN  VARCHAR2 DEFAULT NULL  --在庫組織ID
              ,iv_uom_code                         IN  VARCHAR2 DEFAULT NULL  --単位コード
              ,ov_product_code2                    OUT NOCOPY VARCHAR2        --商品コード２
              ,ov_jan_code                         OUT NOCOPY VARCHAR2        --JANコード
              ,ov_case_jan_code                    OUT NOCOPY VARCHAR2        --ケースJANコード
/* 2010/07/12 Ver1.8 Add Start */
              ,ov_err_flag                         OUT NOCOPY VARCHAR2        --エラー種別
/* 2010/07/12 Ver1.8 Add End */
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --エラー・メッセージエラー       #固定#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --リターン・コード               #固定#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --ユーザー・エラー・メッセージ   #固定#
              );
  --
--
  --レイアウト定義情報取得
  PROCEDURE get_layout_info(
               iv_file_type                        IN  VARCHAR2 DEFAULT NULL  --ファイル形式
              ,iv_layout_class                     IN  VARCHAR2 DEFAULT NULL  --レイアウト区分
              ,ov_data_type_table                  OUT NOCOPY g_record_layout_ttype  --レイアウト定義情報
              ,ov_csv_header                       OUT NOCOPY VARCHAR2        --CSVヘッダ
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --エラー・メッセージエラー       #固定#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --リターン・コード               #固定#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --ユーザー・エラー・メッセージ   #固定#
              );
  --
--
  --データレコード編集
  PROCEDURE makeup_data_record(
               iv_edit_data                        IN  g_layout_ttype         --出力データ
              ,iv_file_type                        IN  VARCHAR2 DEFAULT NULL  --ファイル形式
              ,iv_data_type_table                  IN  g_record_layout_ttype  --編集前レコード型情報
              ,iv_record_type                      IN  VARCHAR2 DEFAULT NULL  --レコード識別子
              ,ov_data_record                      OUT NOCOPY VARCHAR2        --データレコード
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --エラー・メッセージエラー       #固定#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --リターン・コード               #固定#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --ユーザー・エラー・メッセージ   #固定#
              );
  --
--
  /************************************************************************
   * Function Name   : convert_quantity
   * Description     : EDI帳票向け数量換算関数
   ************************************************************************/
  PROCEDURE convert_quantity(
               iv_uom_code                         IN  VARCHAR2  DEFAULT NULL  --単位コード
              ,in_case_qty                         IN  NUMBER    DEFAULT NULL  --ケース入数
              ,in_ball_qty                         IN  NUMBER    DEFAULT NULL  --ボール入数
              ,in_sum_indv_order_qty               IN  NUMBER    DEFAULT NULL  --発注数量(合計・バラ)
              ,in_sum_shipping_qty                 IN  NUMBER    DEFAULT NULL  --出荷数量(合計・バラ)
              ,on_indv_shipping_qty                OUT NOCOPY NUMBER           --出荷数量(バラ)
              ,on_case_shipping_qty                OUT NOCOPY NUMBER           --出荷数量(ケース)
              ,on_ball_shipping_qty                OUT NOCOPY NUMBER           --出荷数量(ボール)
              ,on_indv_stockout_qty                OUT NOCOPY NUMBER           --欠品数量(バラ)
              ,on_case_stockout_qty                OUT NOCOPY NUMBER           --欠品数量(ケース)
              ,on_ball_stockout_qty                OUT NOCOPY NUMBER           --欠品数量(ボール)
              ,on_sum_stockout_qty                 OUT NOCOPY NUMBER           --欠品数量(合計・バラ)
              ,ov_errbuf                           OUT NOCOPY VARCHAR2         --エラー・メッセージエラー       #固定#
              ,ov_retcode                          OUT NOCOPY VARCHAR2         --リターン・コード               #固定#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2         --ユーザー・エラー・メッセージ   #固定#
  );
  --
--
  --納品書発行フラグ取得関数
  FUNCTION get_deliv_slip_flag(
               iv_publish_sequence                 IN  NUMBER   DEFAULT NULL  --納品書発行フラグ設定順番
              ,iv_publish_area                     IN  VARCHAR2 DEFAULT NULL  --納品書発行フラグエリア
           )
    RETURN VARCHAR2;
  --
--
  --納品書発行フラグ全体取得関数
  FUNCTION get_deliv_slip_flag_area(
               iv_publish_sequence                 IN  NUMBER   DEFAULT NULL  --納品書発行フラグ設定順番
              ,iv_publish_area                     IN  VARCHAR2 DEFAULT NULL  --納品書発行フラグエリア
              ,iv_publish_flag                     IN  VARCHAR2 DEFAULT NULL  --納品書発行フラグ
              )
    RETURN VARCHAR2;
  --
--
  /************************************************************************
   * Function Name   : get_salesrep_id
   * Description     : 担当営業員取得関数
   ************************************************************************/
  PROCEDURE get_salesrep_id(
               iv_account_number                   IN  VARCHAR2  DEFAULT NULL  --顧客コード
              ,id_target_date                      IN  DATE      DEFAULT NULL  --基準日
              ,in_org_id                           IN  NUMBER    DEFAULT NULL  --営業単位ID
              ,on_salesrep_id                      OUT NOCOPY NUMBER           --担当営業員ID
              ,ov_employee_number                  OUT NOCOPY VARCHAR2         --最上位者従業員番号
              ,ov_errbuf                           OUT NOCOPY VARCHAR2         --エラー・メッセージエラー       #固定#
              ,ov_retcode                          OUT NOCOPY VARCHAR2         --リターン・コード               #固定#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2         --ユーザー・エラー・メッセージ   #固定#
  );
  --
/* 2011/04/26 Ver1.9 Add Start */
  /************************************************************************
   * Function Name   : get_reason_code
   * Description     : 事由コード取得関数
   ************************************************************************/
  FUNCTION get_reason_code(
               in_line_id                          IN  NUMBER                  --受注明細ID
           )
    RETURN VARCHAR2;
  --
  /************************************************************************
   * Procedure Name  : get_reason_data
   * Description     : 事由コードマスタデータ取得関数
   ************************************************************************/
  PROCEDURE get_reason_data(
               in_line_id                          IN  NUMBER                  --受注明細ID
              ,on_reason_id                        OUT NOCOPY NUMBER           --事由コードマスタ内部ID
              ,ov_reason_code                      OUT NOCOPY VARCHAR2         --事由コード
              ,ov_select_flag                      OUT NOCOPY VARCHAR2         --選択可能フラグ
              ,ov_errbuf                           OUT NOCOPY VARCHAR2         --エラー・メッセージエラー       #固定#
              ,ov_retcode                          OUT NOCOPY VARCHAR2         --リターン・コード               #固定#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2         --ユーザー・エラー・メッセージ   #固定#
  );
/* 2011/04/26 Ver1.9 Add End   */
--
END XXCOS_COMMON2_PKG;
/
