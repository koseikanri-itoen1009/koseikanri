/*============================================================================
* ファイル名 : XxcsoQuoteConstants
* 概要説明   : 販売先用見積入力画面共通固定値クラス
* バージョン : 1.3
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-11 1.0  SCS柳平直人  新規作成
* 2009-03-24 1.1  SCS阿部大輔  【課題77対応】プロファイル値を追加
* 2009-03-24 1.1  SCS阿部大輔  【T1_0138】ボタン制御を修正
* 2009-07-23 1.2  SCS阿部大輔  【0000806】マージン額／マージン率の計算対象変更
* 2011-11-14 1.3  SCSK桐生和幸 【E_本稼動_08312】問屋見積画面の改修①
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
/* 20090723_abe_0000806 START*/
  public static final String QUOTE_DIV_INTRO   = "3";
  public static final String QUOTE_DIV_COST    = "4";
/* 20090723_abe_0000806 END*/

  /*****************************************************************************
   * ステータス
   *****************************************************************************
   */
  /* 20090324_abe_T1_0138 START*/
  public static final String QUOTE_INIT       = "0";
  /* 20090324_abe_T1_0138 END*/
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
// 2011-11-14 Ver1.3 [E_本稼動_08312] Mod Start
//  public static final String TOKEN_VALUE_ACCOUNT_NUMBER       = "顧客コード";
  public static final String TOKEN_VALUE_ACCOUNT_NUMBER       = "顧客（販売先）コード";
// 2011-11-14 Ver1.3 [E_本稼動_08312] Mod End
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
// 2011-11-14 Ver1.3 [E_本稼動_08312] Add Start
  public static final String TOKEN_VALUE_SPECIAL              = "特売";
  public static final String TOKEN_VALUE_OR                   = "又は";
// 2011-11-14 Ver1.3 [E_本稼動_08312] Add Start
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

  /* 20090324_abe_課題77 START*/
  /*****************************************************************************
   * プロファイルオプション値
   *****************************************************************************
   */
  public static final String PERIOD_DAY    = "XXCSO1_PERIOD_DAY_017_A01";
  /* 20090324_abe_課題77 END*/
}