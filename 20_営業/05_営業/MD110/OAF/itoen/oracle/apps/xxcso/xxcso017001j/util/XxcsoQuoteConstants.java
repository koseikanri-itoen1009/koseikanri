/*============================================================================
* t@C¼ : XxcsoQuoteConstants
* Tvà¾   : Ìæp©ÏüÍæÊ¤ÊÅèlNX
* o[W : 1.4
*============================================================================
* C³ð
* út       Ver. SÒ       C³àe
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-11 1.0  SCSö½¼l  VKì¬
* 2009-03-24 1.1  SCS¢åã  yÛè77Îzvt@ClðÇÁ
* 2009-03-24 1.1  SCS¢åã  yT1_0138z{^§äðC³
* 2009-07-23 1.2  SCS¢åã  y0000806z}[Wz^}[W¦ÌvZÎÛÏX
* 2011-11-14 1.3  SCSKË¶aK yE_{Ò®_08312zâ®©ÏæÊÌüC@
* 2012-09-10 1.4  SCSKsG®   yE_{Ò®_09945z©ÏÌÆïû@ÌÏXÎ
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.util;

/*******************************************************************************
 * AhIFÌæp©ÏüÍæÊÌ¤ÊÅèlNX
 * @author  SCSö½¼l
 * @version 1.0
 *******************************************************************************
 */

public class XxcsoQuoteConstants 
{
  /*****************************************************************************
   * URLp[^¼
   *****************************************************************************
   */
  public static final String PARAM_QUOTE_HEADER_ID = "QuoteHeaderId";
  public static final String PARAM_TRAN_DIV        = "TranDiv";

  /*****************************************************************************
   * URLp[^:Àsæª
   *****************************************************************************
   */
  public static final String TRANDIV_UPDATE      = "UPDATE";
  public static final String TRANDIV_COPY        = "COPY";
  public static final String TRANDIV_REVISION_UP = "REVISION_UP";
  public static final String TRANDIV_FROM_SALES  = "CREATE";
  // 2012-09-10 Ver1.4 [E_{Ò®_09945] Add Start
  public static final String TRANDIV_READ_ONLY = "READ_ONLY";
  // 2012-09-10 Ver1.4 [E_{Ò®_09945] Add End

  /*****************************************************************************
   * URLp[^:ßèææÊ¼Ì
   *****************************************************************************
   */
  public static final String PARAM_MENU          = "MENU";
  public static final String PARAM_SEARCH        = "SEARCH";

  /*****************************************************************************
   * ^[p[^
   *****************************************************************************
   */
  public static final String RETURN_PARAM_URL    = "URL";
  public static final String RETURN_PARAM_MSG    = "MESSAGE";
  
  /*****************************************************************************
   * ©ÏíÊ
   *****************************************************************************
   */
  public static final String QUOTE_SALES = "1";

  /*****************************************************************************
   * ©Ïæª
   *****************************************************************************
   */
  public static final String QUOTE_DIV_USUALLY = "1";
  public static final String QUOTE_DIV_BARGAIN = "2";
/* 20090723_abe_0000806 START*/
  public static final String QUOTE_DIV_INTRO   = "3";
  public static final String QUOTE_DIV_COST    = "4";
/* 20090723_abe_0000806 END*/

  /*****************************************************************************
   * Xe[^X
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
   * ©Ïpg[Nl
   *****************************************************************************
   */
  public static final String TOKEN_VALUE_QUOTE_LINE           = "©Ï¾×";
  public static final String TOKEN_VALUE_STATUS               = "Xe[^X";
  public static final String TOKEN_VALUE_QUOTE                = "©Ïîñ";
  public static final String TOKEN_VALUE_QUOTE_NUMBER         = "©ÏÔF";
  public static final String TOKEN_VALUE_QUOTE_REV_NUMBER     = "ÅF";
  public static final String TOKEN_VALUE_PRINT                = "óü";
  public static final String TOKEN_VALUE_INVALID              = "³øÉ";
  public static final String TOKEN_VALUE_FIXATION             = "mè";
  public static final String TOKEN_VALUE_OTHER_CONTENT        = "ÁL";
// 2011-11-14 Ver1.3 [E_{Ò®_08312] Mod Start
//  public static final String TOKEN_VALUE_ACCOUNT_NUMBER       = "ÚqR[h";
  public static final String TOKEN_VALUE_ACCOUNT_NUMBER       = "ÚqiÌæjR[h";
// 2011-11-14 Ver1.3 [E_{Ò®_08312] Mod End
  public static final String TOKEN_VALUE_PUBLISH_DATE         = "­sú";
  public static final String TOKEN_VALUE_DELIV_PRICE_TAX_TYPE = "X[¿iÅæª";
  public static final String TOKEN_VALUE_STORE_PRICE_TAX_TYPE = "¬¿iÅæª";
  public static final String TOKEN_VALUE_UNIT_TYPE            = "P¿æª";
  public static final String TOKEN_VALUE_INVENTORY_ITEM_ID    = "¤iR[h";
  public static final String TOKEN_VALUE_USUALLY_DELIV_PRICE  = "ÊíX[¿i";
  public static final String TOKEN_VALUE_USUALLY_STORE_SALE_PRICE
                               = "ÊíXª¿";
  public static final String TOKEN_VALUE_THIS_TIME_DELIV_PRICE = "¡ñX[¿i";
  public static final String TOKEN_VALUE_THIS_TIME_STORE_SALE_PRICE
                               = "¡ñXª¿";
  public static final String TOKEN_VALUE_QUOTE_START_DATE     = "úÔiJnj";
  public static final String TOKEN_VALUE_QUOTE_END_DATE       = "úÔiI¹j";
  public static final String TOKEN_VALUE_LINE_ORDER           = "ÀÑ";
  public static final String TOKEN_VALUE_USUALLY              = "Êí";
// 2011-11-14 Ver1.3 [E_{Ò®_08312] Add Start
  public static final String TOKEN_VALUE_SPECIAL              = "Á";
  public static final String TOKEN_VALUE_OR                   = "Í";
// 2011-11-14 Ver1.3 [E_{Ò®_08312] Add Start
  public static final String TOKEN_VALUE_EXCULDING_USUALLY    = "ÊíÈO";
  public static final String TOKEN_VALUE_ONE_YEAR             = "1N";
  public static final String TOKEN_VALUE_THREE_MONTHS         = "3";
  public static final String TOKEN_VALUE_THIS_TIME            = "¡ñ";
  public static final String TOKEN_VALUE_QUOTE_LINE_INFO      = "©Ï¾×îñ";
  public static final String MSG_DISP_CSV                     = "CSVt@CF";
  public static final String MSG_DISP_OUT                     = "oÍ";
  public static final String TOKEN_VALUE_DELIV_PLACE          = "[üê";
  public static final String TOKEN_VALUE_PAYMENT_CONDITION    = "x¥ð";
  public static final String TOKEN_VALUE_QUOTE_SUBMIT_NAME    = "©Ïñoæ¼";
  public static final String TOKEN_VALUE_SPECIAL_NOTE         = "ÁL";
  public static final String TOKEN_VALUE_REMARKS              = "õl";
  public static final String TOKEN_VALUE_PDF_OUT
                               = "©ÏiÌæpjPDFoÍ";
  public static final String TOKEN_VALUE_START                = "N®";

  /*****************************************************************************
   * CSVt@C¼
   *****************************************************************************
   */
  public static final String CSV_NAME_DELIMITER = "_";
  public static final String CSV_EXTENSION      = ".csv";

  /*****************************************************************************
   * úl
   *****************************************************************************
   */
  public static final String DEF_DELIV_PLACE             = "MÐwèê";
  public static final String DEF_PAYMENT_CONDITION       = "î{_ñÇ¨è";
  public static final String DEF_DELIV_PRICE_TAX_TYPE    = "1";
  public static final String DEF_STORE_PRICE_TAX_TYPE    = "2";
  public static final String DEF_UNIT_TYPE               = "1";
  public static final String DEF_PRICE                   = "0";

  /* 20090324_abe_Ûè77 START*/
  /*****************************************************************************
   * vt@CIvVl
   *****************************************************************************
   */
  public static final String PERIOD_DAY    = "XXCSO1_PERIOD_DAY_017_A01";
  /* 20090324_abe_Ûè77 END*/
}