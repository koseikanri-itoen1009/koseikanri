/*==============================================================================
* �t�@�C���� : XxcsoContractRegistConstants
* �T�v����   : ���̋@�ݒu�_����o�^���ʌŒ�l�N���X
* �o�[�W���� : 2.7
*==============================================================================
* �C������
* ���t       Ver. �S����         �C�����e
* ---------- ---- -------------- ----------------------------------------------
* 2009-01-27 1.0  SCS����_      �V�K�쐬
* 2009-02-16 1.1  SCS�������l    [CT1-008]BM�w��`�F�b�N�{�b�N�X�s���Ή�
*                                         BM�x���敪�̒ǉ�
* 2009-04-08 1.2  SCS�������l    [ST��QT1_0364]�d����d���`�F�b�N�C���Ή�
* 2009-04-27 1.3  SCS�������l    [ST��QT1_0708]������`�F�b�N��������C��
* 2010-02-09 1.4  SCS�������    [E_�{�ғ�_01538]�_�񏑂̕����m��Ή�
* 2010-03-01 1.5  SCS�������    [E_�{�ғ�_01678]�����x���Ή�
* 2010-03-01 1.5  SCS�������    [E_�{�ғ�_01868]�����Ή�
* 2010-01-06 1.6  SCS�ː��a�K    [E_�{�ғ�_02498]��s�x�X�}�X�^�`�F�b�N�Ή�
* 2011-06-06 1.7  SCS�ː��a�K    [E_�{�ғ�_01963]�V�K�d����쐬�`�F�b�N�Ή�
* 2012-06-12 1.8  SCSK�ː��a�K   [E_�{�ғ�_09602]�_�����{�^���ǉ��Ή�
* 2013-04-01 1.9  SCSK�ː��a�K   [E_�{�ғ�_10413]��s�����}�X�^�ύX�`�F�b�N�ǉ��Ή�
* 2015-02-06 2.0  SCSK�R���đ�   [E_�{�ғ�_12565]SP�ꌈ�E�_�񏑉�ʉ��C
* 2015-11-30 2.1  SCSK�R���đ�   [E_�{�ғ�_13345]�I�[�i�ύX�}�X�^�A�g�G���[�Ή�
* 2016-01-06 2.2  SCSK�ː��a�K   [E_�{�ғ�_13456]���̋@�Ǘ��V�X�e����֑Ή�
* 2019-02-19 2.3  SCSK���X�ؑ�a [E_�{�ғ�_15349]�d����CD����Ή�
* 2020-12-14 2.4  SCSK���X�ؑ�a [E_�{�ғ�_16642]���t��R�[�h�ɕR�t�����[���A�h���X�ɂ���
* 2022-03-31 2.5  SCSK�񑺗I��   [E_�{�ғ�_18060]���̋@�ڋq�ʗ��v�Ǘ�
* 2023-06-08 2.6  SCSK�Ԓn�w     [E_�{�ғ�_19179]�C���{�C�X�Ή��iBM�֘A�j
* 2024-09-04 2.7  SCSK�Ԓn�w     [E_�{�ғ�_20174]���̋@�ڋq�x���Ǘ����̉��C
*==============================================================================
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
// 2015-02-06 [E_�{�ғ�_12565] Add Start
   ,"InstSuppBankTransferFeeDivLayout"
   ,"InstSuppBankNameLayout"
   ,"InstSuppBranchNameLayout"
   ,"InstSuppBankAccountTypeLayout"
   ,"IntroChgBankTransferFeeDivLayout"
   ,"IntroChgBankNameLayout"
   ,"IntroChgBranchNameLayout"
   ,"IntroChgBankAccountTypeLayout"
   ,"ElectricBankTransferFeeDivLayout"
   ,"ElectricBankNameLayout"
   ,"ElectricBranchNameLayout"
   ,"ElectricBankAccountTypeLayout"
// 2015-02-06 [E_�{�ғ�_12565] Add End
   ,"OwnerChangeLayout"
   ,"PublishBaseLayout"
   ,"InstallCodeLayout"
   ,"BaseLeaderLayout"
// Ver.2.6 Add Start
   ,"Bm1InvoiceTaxDivBmLayout"
   ,"Bm1InvoiceTFlagLayout"
   ,"Bm2InvoiceTaxDivBmLayout"
   ,"Bm2InvoiceTFlagLayout"
   ,"Bm3InvoiceTaxDivBmLayout"
   ,"Bm3InvoiceTFlagLayout"
// Ver.2.6 Add End
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
// 2010-03-01 [E_�{�ғ�_01678] Add Start
//   ,"Bm1BankTransferFeeDivLayout"
// 2010-03-01 [E_�{�ғ�_01678] Add End
   ,"Bm1BellingDetailsDivLayout"
// Ver.2.6 Add Start
   ,"Bm1InvoiceTaxDivBmLayout"
// Ver.2.6 Add End
   ,"Bm1InqueryBaseLayout"
// 2010-03-01 [E_�{�ғ�_01678] Add Start
//   ,"Bm1BankNameLayout"
//   ,"Bm1BankAccountTypeLayout"
//   ,"Bm2BankTransferFeeDivLayout"
// 2010-03-01 [E_�{�ғ�_01678] Add End
   ,"Bm2BellingDetailsDivLayout"
// Ver.2.6 Add Start
   ,"Bm2InvoiceTaxDivBmLayout"
// Ver.2.6 Add End
   ,"Bm2InqueryBaseLayout"
// 2010-03-01 [E_�{�ғ�_01678] Add Start
//   ,"Bm2BankNameLayout"
//   ,"Bm2BankAccountTypeLayout"
//   ,"Bm3BankTransferFeeDivLayout"
// 2010-03-01 [E_�{�ғ�_01678] Add End
   ,"Bm3BellingDetailsDivLayout"
// Ver.2.6 Add Start
   ,"Bm3InvoiceTaxDivBmLayout"
// Ver.2.6 Add End
   ,"Bm3InqueryBaseLayout"
// 2010-03-01 [E_�{�ғ�_01678] Add Start
//   ,"Bm3BankNameLayout"
//   ,"Bm3BankAccountTypeLayout"
// 2010-03-01 [E_�{�ғ�_01678] Add End
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
// 2012-06-12 [E_�{�ғ�_09602] Add Start
  public static final String STS_REJECT           = "9";
// 2012-06-12 [E_�{�ғ�_09602] Add End

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

// 2015-02-06 [E_�{�ғ�_12565] Add Start
  /*****************************************************************************
   * �ݒu���^���w��`�F�b�N�t���O
   *****************************************************************************
   */
  public static final String INST_SUPP_EXIST_FLAG_ON     = "Y";
  public static final String INST_SUPP_EXIST_FLAG_OFF    = "N";

  /*****************************************************************************
   * �Љ�萔���w��`�F�b�N�t���O
   *****************************************************************************
   */
  public static final String INTRO_CHG_EXIST_FLAG_ON     = "Y";
  public static final String INTRO_CHG_EXIST_FLAG_OFF    = "N";

  /*****************************************************************************
   * �d�C��w��`�F�b�N�t���O
   *****************************************************************************
   */
  public static final String ELECTRIC_EXIST_FLAG_ON     = "Y";
  public static final String ELECTRIC_EXIST_FLAG_OFF    = "N";
// 2015-02-06 [E_�{�ғ�_12565] Add End

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
// 2010-03-01 [E_�{�ғ�_01678] Add Start
  public static final String BM_PAYMENT_TYPE4         = "4";
// 2010-03-01 [E_�{�ғ�_01678] Add End
  public static final String BM_PAYMENT_TYPE5         = "5";

// 2015-02-06 [E_�{�ғ�_12565] Add Start
  /*****************************************************************************
   * �x���敪�i�ݒu���^���j
   *****************************************************************************
   */
  public static final String INST_SUPP_TYPE0         = "0";
  public static final String INST_SUPP_TYPE1         = "1";

/*****************************************************************************
   * �x���敪�i�Љ�萔���j
   *****************************************************************************
   */
  public static final String INTRO_CHG_TYPE0         = "0";
  public static final String INTRO_CHG_TYPE1         = "1";

/*****************************************************************************
   * �x�������i�d�C��j
   *****************************************************************************
   */
  public static final String ELECTRIC_PAYMENT_TYPE1  = "1";
  public static final String ELECTRIC_PAYMENT_TYPE2  = "2";
// 2015-02-06 [E_�{�ғ�_12565] Add End

// 2009-04-08 [ST��QT1_0364] Add Start
  /*****************************************************************************
   * �I�y���[�V�������[�h�i�����{�^���j
   *****************************************************************************
   */
  public static final String OPERATION_APPLY  = "APPLY";
  public static final String OPERATION_SUBMIT = "SUBMIT";
// 2009-04-08 [ST��QT1_0364] Add End
// 2011-06-06 Ver1.7 [E_�{�ғ�_01963] Add Start
  /*****************************************************************************
   * BM���t��V�K�쐬����
   *****************************************************************************
   */
  public static final String CREATE_VENDOR    = "CREATE";
// 2011-06-06 Ver1.7 [E_�{�ғ�_01963] Add End

// 2016-01-06 [E_�{�ғ�_13456] Add Start
  /*****************************************************************************
   * ���̋@S�A�g�t���O
   *****************************************************************************
   */
  public static final String INTERFACE_NONE       = "0";
  public static final String INTERFACE_NO_TARGET  = "9";
// 2016-01-06 [E_�{�ғ�_13456] Add End

// Ver.2.6 Add Start
  /*****************************************************************************
   * �K�i���������s���Ǝғo�^�iT�敪�j�`�F�b�N�t���O
   *****************************************************************************
   */
  public static final String INVOICE_T_FLAG_ON     = "T";
  public static final String INVOICE_T_FLAG_OFF    = null;

  /*****************************************************************************
   * ���t��R�[�h�����C�x���g
   *****************************************************************************
   */
  public static final String VENDOR_CODE_LOV_VALIDATE     = "lovValidate";
// Ver.2.6 Add End

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
// 2015-02-06 [E_�{�ғ�_12565] Add Start
  public static final String
    TOKEN_VALUE_INST_SUPP               = "�ݒu���^�����";
  public static final String
    TOKEN_VALUE_INTRO_CHG               = "�Љ�萔�����";
  public static final String
    TOKEN_VALUE_ELECTRIC                = "�d�C����";
// 2015-02-06 [E_�{�ғ�_12565] Add End
  public static final String
    TOKEN_VALUE_INSTALL_INFO            = "�ݒu����";
  public static final String
    TOKEN_VALUE_PUBLISH_BASE_INFO       = "���s���������";

  // ���ږ�
  // �_��ҁi�b�j��񃊁[�W����
  public static final String
    TOKEN_VALUE_CONTRACT_NAME           = "�_��Җ�(�S�p)";
  public static final String
    TOKEN_VALUE_DELEGATE_NAME           = "��\�Җ�(�S�p)";
  public static final String
    TOKEN_VALUE_CONTRACT_POST_CODE      = "�_��ҏZ���@�X�֔ԍ�(���p)";
  public static final String
    TOKEN_VALUE_CONTRACT_PREFECTURES    = "�_��ҏZ���@�s���{��(�S�p)";
  public static final String
    TOKEN_VALUE_CONTRACT_CITY_WARD      = "�_��ҏZ���@�s�E��(�S�p)";
  public static final String
    TOKEN_VALUE_CONTRACT_ADDRESS_1      = "�_��ҏZ���@�Z���P(�S�p)";
  public static final String
    TOKEN_VALUE_CONTRACT_ADDRESS_2      = "�_��ҏZ���@�Z���Q(�S�p)";
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
// Ver.2.6 Add Start
  public static final String
    TOKEN_VALUE_INVOICE_TAX_DIV_BM      = "����Ōv�Z�敪";
// Ver.2.6 Add End    
  public static final String
    TOKEN_VALUE_INQUERY_CHARGE_HUB_CD   = "�⍇���S�����_";
  public static final String
    TOKEN_VALUE_PAYMENT_NAME            = "���t�於(�S�p)";
  public static final String
    TOKEN_VALUE_PAYMENT_NAME_ALT        = "���t�於�J�i(���p)";
  public static final String
    TOKEN_VALUE_POST_CODE               = "���t��Z���@�X�֔ԍ�(0000000)";
  public static final String
    TOKEN_VALUE_PREFECTURES             = "���t��Z���@�s���{��(�S�p)";
  public static final String
    TOKEN_VALUE_CITY_WARD               = "���t��Z���@�s�E��(�S�p)";
  public static final String
    TOKEN_VALUE_ADDRESS_1               = "���t��Z���@�Z���P(�S�p)";
  public static final String
    TOKEN_VALUE_ADDRESS_2               = "���t��Z���@�Z���Q(�S�p)";
  public static final String
    TOKEN_VALUE_ADDRESS_LINES_PHONETIC  = "���t��d�b�ԍ�(00-0000-0000)";
// [E_�{�ғ�_16642] Add Start
  public static final String
    TOKEN_VALUE_EMAIL_ADDRESS           = "���t�惁�[���A�h���X(xxx@xxx)";
// [E_�{�ғ�_16642] Add End
// Ver.2.6 Add Start
  public static final String
    TOKEN_VALUE_INVOICE_T_FLAG          = "�C���{�C�X�ԍ��o�^�ρiT�L�j";
  public static final String
    TOKEN_VALUE_INVOICE_T_NO            = "�@�l�ԍ�";
// Ver.2.6 Add End
  public static final String
    TOKEN_VALUE_BANK_NUMBER             = "���Z�@�֖�";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_TYPE       = "�������";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_NUMBER     = "�����ԍ�(���p)";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_NAME_KANA  = "�������`�J�i(���p)";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_NAME_KANJI = "�������`����(�S�p)";

  // �ݒu����
  public static final String
    TOKEN_VALUE_INSTALL_PARTY_NAME      = "�ݒu�於(�S�p)";
  public static final String
    TOKEN_VALUE_INSTALL_POSTAL_CODE     = "�ݒu��Z���@�X�֔ԍ�(0000000)";
  public static final String
    TOKEN_VALUE_INSTALL_STATE           = "�ݒu��Z���@�s���{��(�S�p)";
  public static final String
    TOKEN_VALUE_INSTALL_CITY            = "�ݒu��Z���@�s�E��(�S�p)";
  public static final String
    TOKEN_VALUE_INSTALL_ADDRESS1        = "�ݒu��Z���@�Z���P(�S�p)";
  public static final String
    TOKEN_VALUE_INSTALL_ADDRESS2        = "�ݒu��Z���@�Z���Q(�S�p)";
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
// 2009-04-27 [ST��QT1_0708] Add Start
  public static final String
    TOKEN_VALUE_BFA_SINGLE_BYTE_KANA_CHK = "BFA���p�J�i�`�F�b�N";
  public static final String
    TOKEN_VALUE_SINGLE_BYTE_KANA_CHK    = "���p�J�i�`�F�b�N";
  public static final String
    TOKEN_VALUE_DOUBLE_BYTE_CHK         = "�S�p�����`�F�b�N";
// 2009-04-27 [ST��QT1_0708] Add End
// 2010-02-09 [E_�{�ғ�_01538] Mod Start
  public static final String 
    TOKEN_VALUE_COOPERATE_WAIT_INFO_CHK = "�}�X�^�A�g�҂��`�F�b�N";
  public static final String 
    TOKEN_VALUE_COOPERATE_STATUS_CHK    = "�}�X�^�A�g���`�F�b�N";
  public static final String 
    TOKEN_VALUE_VALIDATE_DB_CHK         = "DB�l���؃`�F�b�N";
// 2010-02-09 [E_�{�ғ�_01538] Mod End
// 2010-03-01 [E_�{�ғ�_01678] Add Start
  public static final String 
    TOKEN_VALUE_PAYMENT_TYPE_CASH_CHK   = "�����x�����؃`�F�b�N";
// 2010-03-01 [E_�{�ғ�_01678] Add End
// 2010-03-01 [E_�{�ғ�_01868] Add Start
  public static final String 
    TOKEN_VALUE_INSTALL_CODE_CHK        = "�����R�[�h���؃`�F�b�N";
// 2010-03-01 [E_�{�ғ�_01868] Add End
// 2015-11-30 [E_�{�ғ�_13345] Add Start
  public static final String
    TOKEN_VALUE_STOP_ACCOUNT_CHK        = "���~�ڋq���؃`�F�b�N";
  public static final String
    TOKEN_VALUE_ACCOUNT_INSTALL_CODE_CHK = "�ڋq�������؃`�F�b�N";
// 2015-11-30 [E_�{�ғ�_13345] Add End
// 2011-01-06 Ver1.6 [E_�{�ғ�_02498] Add Start
  public static final String 
    TOKEN_VALUE_BANK_BRANCH_CHK         = "��s�x�X�}�X�^�`�F�b�N";
// 2011-01-06 Ver1.6 [E_�{�ғ�_02498] Add End
// 2011-06-06 Ver1.7 [E_�{�ғ�_01963] Add Start
  public static final String
    TOKEN_VALUE_SUPLLIER_MST_CHK        = "�d����}�X�^�`�F�b�N";
  public static final String
    TOKEN_CREATE_VENDOR_BEFORE_CONT     = "�쐬��";
  public static final String
    TOKEN_VALUE_BUNK_ACCOUNT_MST_CHK    = "��s�����}�X�^�`�F�b�N";
// 2011-06-06 Ver1.7 [E_�{�ғ�_01963] Add End
// 2013-04-01 Ver1.9 [E_�{�ғ�_10413] Add Start
  public static final String
    TOKEN_VALUE_PLURAL_SUPPLIER_CHK     = "��s�����}�X�^�ύX�`�F�b�N";
// 2013-04-01 Ver1.9 [E_�{�ғ�_10413] Add End
// V2.3 Y.Sasaki Added START
  public static final String
    TOKEN_VALUE_SUPPLIER_CHANGE_CHK     = "���t����ύX�`�F�b�N";
// V2.3 Y.Sasaki Added END
// [E_�{�ғ�_16642] Add Start
  public static final String
    TOKEN_VALUE_EMAIL_ADDRESS_CHK       = "���[���A�h���X�`���`�F�b�N";
// [E_�{�ғ�_16642] Add End
// Ver.2.5 Add Start
  public static final String
    TOKEN_VALUE_CHK_PAY_START_DATE      = "�x�����ԊJ�n���`�F�b�N";
  public static final String
    TOKEN_VALUE_CHK_PAY_ITM             = "�x�����ڂ̃`�F�b�N";
  public static final String
    TOKEN_VALUE_MEMO_RANDUM_INFO_REGION = "�r�o�ꌈ���o�����";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_PAYMENT_TYPE   = "�x�������i�ݒu���^���j";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_PAY_START_DATE = "�x�����ԊJ�n���i�ݒu���^���j";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_PAY_END_DATE   = "�x�����ԏI�����i�ݒu���^���j";
  public static final String
    TOKEN_VALUE_AD_INSTALL_SUPP_AMT         = "���z�i�ݒu���^���j";
  public static final String
    TOKEN_VALUE_AD_ASSETS_PAYMENT_TYPE      = "�x�������i�s�����Y�g�p���j";
  public static final String
    TOKEN_VALUE_AD_ASSETS_PAY_START_DATE    = "�x�����ԊJ�n���i�s�����Y�g�p���j";
  public static final String
    TOKEN_VALUE_AD_ASSETS_PAY_END_DATE      = "�x�����ԏI�����i�s�����Y�g�p���j";
  public static final String
    TOKEN_VALUE_AD_ASSETS_AMT               = "���z�i�s�����Y�g�p���j";
  public static final String TAX_TYPE    = "�ŋ敪";
// Ver.2.5 Add End
// Ver.2.7 Add Start
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_THIS_TIME      = "����x���i�ݒu���^���j";
  public static final String
    TOKEN_VALUE_AD_ASSETS_THIS_TIME         = "����x���i�s�����Y�g�p���j";
// Ver.2.7 Add End
  // PDF�o�͎��t������
  public static final String
    TOKEN_VALUE_PDF_OUT                 = "PDF�o��";
  public static final String
    TOKEN_VALUE_START                   = "�N��";
}