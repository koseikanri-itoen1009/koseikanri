/*============================================================================
* �t�@�C���� : XxcsoSpDecisionConstants
* �T�v����   : SP�ꌈ�Œ�l�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-17 1.0  SCS����_    �V�K�쐬
* 2009-03-23 1.1  SCS�������l  [ST��QT1_0163]�ۑ�No.115��荞��
* 2009-04-20 1.2  SCS�������l  [ST��QT1_0302]�ԋp�{�^��������\���s���Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.util;

/*******************************************************************************
 * �A�h�I���FSP�ꌈ�̌Œ�l�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionConstants 
{
  /*****************************************************************************
   * �Z���^�����O�I�u�W�F�N�g
   *****************************************************************************
   */
  public static final String[] CENTERING_OBJECTS =
  {
    "ApplyBaseTermLayout"
   ,"ApplyUserTermLayout"
   ,"ApplyDateTermLayout"
   ,"StatusTermLayout"
   ,"SpDecisionNumberTermLayout"
   ,"AccountTermLayout"
   ,"ApplyUserLayout"
   ,"InstallPostalCodeLayout"
   ,"BizCondTypeLayout"
   ,"BusinessTypeLayout"
   ,"InstallLocationLayout"
   ,"PublishBaseLayout"
   ,"ContractPostalCodeLayout"
   ,"VdInfo1Layout"
   ,"VdInfo2Layout"
   ,"VdInfo3Layout"
   ,"VdInfo3RequiredLayout"
   ,"Bm1PostalCodeLayout"
   ,"Bm1TransferTypeLayout"
   ,"Bm1PaymentTypeLayout"
   ,"Bm1InquiryBaseLayout"
   ,"Bm2PostalCodeLayout"
   ,"Bm2TransferTypeLayout"
   ,"Bm2PaymentTypeLayout"
   ,"Bm2InquiryBaseLayout"
   ,"CntrPostalCodeLayout"
   ,"CntrTransferTypeLayout"
   ,"CntrPaymentTypeLayout"
   ,"CntrInquiryBaseLayout"
   ,"Bm3PostalCodeLayout"
   ,"Bm3TransferTypeLayout"
   ,"Bm3PaymentTypeLayout"
   ,"Bm3InquiryBaseLayout"
   ,"SalesGrossMarginRateLayout"
   ,"BmRateLayout"
   ,"OperatingProfitRateLayout"
  };

  /*****************************************************************************
   * �K�{�I�u�W�F�N�g
   *****************************************************************************
   */
  public static final String[] REQUIRED_OBJECTS =
  {
    "InstallPostalCodeLayout"
   ,"BizCondTypeLayout"
   ,"BusinessTypeLayout"
   ,"InstallLocationLayout"
   ,"PublishBaseLayout"
   ,"ContractPostalCodeLayout"
   ,"VdInfo1Layout"
   ,"VdInfo2Layout"
   ,"VdInfo3RequiredLayout"
   ,"Bm1PostalCodeLayout"
   ,"Bm1TransferTypeLayout"
   ,"Bm1PaymentTypeLayout"
   ,"Bm2PostalCodeLayout"
   ,"Bm2TransferTypeLayout"
   ,"Bm2PaymentTypeLayout"
   ,"CntrPostalCodeLayout"
   ,"CntrTransferTypeLayout"
   ,"CntrPaymentTypeLayout"
   ,"Bm3PostalCodeLayout"
   ,"Bm3TransferTypeLayout"
   ,"Bm3PaymentTypeLayout"
   ,"BmRateLayout"
  };


  /*****************************************************************************
   * �ǎ��p�I�u�W�F�N�g
   *****************************************************************************
   */
  public static final String[] READONLY_OBJECTS =
  {
    "ConditionReasonView"
   ,"OtherContentView"
  };
  
  /*****************************************************************************
   * �����敪
   *****************************************************************************
   */
  public static final String REGIST_MODE  = "1";
  public static final String APPROVE_MODE = "2";
  
  /*****************************************************************************
   * �����敪
   *****************************************************************************
   */
  public static final String DETAIL_MODE = "1";
  public static final String COPY_MODE   = "2";

  /*****************************************************************************
   * �ڋq�敪
   *****************************************************************************
   */
  public static final String CUST_CLASS_INSTALL = "1";
  public static final String CUST_CLASS_CNTRCT  = "2";
  public static final String CUST_CLASS_BM1     = "3";
  public static final String CUST_CLASS_BM2     = "4";
  public static final String CUST_CLASS_BM3     = "5";
  
  /*****************************************************************************
   * �X�e�[�^�X
   *****************************************************************************
   */
  public static final String STATUS_INPUT   = "1";
  public static final String STATUS_APPROVE = "2";
  public static final String STATUS_ENABLE  = "3";
  public static final String STATUS_REJECT  = "4";

  /*****************************************************************************
   * �\���敪
   *****************************************************************************
   */
  public static final String APP_TYPE_NEW   = "1";
  public static final String APP_TYPE_MOD   = "2";

  /*****************************************************************************
   * �ڋq�X�e�[�^�X
   *****************************************************************************
   */
  public static final String CUST_STATUS_MC_CAND = "10";
  public static final String CUST_STATUS_MC      = "20";
  
  /*****************************************************************************
   * �Ƒԁi�����ށj
   *****************************************************************************
   */
  public static final String BIZ_COND_OFF_SET_VD = "24";
  public static final String BIZ_COND_FULL_VD    = "25";

  /*****************************************************************************
   * �V�^��
   *****************************************************************************
   */
  public static final String NEW_OLD_NEW         = "1";
  public static final String NEW_OLD_OLD         = "2";

  /*****************************************************************************
   * �K�i���^�O
   *****************************************************************************
   */
  public static final String STANDARD_TYPE_STD   = "1";
  public static final String STANDARD_TYPE_EXT   = "2";

  /*****************************************************************************
   * �������
   *****************************************************************************
   */
  public static final String COND_SALES                = "1";
  public static final String COND_SALES_CONTRIBUTE     = "2";
  public static final String COND_CNTNR                = "3";
  public static final String COND_CNTNR_CONTRIBUTE     = "4";
  public static final String COND_NON_PAY_BM           = "5";

  /*****************************************************************************
   * �S�e��敪
   *****************************************************************************
   */
  public static final String CNTNR_ALL = "1";
  public static final String CNTNR_SEL = "2";

  /*****************************************************************************
   * �d�C��敪
   *****************************************************************************
   */
// 2009-03-23 [ST��QT1_0163] Add Start
  public static final String ELEC_NONE     = "0";
// 2009-03-23 [ST��QT1_0163] Add End
  public static final String ELEC_FIXED    = "1";
  public static final String ELEC_VALIABLE = "2";
  
  /*****************************************************************************
   * ���t��
   *****************************************************************************
   */
  public static final String SEND_SAME_INSTALL = "1";
  public static final String SEND_SAME_CNTRCT  = "2";
  public static final String SEND_OTHER        = "3";

  /*****************************************************************************
   * �U���萔�����S
   *****************************************************************************
   */
  public static final String TRANSFER_CUST     = "S";

  /*****************************************************************************
   * �x�����@�E���׏�
   *****************************************************************************
   */
  public static final String PAYMENT_TYPE_NONE = "5";

  /*****************************************************************************
   * �͈�
   *****************************************************************************
   */
  public static final String RANGE_TYPE_RELATION = "1";

  /*****************************************************************************
   * ��ƈ˗��敪
   *****************************************************************************
   */
  public static final String REQ_APPROVE = "1";
  public static final String REQ_CONFIRM = "2";

  /*****************************************************************************
   * ���ُ�ԋ敪
   *****************************************************************************
   */
  public static final String APPR_NONE   = "0";
  public static final String APPR_DURING = "1";
  public static final String APPR_END    = "2";

// 2009-04-20 [ST��QT1_0302] Add Start
  /*****************************************************************************
   * ���ٓ��e
   *****************************************************************************
   */
  public static final String APPR_CONT_APPROVE = "1";
  public static final String APPR_CONT_REJECT  = "2";
  public static final String APPR_CONT_CONFIRM = "3";
  public static final String APPR_CONT_RETURN  = "4";
// 2009-04-20 [ST��QT1_0302] Add End

  /*****************************************************************************
   * �I�y���[�V�������[�h
   *****************************************************************************
   */
  public static final String OPERATION_SUBMIT  = "SUBMIT";
  public static final String OPERATION_CONFIRM = "CONFIRM";
  public static final String OPERATION_RETURN  = "RETURN";
  public static final String OPERATION_APPROVE = "APPROVE";
  public static final String OPERATION_REJECT  = "REJECT";
  
  /*****************************************************************************
   * �I�y���[�V�������[�h
   *****************************************************************************
   */
  public static final int MAX_ATTACH_FILE_NAME_LENGTH = 100;

  /*****************************************************************************
   * �����l
   *****************************************************************************
   */
  public static final String INIT_STATUS         = STATUS_INPUT;
  public static final String INIT_APP_TYPE       = APP_TYPE_NEW;
  public static final String INIT_BM1_PAY_CLASS  = PAYMENT_TYPE_NONE;
  public static final String INIT_BM2_PAY_CLASS  = PAYMENT_TYPE_NONE;
  public static final String INIT_BM3_PAY_CLASS  = PAYMENT_TYPE_NONE;
  public static final String INIT_CONSTRUCT_CHG  = "0";
  public static final String INIT_ELEC_CHG_MONTH = "0";
  public static final String INIT_RANGE_TYPE     = RANGE_TYPE_RELATION;
  public static final String INIT_APPROVE_CODE   = "*";
  
  /*****************************************************************************
   * �}�b�v�p�����[�^
   *****************************************************************************
   */
  public static final String PARAM_URL_PARAM = "URL_PARAM";
  public static final String PARAM_MESSAGE   = "MESSAGE";

  /*****************************************************************************
   * �g�[�N���l
   *****************************************************************************
   */
  public static final String
    TOKEN_VALUE_SP_DECISION           = "SP�ꌈ��";
  public static final String
    TOKEN_VALUE_SP_DEC_NUM            = "SP�ꌈ���ԍ��F";
  public static final String
    TOKEN_VALUE_SUBMIT                = "��o";
  public static final String
    TOKEN_VALUE_CONFIRM               = "�m�F";
  public static final String
    TOKEN_VALUE_RETURN                = "�ԋp";
  public static final String
    TOKEN_VALUE_APPROVE               = "���F";
  public static final String
    TOKEN_VALUE_REJECT                = "�ی�";
  public static final String
    TOKEN_VALUE_REQUEST_CONC          = "�����˗��o�^����";
  public static final String
    TOKEN_VALUE_START                 = "�N��";
  public static final String 
    TOKEN_VALUE_INST_PARTY_NAME       = "�ڋq��";
  public static final String
    TOKEN_VALUE_INST_PARTY_NAME_ALT   = "�ڋq���i�J�i�j";
  public static final String
    TOKEN_VALUE_INST_NAME             = "�ݒu�於";
  public static final String
    TOKEN_VALUE_POSTAL_CODE           = "�X�֔ԍ�";
  public static final String
    TOKEN_VALUE_STATE                 = "�s���{��";
  public static final String
    TOKEN_VALUE_CITY                  = "�s�E��";
  public static final String
    TOKEN_VALUE_ADDRESS1              = "�Z��1";
  public static final String
    TOKEN_VALUE_ADDRESS2              = "�Z��2";
  public static final String
    TOKEN_VALUE_ADDRESS_LINIE         = "�d�b�ԍ�";
  public static final String
    TOKEN_VALUE_BUSINESS_CONDITION    = "�Ƒԁi�����ށj";
  public static final String
    TOKEN_VALUE_BUSINESS_TYPE         = "�Ǝ�";
  public static final String
    TOKEN_VALUE_INSTALL_LOCATION      = "�ݒu�ꏊ";
  public static final String
    TOKEN_VALUE_EMPLOYEES             = "�Ј���";
  public static final String
    TOKEN_VALUE_PUBLISHED_BASE        = "�S�����_";
  public static final String
    TOKEN_VALUE_INSTALL_DATE          = "�ݒu��";
  public static final String
    TOKEN_VALUE_LEASE_COMP            = "���[�X������";
  public static final String 
    TOKEN_VALUE_CNTR_PARTY_NAME       = "�_��於";
  public static final String
    TOKEN_VALUE_CNTR_PARTY_NAME_ALT   = "�_��於�J�i";
  public static final String
    TOKEN_VALUE_DELEGATE              = "��\��";
  public static final String
    TOKEN_VALUE_NEW_OLD               = "�V�^��";
  public static final String
    TOKEN_VALUE_MAKER_NAME            = "���[�J�[��";
  public static final String
    TOKEN_VALUE_STD_TYPE              = "�K�i���^�O";
  public static final String
    TOKEN_VALUE_SELE_NUMBER           = "�Z����";
  public static final String
    TOKEN_VALUE_MAKER_CODE            = "���[�J�[��";
  public static final String
    TOKEN_VALUE_VENDOR_MODEL          = "�@��R�[�h";
  public static final String
    TOKEN_VALUE_COND_BIZ              = "�������";
  public static final String
    TOKEN_VALUE_FIXED_PRICE           = "�艿";
  public static final String
    TOKEN_VALUE_SALES_PRICE           = "����";
  public static final String
    TOKEN_VALUE_DISCOUNT_AMT          = "�艿����̒l���z";
  public static final String
    TOKEN_VALUE_BM1_BM_RATE           = "BM1��BM��";
  public static final String
    TOKEN_VALUE_BM2_BM_RATE           = "BM2��BM��";
  public static final String
    TOKEN_VALUE_CONTRIBUTE_BM_RATE    = "��t����BM��";
  public static final String
    TOKEN_VALUE_BM3_BM_RATE           = "BM3��BM��";
  public static final String
    TOKEN_VALUE_BM1_BM_AMT            = "BM1��BM���z";
  public static final String
    TOKEN_VALUE_BM2_BM_AMT            = "BM2��BM���z";
  public static final String
    TOKEN_VALUE_CONTRIBUTE_BM_AMT     = "��t����BM���z";
  public static final String
    TOKEN_VALUE_BM3_BM_AMT            = "BM3��BM���z";
  public static final String
    TOKEN_VALUE_CONTRACT_YEAR         = "�_��N��";
  public static final String
    TOKEN_VALUE_INST_SUP_AMT          = "����ݒu���^��";
  public static final String
    TOKEN_VALUE_INST_SUP_AMT2         = "2��ڈȍ~�ݒu���^��";
  public static final String
    TOKEN_VALUE_PAYMENT_CYCLE         = "�x���T�C�N��";
  public static final String
    TOKEN_VALUE_ELECTRICITY_AMOUNT    = "�d�C��";
  public static final String
    TOKEN_VALUE_COND_REASON           = "���ʏ����̗��R/���L����/������";
  public static final String
    TOKEN_VALUE_BM1_SEND_TYPE         = "���t��";
  public static final String 
    TOKEN_VALUE_BM_PARTY_NAME         = "���t�於";
  public static final String
    TOKEN_VALUE_BM_PARTY_NAME_ALT     = "���t�於�i�J�i�j";
  public static final String
    TOKEN_VALUE_TRANSFER              = "�U���萔�����S";
  public static final String
    TOKEN_VALUE_OTHER_CONTENT         = "���񎖍�";
  public static final String
    TOKEN_VALUE_SALES_MONTH           = "���Ԕ���";
  public static final String
    TOKEN_VALUE_BM_RATE               = "BM��";
  public static final String
    TOKEN_VALUE_LEASE_CHARGE          = "���[�X���i���z�j";
  public static final String
    TOKEN_VALUE_CONSTRUCT_CHARGE      = "�H����";
  public static final String
    TOKEN_VALUE_ELECTRICITY_AMT_MONTH = "�d�C��i���j";
  public static final String
    TOKEN_VALUE_EXCERPT               = "�E�v";
  public static final String
    TOKEN_VALUE_COMMENT               = "���كR�����g";
  public static final String
    TOKEN_VALUE_INSTALL_REGION        = "�ݒu��";
  public static final String 
    TOKEN_VALUE_CNTRCT_REGION         = "�_���";
  public static final String
    TOKEN_VALUE_BM1_REGION            = "BM1";
  public static final String
    TOKEN_VALUE_BM2_REGION            = "BM2";
  public static final String
    TOKEN_VALUE_CONTRIBUTE_REGION     = "��t��";
  public static final String
    TOKEN_VALUE_BM3_REGION            = "BM3";
  public static final String
    TOKEN_VALUE_VD_INFO_REGION        = "VD���";
  public static final String
    TOKEN_VALUE_COND_BIZ_REGION       = "�������";
  public static final String
    TOKEN_VALUE_OTHER_COND_REGION     = "���̑�����";
  public static final String
    TOKEN_VALUE_CNTRCT_CONTENT_REGION = "�_�񏑂ւ̋L�ڎ���";
  public static final String
    TOKEN_VALUE_EST_PROFIT_REGION     = "�T�Z�N�ԑ��v";
  public static final String
    TOKEN_VALUE_ATTACH_REGION         = "�Y�t";
  public static final String
    TOKEN_VALUE_SEND_REGION           = "�񑗐�";
  public static final String
    TOKEN_VALUE_DOUBLE_BYTE_KANA_CHK  = "�S�p�J�i�`�F�b�N";
  public static final String
    TOKEN_VALUE_TEL_FORMAT_CHK        = "�d�b�ԍ������`�F�b�N";
  public static final String
    TOKEN_VALUE_ATTACH_FILE_NAME      = "�Y�t�t�@�C����";
  public static final String
    TOKEN_VALUE_CALC_LINE             = "�艿���Z���v�Z";
  public static final String
    TOKEN_VALUE_APPR_AUTH_LEVEL_CHK   = "���F�������x������";
  public static final String
    TOKEN_VALUE_IB_REQUEST            = "���̋@�i�Y��j�����˗��f�[�^�A�g�@�\";
  public static final String
    TOKEN_VALUE_CONV_NUMBER_SEPARATE  = "���l�̃Z�p���[�g�ϊ�";
  public static final String
    TOKEN_VALUE_SALES_COND            = "�����ʏ���";
  public static final String
    TOKEN_VALUE_EMPLOYEE_NUMBER       = "�Ј��ԍ�";
}