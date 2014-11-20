/*============================================================================
* ファイル名 : XxcsoQuoteConstants
* 概要説明   : 販売先用見積入力画面共通固定値クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-11 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.util;

/*******************************************************************************
 * アドオン：販売先用見積入力画面の共通固定値クラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */

public class XxcsoQuoteConstants 
{
  /*****************************************************************************
   * URLパラメータ名
   *****************************************************************************
   */
  public static final String PARAM_QUOTE_HEADER_ID = "QuoteHeaderId";
  public static final String PARAM_TRAN_DIV        = "TranDiv";

  /*****************************************************************************
   * URLパラメータ:実行区分
   *****************************************************************************
   */
  public static final String TRANDIV_UPDATE      = "UPDATE";
  public static final String TRANDIV_COPY        = "COPY";
  public static final String TRANDIV_REVISION_UP = "REVISION_UP";
  public static final String TRANDIV_FROM_SALES  = "CREATE";

  /*****************************************************************************
   * URLパラメータ:戻り先画面名称
   *****************************************************************************
   */
  public static final String PARAM_MENU          = "MENU";
  public static final String PARAM_SEARCH        = "SEARCH";

  /*****************************************************************************
   * リターンパラメータ
   *****************************************************************************
   */
  public static final String RETURN_PARAM_URL    = "URL";
  public static final String RETURN_PARAM_MSG    = "MESSAGE";
  
  /*****************************************************************************
   * 見積種別
   *****************************************************************************
   */
  public static final String QUOTE_SALES = "1";

  /*****************************************************************************
   * 見積区分
   *****************************************************************************
   */
  public static final String QUOTE_DIV_USUALLY = "1";
  public static final String QUOTE_DIV_BARGAIN = "2";

  /*****************************************************************************
   * ステータス
   *****************************************************************************
   */
  public static final String QUOTE_INPUT      = "1";
  public static final String QUOTE_FIXATION   = "2";
  public static final String QUOTE_OLD        = "3";
  public static final String QUOTE_INVALIDITY = "4";

  /*****************************************************************************
   * 見積用トークン値
   *****************************************************************************
   */
  public static final String TOKEN_VALUE_QUOTE_LINE           = "見積明細";
  public static final String TOKEN_VALUE_STATUS               = "ステータス";
  public static final String TOKEN_VALUE_QUOTE                = "見積情報";
  public static final String TOKEN_VALUE_QUOTE_NUMBER         = "見積番号：";
  public static final String TOKEN_VALUE_QUOTE_REV_NUMBER     = "版：";
  public static final String TOKEN_VALUE_PRINT                = "印刷";
  public static final String TOKEN_VALUE_INVALID              = "無効に";
  public static final String TOKEN_VALUE_FIXATION             = "確定";
  public static final String TOKEN_VALUE_OTHER_CONTENT        = "特記事項";
  public static final String TOKEN_VALUE_ACCOUNT_NUMBER       = "顧客コード";
  public static final String TOKEN_VALUE_PUBLISH_DATE         = "発行日";
  public static final String TOKEN_VALUE_DELIV_PRICE_TAX_TYPE = "店納価格税区分";
  public static final String TOKEN_VALUE_STORE_PRICE_TAX_TYPE = "小売価格税区分";
  public static final String TOKEN_VALUE_UNIT_TYPE            = "単価区分";
  public static final String TOKEN_VALUE_INVENTORY_ITEM_ID    = "商品コード";
  public static final String TOKEN_VALUE_USUALLY_DELIV_PRICE  = "通常店納価格";
  public static final String TOKEN_VALUE_USUALLY_STORE_SALE_PRICE
                               = "通常店頭売価";
  public static final String TOKEN_VALUE_THIS_TIME_DELIV_PRICE = "今回店納価格";
  public static final String TOKEN_VALUE_THIS_TIME_STORE_SALE_PRICE
                               = "今回店頭売価";
  public static final String TOKEN_VALUE_QUOTE_START_DATE     = "期間（開始）";
  public static final String TOKEN_VALUE_QUOTE_END_DATE       = "期間（終了）";
  public static final String TOKEN_VALUE_LINE_ORDER           = "並び順";
  public static final String TOKEN_VALUE_USUALLY              = "通常";
  public static final String TOKEN_VALUE_EXCULDING_USUALLY    = "通常以外";
  public static final String TOKEN_VALUE_ONE_YEAR             = "1年";
  public static final String TOKEN_VALUE_THREE_MONTHS         = "3ヶ月";
  public static final String TOKEN_VALUE_THIS_TIME            = "今回";
  public static final String TOKEN_VALUE_QUOTE_LINE_INFO      = "見積明細情報";
  public static final String MSG_DISP_CSV                     = "CSVファイル：";
  public static final String MSG_DISP_OUT                     = "出力";
  public static final String TOKEN_VALUE_DELIV_PLACE          = "納入場所";
  public static final String TOKEN_VALUE_PAYMENT_CONDITION    = "支払条件";
  public static final String TOKEN_VALUE_QUOTE_SUBMIT_NAME    = "見積書提出先名";
  public static final String TOKEN_VALUE_SPECIAL_NOTE         = "特記事項";
  public static final String TOKEN_VALUE_REMARKS              = "備考";
  public static final String TOKEN_VALUE_PDF_OUT
                               = "見積書（販売先用）PDF出力";
  public static final String TOKEN_VALUE_START                = "起動";

  /*****************************************************************************
   * CSVファイル名
   *****************************************************************************
   */
  public static final String CSV_NAME_DELIMITER = "_";
  public static final String CSV_EXTENSION      = ".csv";

  /*****************************************************************************
   * 初期値
   *****************************************************************************
   */
  public static final String DEF_DELIV_PLACE             = "貴社指定場所";
  public static final String DEF_PAYMENT_CONDITION       = "基本契約どおり";
  public static final String DEF_DELIV_PRICE_TAX_TYPE    = "1";
  public static final String DEF_STORE_PRICE_TAX_TYPE    = "2";
  public static final String DEF_UNIT_TYPE               = "1";
  public static final String DEF_PRICE                   = "0";

}