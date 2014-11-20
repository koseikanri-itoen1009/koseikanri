/*============================================================================
* ファイル名 : XxcsoSalesRegistConstants
* 概要説明   : 商談決定情報入力固定値クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-11 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.util;

/*******************************************************************************
 * アドオン：商談決定情報入力の固定値クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesRegistConstants 
{
  /*****************************************************************************
   * センタリングオブジェクト
   *****************************************************************************
   */
  public static final String[] CENTERING_OBJECTS =
  {
    "SalesClassCode"
   ,"SalesAdoptClassCode"
   ,"SalesAreaCode"
  };

  /*****************************************************************************
   * 必須インジケータオブジェクト
   *****************************************************************************
   */
  public static final String[] REQUIRED_OBJECTS =
  {
    "SalesClassCodeLayout"
   ,"SalesAdoptClassCodeLayout"
   ,"SalesAreaCodeLayout"
  };
  
  /*****************************************************************************
   * Sales商談（標準）画面へのパラメータ キー値
   *****************************************************************************
   */
  public static final String RETURN_URL_PARAM = "ASNReqFrmOpptyId";
  
  /*****************************************************************************
   * 削除可能／不可
   *****************************************************************************
   */
  public static final String DELETE_ENABLED   = "DeleteEnabled";
  public static final String DELETE_DISABLED  = "DeleteDisabled";

  /*****************************************************************************
   * 商品区分
   *****************************************************************************
   */
  public static final String SALES_CLASS_CAMP = "3";
  public static final String SALES_CLASS_CUT  = "5";

  /*****************************************************************************
   * 商談決定情報用トークン値
   *****************************************************************************
   */
  public static final String
    TOKEN_VALUE_OTHER_CONTENT          = "その他・特記事項";
  public static final String
    TOKEN_VALUE_ITEM_CODE              = "商品コード";
  public static final String
    TOKEN_VALUE_SALES_CLASS            = "商品区分";
  public static final String
    TOKEN_VALUE_SALES_ADOPT_CLASS      = "採用区分";
  public static final String
    TOKEN_VALUE_SALES_AREA             = "販売対象エリア";
  public static final String
    TOKEN_VALUE_SALES_SCHEDULE_DATE    = "予定日";
  public static final String
    TOKEN_VALUE_DELIV_PRICE            = "店納価格";
  public static final String
    TOKEN_VALUE_SALES_PRICE            = "売価";
  public static final String
    TOKEN_VALUE_QUOTATION_PRICE        = "建値";
  public static final String
    TOKEN_VALUE_INC_TAX                = "税込";
  public static final String
    TOKEN_VALUE_NOT_INC_TAX            = "税抜";
  public static final String
    TOKEN_VALUE_INTRO_TERMS            = "導入条件";
  public static final String
    TOKEN_VALUE_SALES_INFO             = "商談決定情報";
  public static final String
    TOKEN_VALUE_NOTIFY_LIST            = "通知者リスト";
  public static final String
    TOKEN_VALUE_NOTIFY_SUBJECT         = "件名";
  public static final String
    TOKEN_VALUE_NOTIFY_COMMENT         = "コメント";
  public static final String
    TOKEN_VALUE_APPROVAL_USER          = "承認者";
  public static final String
    TOKEN_VALUE_REQUEST                = "承認依頼";
}