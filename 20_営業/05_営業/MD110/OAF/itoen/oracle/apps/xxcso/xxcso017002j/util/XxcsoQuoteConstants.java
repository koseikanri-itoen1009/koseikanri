/*============================================================================
* �t�@�C���� : XxcsoQuoteConstants
* �T�v����   : �����≮�p���ϓ��͉�ʋ��ʌŒ�l�N���X
* �o�[�W���� : 1.3
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS�y���  �V�K�쐬
* 2009-03-24 1.1  SCS�������  �y�ۑ�77�Ή��z�v���t�@�C���l��ǉ�
* 2009-03-24 1.1  SCS�������  �yT1_0138�z�{�^��������C��
* 2009-06-16 1.2  SCS�������  �yT1_1257�z�}�[�W���z�̕ύX�C��
* 2009-07-23 1.3  SCS�������  �y0000806�z�}�[�W���z�^�}�[�W�����̌v�Z�ΏەύX
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.util;
/*******************************************************************************
 * �A�h�I���F�����≮�p���ϓ��͉�ʂ̋��ʌŒ�l�N���X
 * @author  SCS�y���
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
  public static final String TRANDIV_CREATE      = "CREATE";

  /*****************************************************************************
   * URL�p�����[�^:�߂���ʖ���
   *****************************************************************************
   */
  public static final String PARAM_MENU          = "MENU";
  public static final String PARAM_SEARCH        = "SEARCH";
  public static final String PARAM_SALES         = "SALES";

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
  public static final String QUOTE_STORE = "2";

  /*****************************************************************************
   * ���ϋ敪
   *****************************************************************************
   */
  public static final String QUOTE_DIV_USUALLY = "1";
  public static final String QUOTE_DIV_BARGAIN = "2";
/* 20090723_abe_0000806 START*/
  public static final String QUOTE_DIV_INTRO   = "3";
  public static final String QUOTE_DIV_COST    = "4";
/* 20090723_abe_0000806 END*/

  /*****************************************************************************
   * �X�e�[�^�X
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
  public static final String TOKEN_VALUE_REFERENCE_QUOTE_NUMBER
                                                              = "�Q�Ɨp���ϔԍ�";
  public static final String TOKEN_VALUE_PUBLISH_DATE         = "���s��";
  public static final String TOKEN_VALUE_DELIV_PRICE_TAX_TYPE = "�X�[���i�ŋ敪";
  public static final String TOKEN_VALUE_UNIT_TYPE            = "�P���敪";
  public static final String TOKEN_VALUE_USUALLY_DELIV_PRICE  = "�ʏ�X�[���i";
  public static final String TOKEN_VALUE_THIS_TIME_DELIV_PRICE = "����X�[���i";
  public static final String TOKEN_VALUE_QUOTATION_PRICE      = "���l";
  public static final String TOKEN_VALUE_SALES_DISCOUNT_PRICE = "����l��";
  public static final String TOKEN_VALUE_USUALL_NET_PRICE     = "�ʏ�NET���i";
  public static final String TOKEN_VALUE_THIS_TIME_NET_PRICE  = "����NET���i";
  public static final String TOKEN_VALUE_AMOUNT_OF_MARGIN     = "�}�[�W���z";
  public static final String TOKEN_VALUE_MARGIN_RATE          = "�}�[�W����";
  public static final String TOKEN_VALUE_QUOTE_START_DATE     = "���ԁi�J�n�j";
  public static final String TOKEN_VALUE_QUOTE_END_DATE       = "���ԁi�I���j";
  public static final String TOKEN_VALUE_LINE_ORDER           = "���я�";
  public static final String TOKEN_VALUE_USUALLY              = "�ʏ�";
  public static final String TOKEN_VALUE_EXCULDING_USUALLY    = "�ʏ�ȊO";
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
                               = "���Ϗ��i�����≮�p�jPDF�o��";
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
  /* 20090616_abe_T1_1257 START*/
  //public static final String DEF_UNIT_TYPE               = "2";
  public static final String DEF_UNIT_TYPE               = "1";
  public static final String DEF_UNIT_TYPE1              = "1";
  public static final String DEF_UNIT_TYPE2              = "2";
  public static final String DEF_UNIT_TYPE3              = "3";
  /* 20090616_abe_T1_1257 END*/
  public static final String DEF_PRICE                   = "0";
  public static final String DEF_RATE                    = "100";

  /*****************************************************************************
   * �t�@���N�V�����Ԓl
   *****************************************************************************
   */
  public static final String RETURN_ERR    = "1";

  /*****************************************************************************
   * �}�[�W����
   *****************************************************************************
   */
  public static final String RATE_MIN        = "-99.99";
  public static final String RATE_MAX        = "99.99";
  public static final String RATE_LIMIT_MIN  = "-100";
  public static final String RATE_LIMIT_MAX  = "100";
  /* 20090324_abe_�ۑ�77 START*/
  /*****************************************************************************
   * �v���t�@�C���I�v�V�����l
   *****************************************************************************
   */
  public static final String PERIOD_DAY    = "XXCSO1_PERIOD_DAY_017_A01";
  /* 20090324_abe_�ۑ�77 END*/
}