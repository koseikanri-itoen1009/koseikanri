/*============================================================================
* �t�@�C���� : XxcsoContractRegistConstants
* �T�v����   : ���̋@�ݒu�_����o�^���ʌŒ�l�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS����_    �V�K�쐬
* 2009-02-16 1.1  SCS�������l  [CT1-008]BM�w��`�F�b�N�{�b�N�X�s���Ή�
*                                       BM�x���敪�̒ǉ�
* 2009-04-08 1.2  SCS�������l  [ST��QT1_0364]�d����d���`�F�b�N�C���Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.util;

/*******************************************************************************
 * ���̋@�ݒu�_����o�^���ʌŒ�l�N���X�B
 * @author  SCS�������l
 * @version 1.1
 *******************************************************************************
 */
public class XxcsoContractRegistConstants 
{

  /*****************************************************************************
   * �Z���^�����O�I�u�W�F�N�g
   *****************************************************************************
   */
  public static final String[] CENTERING_OBJECTS =
  {
    "InputUserLayout"
   ,"CloseDayLayout"
   ,"TransferDayLayout"
   ,"ContractPeriodLayout"
   ,"CancellationOfferLayout"
   ,"Bm1BankTransferFeeDivLayout"
   ,"Bm1BellingDetailsDivLayout"
   ,"Bm1InqueryBaseLayout"
   ,"Bm1BankNameLayout"
   ,"Bm1BranchNameLayout"
   ,"Bm1BankAccountTypeLayout"
   ,"Bm2BankTransferFeeDivLayout"
   ,"Bm2BellingDetailsDivLayout"
   ,"Bm2InqueryBaseLayout"
   ,"Bm2BankNameLayout"
   ,"Bm2BranchNameLayout"
   ,"Bm2BankAccountTypeLayout"
   ,"Bm3BankTransferFeeDivLayout"
   ,"Bm3BellingDetailsDivLayout"
   ,"Bm3InqueryBaseLayout"
   ,"Bm3BankNameLayout"
   ,"Bm3BranchNameLayout"
   ,"Bm3BankAccountTypeLayout"
   ,"OwnerChangeLayout"
   ,"PublishBaseLayout"
   ,"InstallCodeLayout"
   ,"BaseLeaderLayout"
  };


  /*****************************************************************************
   * �K�{�I�u�W�F�N�g
   *****************************************************************************
   */
  public static final String[] REQUIRED_OBJECTS =
  {
    "CloseDayLayout"
   ,"TransferDayLayout"
   ,"CancellationOfferLayout"
   ,"Bm1BankTransferFeeDivLayout"
   ,"Bm1BellingDetailsDivLayout"
   ,"Bm1InqueryBaseLayout"
   ,"Bm1BankNameLayout"
   ,"Bm1BankAccountTypeLayout"
   ,"Bm2BankTransferFeeDivLayout"
   ,"Bm2BellingDetailsDivLayout"
   ,"Bm2InqueryBaseLayout"
   ,"Bm2BankNameLayout"
   ,"Bm2BankAccountTypeLayout"
   ,"Bm3BankTransferFeeDivLayout"
   ,"Bm3BellingDetailsDivLayout"
   ,"Bm3InqueryBaseLayout"
   ,"Bm3BankNameLayout"
   ,"Bm3BankAccountTypeLayout"
   ,"PublishBaseLayout"
   ,"InstallCodeLayout"
  };

  /*****************************************************************************
   * �����敪
   *****************************************************************************
   */
  public static final String MODE_UPDATE          = "1";
  public static final String MODE_COPY            = "2";

  /*****************************************************************************
   * �_�񏑋敪
   *****************************************************************************
   */
  public static final String FORMAT_STD           = "0";
  public static final String FORMAT_OTHER         = "1";

  /*****************************************************************************
   * �X�e�[�^�X
   *****************************************************************************
   */
  public static final String STS_INPUT            = "0";
  public static final String STS_FIX              = "1";

  /*****************************************************************************
   * �U����
   *****************************************************************************
   */
  public static final String TRANSFER_DAY_20      = "20";

  /*****************************************************************************
   * �U����
   *****************************************************************************
   */
  public static final String LAST_DAY             = "30";
  public static final String NEXT_MONTH           = "50";

  /*****************************************************************************
   * �x�����׏��^�C�v
   *****************************************************************************
   */
  public static final String TRANCE_EXIST          = "1";
  public static final String TRANCE_NON_EXIST      = "2";

  /*****************************************************************************
   * �}�X�^�A�g�t���O
   *****************************************************************************
   */
  public static final String COOPERATE_NONE       = "0";

  /*****************************************************************************
   * �o�b�`�����X�e�[�^�X
   *****************************************************************************
   */
  public static final String BATCH_PROC_NORMAL    = "0";

  /*****************************************************************************
   * BM�`�F�b�N
   *****************************************************************************
   */
  public static final String DELIV_BM1            = "1";
  public static final String DELIV_BM2            = "2";
  public static final String DELIV_BM3            = "3";

  /*****************************************************************************
   * �|�b�v���X�g�����ݒ���
   *****************************************************************************
   */
  public static final String INIT_FORMAT          = FORMAT_STD;
  public static final String INIT_STS             = STS_INPUT;
  public static final String INIT_TRANSFER_MONTH  = NEXT_MONTH;
  public static final String INIT_TRANSFER_DAY    = "20";
  public static final String INIT_CLOSE_DAY       = LAST_DAY;
  public static final String INIT_CANCELLATION    = "1";

  /*****************************************************************************
   * BM�w��`�F�b�N�t���O
   *****************************************************************************
   */
  public static final String BM_EXIST_FLAG_ON     = "Y";
  public static final String BM_EXIST_FLAG_OFF    = "N";

  /*****************************************************************************
   * �I�[�i�[�ύX�`�F�b�N�t���O
   *****************************************************************************
   */
  public static final String OWNER_CHANGE_FLAG_ON     = "Y";
  public static final String OWNER_CHANGE_FLAG_OFF    = "N";

  /*****************************************************************************
   * ��ʃZ�L�����e�B����t���O
   *****************************************************************************
   */
  public static final String AUTH_NONE                = "0";
  public static final String AUTH_ACCOUNT             = "1";
  public static final String AUTH_BASE_LEADER         = "2";

  /*****************************************************************************
   * �}�b�v�p�����[�^
   *****************************************************************************
   */
  public static final String PARAM_URL_PARAM          = "URL_PARAM";
  public static final String PARAM_MESSAGE            = "MESSAGE";

  /*****************************************************************************
   * BM�x���敪
   *****************************************************************************
   */
  public static final String BM_PAYMENT_TYPE5         = "5";

// 2009-04-08 [ST��QT1_0364] Add Start
  /*****************************************************************************
   * �I�y���[�V�������[�h�i�����{�^���j
   *****************************************************************************
   */
  public static final String OPERATION_APPLY  = "APPLY";
  public static final String OPERATION_SUBMIT = "SUBMIT";
// 2009-04-08 [ST��QT1_0364] Add End

  /*****************************************************************************
   * �g�[�N���l
   *****************************************************************************
   */
  // ���[�W������
  public static final String
    TOKEN_VALUE_CONTRACT_INFO           = "�_��ҁi�b�j���";
  public static final String
    TOKEN_VALUE_PAYCOND_INFO            = "�U�����E���ߓ����";
  public static final String
    TOKEN_VALUE_PERIOD_INFO             = "�_����ԁE�r���������";
  public static final String
    TOKEN_VALUE_BM1_DEST                = "�a�l�P�w����";
  public static final String
    TOKEN_VALUE_BM2_DEST                = "�a�l�Q�w����";
  public static final String
    TOKEN_VALUE_BM3_DEST                = "�a�l�R�w����";
  public static final String
    TOKEN_VALUE_INSTALL_INFO            = "�ݒu����";
  public static final String
    TOKEN_VALUE_PUBLISH_BASE_INFO       = "���s���������";

  // ���ږ�
  // �_��ҁi�b�j��񃊁[�W����
  public static final String
    TOKEN_VALUE_CONTRACT_NAME           = "�_��Җ�";
  public static final String
    TOKEN_VALUE_DELEGATE_NAME           = "��\�Җ�";
  public static final String
    TOKEN_VALUE_CONTRACT_POST_CODE      = "�_��ҏZ���i�X�֔ԍ��j";
  public static final String
    TOKEN_VALUE_CONTRACT_PREFECTURES    = "�_��ҏZ���i�s���{���j";
  public static final String
    TOKEN_VALUE_CONTRACT_CITY_WARD      = "�_��ҏZ���i�s�E��j";
  public static final String
    TOKEN_VALUE_CONTRACT_ADDRESS_1      = "�_��ҏZ���i�Z���P�j";
  public static final String
    TOKEN_VALUE_CONTRACT_ADDRESS_2      = "�_��ҏZ���i�Z���Q�j";
  public static final String
    TOKEN_VALUE_CONTRACT_EFFECT_DATE    = "�_�񏑔�����";

  // �U�����E���ߓ���񃊁[�W����
  public static final String
    TOKEN_VALUE_CLOSE_DAY_CODE          = "���ߓ�";
  public static final String
    TOKEN_VALUE_TRANSFER_MONTH_CODE     = "�U����";
  public static final String
    TOKEN_VALUE_TRANSFER_DAY_CODE       = "�U����";

  // �_����ԁE�r���������
  public static final String
    TOKEN_VALUE_CANCELLATION_OFFER_CODE = "�_������\�o";

  // �a�l�w����
  public static final String
    TOKEN_VALUE_BM1                     = "�a�l�P";
  public static final String
    TOKEN_VALUE_BM2                     = "�a�l�Q";
  public static final String
    TOKEN_VALUE_BM3                     = "�a�l�R";

  public static final String
    TOKEN_VALUE_DELIVERY_CODE           = "���t��R�[�h";
  public static final String
    TOKEN_VALUE_BANK_TRANSFER_FEE_CHARGE_DIV = "�U���萔�����S";
  public static final String
    TOKEN_VALUE_BELLING_DETAILS_DIV     = "�x�����@�A���׏�";
  public static final String
    TOKEN_VALUE_INQUERY_CHARGE_HUB_CD   = "�⍇���S�����_";
  public static final String
    TOKEN_VALUE_PAYMENT_NAME            = "���t�於";
  public static final String
    TOKEN_VALUE_PAYMENT_NAME_ALT        = "���t�於�J�i";
  public static final String
    TOKEN_VALUE_POST_CODE               = "���t��Z���i�X�֔ԍ��j";
  public static final String
    TOKEN_VALUE_PREFECTURES             = "���t��Z���i�s���{���j";
  public static final String
    TOKEN_VALUE_CITY_WARD               = "���t��Z���i�s�E��j";
  public static final String
    TOKEN_VALUE_ADDRESS_1               = "���t��Z���i�Z���P�j";
  public static final String
    TOKEN_VALUE_ADDRESS_2               = "���t��Z���i�Z���Q�j";
  public static final String
    TOKEN_VALUE_ADDRESS_LINES_PHONETIC  = "���t��d�b�ԍ�";
  public static final String
    TOKEN_VALUE_BANK_NUMBER             = "���Z�@�֖�";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_TYPE       = "�������";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_NUMBER     = "�����ԍ�";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_NAME_KANA  = "�������`�J�i";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_NAME_KANJI = "�������`����";

  // �ݒu����
  public static final String
    TOKEN_VALUE_INSTALL_PARTY_NAME      = "�ݒu�於";
  public static final String
    TOKEN_VALUE_INSTALL_POSTAL_CODE     = "�ݒu��Z���i�X�֔ԍ��j";
  public static final String
    TOKEN_VALUE_INSTALL_STATE           = "�ݒu��Z���i�s���{���j";
  public static final String
    TOKEN_VALUE_INSTALL_CITY            = "�ݒu��Z���i�s�E��j";
  public static final String
    TOKEN_VALUE_INSTALL_ADDRESS1        = "�ݒu��Z���i�Z���P�j";
  public static final String
    TOKEN_VALUE_INSTALL_ADDRESS2        = "�ݒu��Z���i�Z���Q�j";
  public static final String
    TOKEN_VALUE_INSTALL_DATE            = "�ݒu��";
  public static final String
    TOKEN_VALUE_INSTALL_CODE            = "�����R�[�h";

  // ���s���������
  public static final String
    TOKEN_VALUE_PUBLISH_DEPT_CODE       = "�S�����_";

  // �`�F�b�N�G���[���b�Z�[�W�t������
  public static final String
    TOKEN_VALUE_DOUBLE_BYTE_KANA_CHK    = "�S�p�J�i�`�F�b�N";
  public static final String
    TOKEN_VALUE_TEL_FORMAT_CHK          = "�d�b�ԍ������`�F�b�N";
  public static final String
    TOKEN_VALUE_DUPLICATE_VENDOR_NAME_CHK = "�d���於�d���`�F�b�N";
  public static final String
    TOKEN_VALUE_AR_GL_PERIOD_STATUS     = "AR��v���ԃN���[�Y�`�F�b�N";
  public static final String
    TOKEN_VALUE_BM_VENDOR_NAME          = "�a�l�P���t�於�`�a�l�R���t�於";

  // PDF�o�͎��t������
  public static final String
    TOKEN_VALUE_PDF_OUT                 = "PDF�o��";
  public static final String
    TOKEN_VALUE_START                   = "�N��";

}