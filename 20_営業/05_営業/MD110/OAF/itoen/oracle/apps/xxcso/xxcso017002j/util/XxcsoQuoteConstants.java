/*============================================================================
* ファイル名 : XxcsoQuoteConstants
* 概要説明   : 帳合問屋用見積入力画面共通固定値クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS及川領  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.util;
/*******************************************************************************
 * アドオン：帳合問屋用見積入力画面の共通固定値クラス
 * @author  SCS及川領
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
  public static final String TRANDIV_CREATE      = "CREATE";

  /*****************************************************************************
   * URLパラメータ:戻り先画面名称
   *****************************************************************************
   */
  public static final String PARAM_MENU          = "MENU";
  public static final String PARAM_SEARCH        = "SEARCH";
  public static final String PARAM_SALES         = "SALES";

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
  public static final String QUOTE_STORE = "2";

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
  public static final String TOKEN_VALUE_REFERENCE_QUOTE_NUMBER
                                                              = "参照用見積番号";
  public static final String TOKEN_VALUE_PUBLISH_DATE         = "発行日";
  public static final String TOKEN_VALUE_DELIV_PRICE_TAX_TYPE = "店納価格税区分";
  public static final String TOKEN_VALUE_UNIT_TYPE            = "単価区分";
  public static final String TOKEN_VALUE_USUALLY_DELIV_PRICE  = "通常店納価格";
  public static final String TOKEN_VALUE_THIS_TIME_DELIV_PRICE = "今回店納価格";
  public static final String TOKEN_VALUE_QUOTATION_PRICE      = "建値";
  public static final String TOKEN_VALUE_SALES_DISCOUNT_PRICE = "売上値引";
  public static final String TOKEN_VALUE_USUALL_NET_PRICE     = "通常NET価格";
  public static final String TOKEN_VALUE_THIS_TIME_NET_PRICE  = "今回NET価格";
  public static final String TOKEN_VALUE_AMOUNT_OF_MARGIN     = "マージン額";
  public static final String TOKEN_VALUE_MARGIN_RATE          = "マージン率";
  public static final String TOKEN_VALUE_QUOTE_START_DATE     = "期間（開始）";
  public static final String TOKEN_VALUE_QUOTE_END_DATE       = "期間（終了）";
  public static final String TOKEN_VALUE_LINE_ORDER           = "並び順";
  public static final String TOKEN_VALUE_USUALLY              = "通常";
  public static final String TOKEN_VALUE_EXCULDING_USUALLY    = "通常以外";
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
                               = "見積書（帳合問屋用）PDF出力";
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
  public static final String DEF_UNIT_TYPE               = "2";
  public static final String DEF_PRICE                   = "0";
  public static final String DEF_RATE                    = "100";

  /*****************************************************************************
   * ファンクション返値
   *****************************************************************************
   */
  public static final String RETURN_ERR    = "1";

  /*****************************************************************************
   * マージン率
   *****************************************************************************
   */
  public static final String RATE_MIN        = "-99.99";
  public static final String RATE_MAX        = "99.99";
  public static final String RATE_LIMIT_MIN  = "-100";
  public static final String RATE_LIMIT_MAX  = "100";
}