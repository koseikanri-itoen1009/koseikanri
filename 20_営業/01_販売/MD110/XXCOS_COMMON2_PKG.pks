CREATE OR REPLACE PACKAGE XXCOS_COMMON2_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : XXCOS_COMMON2_PKG(spec)
 * Description            : 
 * MD.070                 : MD070_IPO_COS_共通関数
 * Version                : 1.1
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
 *  get_deliv_slip_flag             F           納品書発行フラグ取得関数
 *  get_deliv_slip_flag_area        F           納品書発行フラグ全体取得関数
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/11/27    1.0  SCS              新規作成
 *  2009/02/24    1.1  H.Fujimoto       結合不具合No.129
 *  2009/03/11    1.2  K.Kumamoto       I_E_048(百貨店送り状)単体テスト障害対応 (SPEC修正)
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
  TYPE g_layout_ttype        IS TABLE OF varchar2(1000)   INDEX BY VARCHAR2(100);
  --
  --レイアウト区分定義
  gv_layout_class_order                       CONSTANT VARCHAR2(1) := '0';    --受注系
  gv_layout_class_stock                       CONSTANT VARCHAR2(1) := '1';    --在庫
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
END XXCOS_COMMON2_PKG;
/
