/*============================================================================
* �t�@�C���� : XxcsoQuoteConstants
* �T�v����   : �̔���p���ϓ��͉�ʋ��ʌŒ�l�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-11 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.util;

/*******************************************************************************
 * �A�h�I���F�̔���p���ϓ��͉�ʂ̋��ʌŒ�l�N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */

public class XxcsoQuoteConstants 
{
  /*****************************************************************************
   * URL�p�����[�^��
   *****************************************************************************
   */
  public static final String PARAM_QUOTE_HEADER_ID = "QuoteHeaderId";
  public static final String PARAM_TRAN_DIV        = "TranDiv";

  /*****************************************************************************
   * URL�p�����[�^:���s�敪
   *****************************************************************************
   */
  public static final String TRANDIV_UPDATE      = "UPDATE";
  public static final String TRANDIV_COPY        = "COPY";
  public static final String TRANDIV_REVISION_UP = "REVISION_UP";
  public static final String TRANDIV_FROM_SALES  = "CREATE";

  /*****************************************************************************
   * URL�p�����[�^:�߂���ʖ���
   *****************************************************************************
   */
  public static final String PARAM_MENU          = "MENU";
  public static final String PARAM_SEARCH        = "SEARCH";

  /*****************************************************************************
   * ���^�[���p�����[�^
   *****************************************************************************
   */
  public static final String RETURN_PARAM_URL    = "URL";
  public static final String RETURN_PARAM_MSG    = "MESSAGE";
  
  /*****************************************************************************
   * ���ώ��
   *****************************************************************************
   */
  public static final String QUOTE_SALES = "1";

  /*****************************************************************************
   * ���ϋ敪
   *****************************************************************************
   */
  public static final String QUOTE_DIV_USUALLY = "1";
  public static final String QUOTE_DIV_BARGAIN = "2";

  /*****************************************************************************
   * �X�e�[�^�X
   *****************************************************************************
   */
  public static final String QUOTE_INPUT      = "1";
  public static final String QUOTE_FIXATION   = "2";
  public static final String QUOTE_OLD        = "3";
  public static final String QUOTE_INVALIDITY = "4";

  /*****************************************************************************
   * ���ϗp�g�[�N���l
   *****************************************************************************
   */
  public static final String TOKEN_VALUE_QUOTE_LINE           = "���ϖ���";
  public static final String TOKEN_VALUE_STATUS               = "�X�e�[�^�X";
  public static final String TOKEN_VALUE_QUOTE                = "���Ϗ��";
  public static final String TOKEN_VALUE_QUOTE_NUMBER         = "���ϔԍ��F";
  public static final String TOKEN_VALUE_QUOTE_REV_NUMBER     = "�ŁF";
  public static final String TOKEN_VALUE_PRINT                = "���";
  public static final String TOKEN_VALUE_INVALID              = "������";
  public static final String TOKEN_VALUE_FIXATION             = "�m��";
  public static final String TOKEN_VALUE_OTHER_CONTENT        = "���L����";
  public static final String TOKEN_VALUE_ACCOUNT_NUMBER       = "�ڋq�R�[�h";
  public static final String TOKEN_VALUE_PUBLISH_DATE         = "���s��";
  public static final String TOKEN_VALUE_DELIV_PRICE_TAX_TYPE = "�X�[���i�ŋ敪";
  public static final String TOKEN_VALUE_STORE_PRICE_TAX_TYPE = "�������i�ŋ敪";
  public static final String TOKEN_VALUE_UNIT_TYPE            = "�P���敪";
  public static final String TOKEN_VALUE_INVENTORY_ITEM_ID    = "���i�R�[�h";
  public static final String TOKEN_VALUE_USUALLY_DELIV_PRICE  = "�ʏ�X�[���i";
  public static final String TOKEN_VALUE_USUALLY_STORE_SALE_PRICE
                               = "�ʏ�X������";
  public static final String TOKEN_VALUE_THIS_TIME_DELIV_PRICE = "����X�[���i";
  public static final String TOKEN_VALUE_THIS_TIME_STORE_SALE_PRICE
                               = "����X������";
  public static final String TOKEN_VALUE_QUOTE_START_DATE     = "���ԁi�J�n�j";
  public static final String TOKEN_VALUE_QUOTE_END_DATE       = "���ԁi�I���j";
  public static final String TOKEN_VALUE_LINE_ORDER           = "���я�";
  public static final String TOKEN_VALUE_USUALLY              = "�ʏ�";
  public static final String TOKEN_VALUE_EXCULDING_USUALLY    = "�ʏ�ȊO";
  public static final String TOKEN_VALUE_ONE_YEAR             = "1�N";
  public static final String TOKEN_VALUE_THREE_MONTHS         = "3����";
  public static final String TOKEN_VALUE_THIS_TIME            = "����";
  public static final String TOKEN_VALUE_QUOTE_LINE_INFO      = "���ϖ��׏��";
  public static final String MSG_DISP_CSV                     = "CSV�t�@�C���F";
  public static final String MSG_DISP_OUT                     = "�o��";
  public static final String TOKEN_VALUE_DELIV_PLACE          = "�[���ꏊ";
  public static final String TOKEN_VALUE_PAYMENT_CONDITION    = "�x������";
  public static final String TOKEN_VALUE_QUOTE_SUBMIT_NAME    = "���Ϗ���o�於";
  public static final String TOKEN_VALUE_SPECIAL_NOTE         = "���L����";
  public static final String TOKEN_VALUE_REMARKS              = "���l";
  public static final String TOKEN_VALUE_PDF_OUT
                               = "���Ϗ��i�̔���p�jPDF�o��";
  public static final String TOKEN_VALUE_START                = "�N��";

  /*****************************************************************************
   * CSV�t�@�C����
   *****************************************************************************
   */
  public static final String CSV_NAME_DELIMITER = "_";
  public static final String CSV_EXTENSION      = ".csv";

  /*****************************************************************************
   * �����l
   *****************************************************************************
   */
  public static final String DEF_DELIV_PLACE             = "�M�Ўw��ꏊ";
  public static final String DEF_PAYMENT_CONDITION       = "��{�_��ǂ���";
  public static final String DEF_DELIV_PRICE_TAX_TYPE    = "1";
  public static final String DEF_STORE_PRICE_TAX_TYPE    = "2";
  public static final String DEF_UNIT_TYPE               = "1";
  public static final String DEF_PRICE                   = "0";

}