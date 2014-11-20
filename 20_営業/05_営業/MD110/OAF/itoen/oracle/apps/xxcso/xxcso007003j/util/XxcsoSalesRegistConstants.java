/*============================================================================
* �t�@�C���� : XxcsoSalesRegistConstants
* �T�v����   : ���k��������͌Œ�l�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-11 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.util;

/*******************************************************************************
 * �A�h�I���F���k��������͂̌Œ�l�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesRegistConstants 
{
  /*****************************************************************************
   * �Z���^�����O�I�u�W�F�N�g
   *****************************************************************************
   */
  public static final String[] CENTERING_OBJECTS =
  {
    "SalesClassCode"
   ,"SalesAdoptClassCode"
   ,"SalesAreaCode"
  };

  /*****************************************************************************
   * �K�{�C���W�P�[�^�I�u�W�F�N�g
   *****************************************************************************
   */
  public static final String[] REQUIRED_OBJECTS =
  {
    "SalesClassCodeLayout"
   ,"SalesAdoptClassCodeLayout"
   ,"SalesAreaCodeLayout"
  };
  
  /*****************************************************************************
   * Sales���k�i�W���j��ʂւ̃p�����[�^ �L�[�l
   *****************************************************************************
   */
  public static final String RETURN_URL_PARAM = "ASNReqFrmOpptyId";
  
  /*****************************************************************************
   * �폜�\�^�s��
   *****************************************************************************
   */
  public static final String DELETE_ENABLED   = "DeleteEnabled";
  public static final String DELETE_DISABLED  = "DeleteDisabled";

  /*****************************************************************************
   * ���i�敪
   *****************************************************************************
   */
  public static final String SALES_CLASS_CAMP = "3";
  public static final String SALES_CLASS_CUT  = "5";

  /*****************************************************************************
   * ���k������p�g�[�N���l
   *****************************************************************************
   */
  public static final String
    TOKEN_VALUE_OTHER_CONTENT          = "���̑��E���L����";
  public static final String
    TOKEN_VALUE_ITEM_CODE              = "���i�R�[�h";
  public static final String
    TOKEN_VALUE_SALES_CLASS            = "���i�敪";
  public static final String
    TOKEN_VALUE_SALES_ADOPT_CLASS      = "�̗p�敪";
  public static final String
    TOKEN_VALUE_SALES_AREA             = "�̔��ΏۃG���A";
  public static final String
    TOKEN_VALUE_SALES_SCHEDULE_DATE    = "�\���";
  public static final String
    TOKEN_VALUE_DELIV_PRICE            = "�X�[���i";
  public static final String
    TOKEN_VALUE_SALES_PRICE            = "����";
  public static final String
    TOKEN_VALUE_QUOTATION_PRICE        = "���l";
  public static final String
    TOKEN_VALUE_INC_TAX                = "�ō�";
  public static final String
    TOKEN_VALUE_NOT_INC_TAX            = "�Ŕ�";
  public static final String
    TOKEN_VALUE_INTRO_TERMS            = "��������";
  public static final String
    TOKEN_VALUE_SALES_INFO             = "���k������";
  public static final String
    TOKEN_VALUE_NOTIFY_LIST            = "�ʒm�҃��X�g";
  public static final String
    TOKEN_VALUE_NOTIFY_SUBJECT         = "����";
  public static final String
    TOKEN_VALUE_NOTIFY_COMMENT         = "�R�����g";
  public static final String
    TOKEN_VALUE_APPROVAL_USER          = "���F��";
  public static final String
    TOKEN_VALUE_REQUEST                = "���F�˗�";
}