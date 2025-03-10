/*==============================================================================
* t@C¼ : XxcsoContractRegistConstants
* Tvà¾   : ©Ì@Ýu_ñîño^¤ÊÅèlNX
* o[W : 2.7
*==============================================================================
* C³ð
* út       Ver. SÒ         C³àe
* ---------- ---- -------------- ----------------------------------------------
* 2009-01-27 1.0  SCS¬ì_      VKì¬
* 2009-02-16 1.1  SCSö½¼l    [CT1-008]BMwè`FbN{bNXs³Î
*                                         BMx¥æªÌÇÁ
* 2009-04-08 1.2  SCSö½¼l    [STáQT1_0364]düæd¡`FbNC³Î
* 2009-04-27 1.3  SCSö½¼l    [STáQT1_0708]¶ñ`FbNêC³
* 2010-02-09 1.4  SCS¢åã    [E_{Ò®_01538]_ñÌ¡mèÎ
* 2010-03-01 1.5  SCS¢åã    [E_{Ò®_01678]»àx¥Î
* 2010-03-01 1.5  SCS¢åã    [E_{Ò®_01868]¨Î
* 2010-01-06 1.6  SCSË¶aK    [E_{Ò®_02498]âsxX}X^`FbNÎ
* 2011-06-06 1.7  SCSË¶aK    [E_{Ò®_01963]VKdüæì¬`FbNÎ
* 2012-06-12 1.8  SCSKË¶aK   [E_{Ò®_09602]_ñæÁ{^ÇÁÎ
* 2013-04-01 1.9  SCSKË¶aK   [E_{Ò®_10413]âsûÀ}X^ÏX`FbNÇÁÎ
* 2015-02-06 2.0  SCSKRºãÄ¾   [E_{Ò®_12565]SPêE_ñæÊüC
* 2015-11-30 2.1  SCSKRºãÄ¾   [E_{Ò®_13345]I[iÏX}X^AgG[Î
* 2016-01-06 2.2  SCSKË¶aK   [E_{Ò®_13456]©Ì@ÇVXeãÖÎ
* 2019-02-19 2.3  SCSK²XØåa [E_{Ò®_15349]düæCD§äÎ
* 2020-12-14 2.4  SCSK²XØåa [E_{Ò®_16642]tæR[hÉRt­[AhXÉÂ¢Ä
* 2022-03-31 2.5  SCSKñºI   [E_{Ò®_18060]©Ì@ÚqÊvÇ
* 2023-06-08 2.6  SCSKÔnw     [E_{Ò®_19179]C{CXÎiBMÖAj
* 2024-09-04 2.7  SCSKÔnw     [E_{Ò®_20174]©Ì@Úqx¥ÇîñÌüC
*==============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.util;

/*******************************************************************************
 * ©Ì@Ýu_ñîño^¤ÊÅèlNXB
 * @author  SCSö½¼l
 * @version 1.1
 *******************************************************************************
 */
public class XxcsoContractRegistConstants
{

  /*****************************************************************************
   * Z^OIuWFNg
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
// 2015-02-06 [E_{Ò®_12565] Add Start
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
// 2015-02-06 [E_{Ò®_12565] Add End
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
   * K{IuWFNg
   *****************************************************************************
   */
  public static final String[] REQUIRED_OBJECTS =
  {
    "CloseDayLayout"
   ,"TransferDayLayout"
   ,"CancellationOfferLayout"
// 2010-03-01 [E_{Ò®_01678] Add Start
//   ,"Bm1BankTransferFeeDivLayout"
// 2010-03-01 [E_{Ò®_01678] Add End
   ,"Bm1BellingDetailsDivLayout"
// Ver.2.6 Add Start
   ,"Bm1InvoiceTaxDivBmLayout"
// Ver.2.6 Add End
   ,"Bm1InqueryBaseLayout"
// 2010-03-01 [E_{Ò®_01678] Add Start
//   ,"Bm1BankNameLayout"
//   ,"Bm1BankAccountTypeLayout"
//   ,"Bm2BankTransferFeeDivLayout"
// 2010-03-01 [E_{Ò®_01678] Add End
   ,"Bm2BellingDetailsDivLayout"
// Ver.2.6 Add Start
   ,"Bm2InvoiceTaxDivBmLayout"
// Ver.2.6 Add End
   ,"Bm2InqueryBaseLayout"
// 2010-03-01 [E_{Ò®_01678] Add Start
//   ,"Bm2BankNameLayout"
//   ,"Bm2BankAccountTypeLayout"
//   ,"Bm3BankTransferFeeDivLayout"
// 2010-03-01 [E_{Ò®_01678] Add End
   ,"Bm3BellingDetailsDivLayout"
// Ver.2.6 Add Start
   ,"Bm3InvoiceTaxDivBmLayout"
// Ver.2.6 Add End
   ,"Bm3InqueryBaseLayout"
// 2010-03-01 [E_{Ò®_01678] Add Start
//   ,"Bm3BankNameLayout"
//   ,"Bm3BankAccountTypeLayout"
// 2010-03-01 [E_{Ò®_01678] Add End
   ,"PublishBaseLayout"
   ,"InstallCodeLayout"
  };

  /*****************************************************************************
   * æª
   *****************************************************************************
   */
  public static final String MODE_UPDATE          = "1";
  public static final String MODE_COPY            = "2";

  /*****************************************************************************
   * _ñæª
   *****************************************************************************
   */
  public static final String FORMAT_STD           = "0";
  public static final String FORMAT_OTHER         = "1";

  /*****************************************************************************
   * Xe[^X
   *****************************************************************************
   */
  public static final String STS_INPUT            = "0";
  public static final String STS_FIX              = "1";
// 2012-06-12 [E_{Ò®_09602] Add Start
  public static final String STS_REJECT           = "9";
// 2012-06-12 [E_{Ò®_09602] Add End

  /*****************************************************************************
   * Uú
   *****************************************************************************
   */
  public static final String TRANSFER_DAY_20      = "20";

  /*****************************************************************************
   * U
   *****************************************************************************
   */
  public static final String LAST_DAY             = "30";
  public static final String NEXT_MONTH           = "50";

  /*****************************************************************************
   * x¥¾×^Cv
   *****************************************************************************
   */
  public static final String TRANCE_EXIST          = "1";
  public static final String TRANCE_NON_EXIST      = "2";

  /*****************************************************************************
   * }X^AgtO
   *****************************************************************************
   */
  public static final String COOPERATE_NONE       = "0";

  /*****************************************************************************
   * ob`Xe[^X
   *****************************************************************************
   */
  public static final String BATCH_PROC_NORMAL    = "0";

  /*****************************************************************************
   * BM`FbN
   *****************************************************************************
   */
  public static final String DELIV_BM1            = "1";
  public static final String DELIV_BM2            = "2";
  public static final String DELIV_BM3            = "3";

  /*****************************************************************************
   * |bvXgúÝèîñ
   *****************************************************************************
   */
  public static final String INIT_FORMAT          = FORMAT_STD;
  public static final String INIT_STS             = STS_INPUT;
  public static final String INIT_TRANSFER_MONTH  = NEXT_MONTH;
  public static final String INIT_TRANSFER_DAY    = "20";
  public static final String INIT_CLOSE_DAY       = LAST_DAY;
  public static final String INIT_CANCELLATION    = "1";

  /*****************************************************************************
   * BMwè`FbNtO
   *****************************************************************************
   */
  public static final String BM_EXIST_FLAG_ON     = "Y";
  public static final String BM_EXIST_FLAG_OFF    = "N";

// 2015-02-06 [E_{Ò®_12565] Add Start
  /*****************************************************************************
   * Ýu¦^àwè`FbNtO
   *****************************************************************************
   */
  public static final String INST_SUPP_EXIST_FLAG_ON     = "Y";
  public static final String INST_SUPP_EXIST_FLAG_OFF    = "N";

  /*****************************************************************************
   * Ðîè¿wè`FbNtO
   *****************************************************************************
   */
  public static final String INTRO_CHG_EXIST_FLAG_ON     = "Y";
  public static final String INTRO_CHG_EXIST_FLAG_OFF    = "N";

  /*****************************************************************************
   * dCãwè`FbNtO
   *****************************************************************************
   */
  public static final String ELECTRIC_EXIST_FLAG_ON     = "Y";
  public static final String ELECTRIC_EXIST_FLAG_OFF    = "N";
// 2015-02-06 [E_{Ò®_12565] Add End

  /*****************************************************************************
   * I[i[ÏX`FbNtO
   *****************************************************************************
   */
  public static final String OWNER_CHANGE_FLAG_ON     = "Y";
  public static final String OWNER_CHANGE_FLAG_OFF    = "N";

  /*****************************************************************************
   * æÊZLeB»ètO
   *****************************************************************************
   */
  public static final String AUTH_NONE                = "0";
  public static final String AUTH_ACCOUNT             = "1";
  public static final String AUTH_BASE_LEADER         = "2";

  /*****************************************************************************
   * }bvp[^
   *****************************************************************************
   */
  public static final String PARAM_URL_PARAM          = "URL_PARAM";
  public static final String PARAM_MESSAGE            = "MESSAGE";

  /*****************************************************************************
   * BMx¥æª
   *****************************************************************************
   */
// 2010-03-01 [E_{Ò®_01678] Add Start
  public static final String BM_PAYMENT_TYPE4         = "4";
// 2010-03-01 [E_{Ò®_01678] Add End
  public static final String BM_PAYMENT_TYPE5         = "5";

// 2015-02-06 [E_{Ò®_12565] Add Start
  /*****************************************************************************
   * x¥æªiÝu¦^àj
   *****************************************************************************
   */
  public static final String INST_SUPP_TYPE0         = "0";
  public static final String INST_SUPP_TYPE1         = "1";

/*****************************************************************************
   * x¥æªiÐîè¿j
   *****************************************************************************
   */
  public static final String INTRO_CHG_TYPE0         = "0";
  public static final String INTRO_CHG_TYPE1         = "1";

/*****************************************************************************
   * x¥ðidCãj
   *****************************************************************************
   */
  public static final String ELECTRIC_PAYMENT_TYPE1  = "1";
  public static final String ELECTRIC_PAYMENT_TYPE2  = "2";
// 2015-02-06 [E_{Ò®_12565] Add End

// 2009-04-08 [STáQT1_0364] Add Start
  /*****************************************************************************
   * Iy[V[hiº{^j
   *****************************************************************************
   */
  public static final String OPERATION_APPLY  = "APPLY";
  public static final String OPERATION_SUBMIT = "SUBMIT";
// 2009-04-08 [STáQT1_0364] Add End
// 2011-06-06 Ver1.7 [E_{Ò®_01963] Add Start
  /*****************************************************************************
   * BMtæVKì¬»è
   *****************************************************************************
   */
  public static final String CREATE_VENDOR    = "CREATE";
// 2011-06-06 Ver1.7 [E_{Ò®_01963] Add End

// 2016-01-06 [E_{Ò®_13456] Add Start
  /*****************************************************************************
   * ©Ì@SAgtO
   *****************************************************************************
   */
  public static final String INTERFACE_NONE       = "0";
  public static final String INTERFACE_NO_TARGET  = "9";
// 2016-01-06 [E_{Ò®_13456] Add End

// Ver.2.6 Add Start
  /*****************************************************************************
   * Ki¿­sÆÒo^iTæªj`FbNtO
   *****************************************************************************
   */
  public static final String INVOICE_T_FLAG_ON     = "T";
  public static final String INVOICE_T_FLAG_OFF    = null;

  /*****************************************************************************
   * tæR[hõCxg
   *****************************************************************************
   */
  public static final String VENDOR_CODE_LOV_VALIDATE     = "lovValidate";
// Ver.2.6 Add End

  /*****************************************************************************
   * g[Nl
   *****************************************************************************
   */
  // [W¼
  public static final String
    TOKEN_VALUE_CONTRACT_INFO           = "_ñÒibjîñ";
  public static final String
    TOKEN_VALUE_PAYCOND_INFO            = "UúE÷ßúîñ";
  public static final String
    TOKEN_VALUE_PERIOD_INFO             = "_ñúÔErðîñ";
  public static final String
    TOKEN_VALUE_BM1_DEST                = "alPwèîñ";
  public static final String
    TOKEN_VALUE_BM2_DEST                = "alQwèîñ";
  public static final String
    TOKEN_VALUE_BM3_DEST                = "alRwèîñ";
// 2015-02-06 [E_{Ò®_12565] Add Start
  public static final String
    TOKEN_VALUE_INST_SUPP               = "Ýu¦^àîñ";
  public static final String
    TOKEN_VALUE_INTRO_CHG               = "Ðîè¿îñ";
  public static final String
    TOKEN_VALUE_ELECTRIC                = "dCãîñ";
// 2015-02-06 [E_{Ò®_12565] Add End
  public static final String
    TOKEN_VALUE_INSTALL_INFO            = "Ýuæîñ";
  public static final String
    TOKEN_VALUE_PUBLISH_BASE_INFO       = "­s³®îñ";

  // Ú¼
  // _ñÒibjîñ[W
  public static final String
    TOKEN_VALUE_CONTRACT_NAME           = "_ñÒ¼(Sp)";
  public static final String
    TOKEN_VALUE_DELEGATE_NAME           = "ã\Ò¼(Sp)";
  public static final String
    TOKEN_VALUE_CONTRACT_POST_CODE      = "_ñÒZ@XÖÔ(¼p)";
  public static final String
    TOKEN_VALUE_CONTRACT_PREFECTURES    = "_ñÒZ@s¹{§(Sp)";
  public static final String
    TOKEN_VALUE_CONTRACT_CITY_WARD      = "_ñÒZ@sEæ(Sp)";
  public static final String
    TOKEN_VALUE_CONTRACT_ADDRESS_1      = "_ñÒZ@ZP(Sp)";
  public static final String
    TOKEN_VALUE_CONTRACT_ADDRESS_2      = "_ñÒZ@ZQ(Sp)";
  public static final String
    TOKEN_VALUE_CONTRACT_EFFECT_DATE    = "_ñ­øú";

  // UúE÷ßúîñ[W
  public static final String
    TOKEN_VALUE_CLOSE_DAY_CODE          = "÷ßú";
  public static final String
    TOKEN_VALUE_TRANSFER_MONTH_CODE     = "U";
  public static final String
    TOKEN_VALUE_TRANSFER_DAY_CODE       = "Uú";

  // _ñúÔErðîñ
  public static final String
    TOKEN_VALUE_CANCELLATION_OFFER_CODE = "_ñð\o";

  // alwèîñ
  public static final String
    TOKEN_VALUE_BM1                     = "alP";
  public static final String
    TOKEN_VALUE_BM2                     = "alQ";
  public static final String
    TOKEN_VALUE_BM3                     = "alR";

  public static final String
    TOKEN_VALUE_DELIVERY_CODE           = "tæR[h";
  public static final String
    TOKEN_VALUE_BANK_TRANSFER_FEE_CHARGE_DIV = "Uè¿S";
  public static final String
    TOKEN_VALUE_BELLING_DETAILS_DIV     = "x¥û@A¾×";
// Ver.2.6 Add Start
  public static final String
    TOKEN_VALUE_INVOICE_TAX_DIV_BM      = "ÁïÅvZæª";
// Ver.2.6 Add End    
  public static final String
    TOKEN_VALUE_INQUERY_CHARGE_HUB_CD   = "â¹S_";
  public static final String
    TOKEN_VALUE_PAYMENT_NAME            = "tæ¼(Sp)";
  public static final String
    TOKEN_VALUE_PAYMENT_NAME_ALT        = "tæ¼Ji(¼p)";
  public static final String
    TOKEN_VALUE_POST_CODE               = "tæZ@XÖÔ(0000000)";
  public static final String
    TOKEN_VALUE_PREFECTURES             = "tæZ@s¹{§(Sp)";
  public static final String
    TOKEN_VALUE_CITY_WARD               = "tæZ@sEæ(Sp)";
  public static final String
    TOKEN_VALUE_ADDRESS_1               = "tæZ@ZP(Sp)";
  public static final String
    TOKEN_VALUE_ADDRESS_2               = "tæZ@ZQ(Sp)";
  public static final String
    TOKEN_VALUE_ADDRESS_LINES_PHONETIC  = "tædbÔ(00-0000-0000)";
// [E_{Ò®_16642] Add Start
  public static final String
    TOKEN_VALUE_EMAIL_ADDRESS           = "tæ[AhX(xxx@xxx)";
// [E_{Ò®_16642] Add End
// Ver.2.6 Add Start
  public static final String
    TOKEN_VALUE_INVOICE_T_FLAG          = "C{CXÔo^ÏiTLj";
  public static final String
    TOKEN_VALUE_INVOICE_T_NO            = "@lÔ";
// Ver.2.6 Add End
  public static final String
    TOKEN_VALUE_BANK_NUMBER             = "àZ@Ö¼";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_TYPE       = "ûÀíÊ";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_NUMBER     = "ûÀÔ(¼p)";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_NAME_KANA  = "ûÀ¼`Ji(¼p)";
  public static final String
    TOKEN_VALUE_BANK_ACCOUNT_NAME_KANJI = "ûÀ¼`¿(Sp)";

  // Ýuæîñ
  public static final String
    TOKEN_VALUE_INSTALL_PARTY_NAME      = "Ýuæ¼(Sp)";
  public static final String
    TOKEN_VALUE_INSTALL_POSTAL_CODE     = "ÝuæZ@XÖÔ(0000000)";
  public static final String
    TOKEN_VALUE_INSTALL_STATE           = "ÝuæZ@s¹{§(Sp)";
  public static final String
    TOKEN_VALUE_INSTALL_CITY            = "ÝuæZ@sEæ(Sp)";
  public static final String
    TOKEN_VALUE_INSTALL_ADDRESS1        = "ÝuæZ@ZP(Sp)";
  public static final String
    TOKEN_VALUE_INSTALL_ADDRESS2        = "ÝuæZ@ZQ(Sp)";
  public static final String
    TOKEN_VALUE_INSTALL_DATE            = "Ýuú";
  public static final String
    TOKEN_VALUE_INSTALL_CODE            = "¨R[h";

  // ­s³®îñ
  public static final String
    TOKEN_VALUE_PUBLISH_DEPT_CODE       = "S_";

  // `FbNG[bZ[WtÁ¶¾
  public static final String
    TOKEN_VALUE_DOUBLE_BYTE_KANA_CHK    = "SpJi`FbN";
  public static final String
    TOKEN_VALUE_TEL_FORMAT_CHK          = "dbÔ®`FbN";
  public static final String
    TOKEN_VALUE_DUPLICATE_VENDOR_NAME_CHK = "düæ¼d¡`FbN";
  public static final String
    TOKEN_VALUE_AR_GL_PERIOD_STATUS     = "ARïvúÔN[Y`FbN";
  public static final String
    TOKEN_VALUE_BM_VENDOR_NAME          = "alPtæ¼`alRtæ¼";
// 2009-04-27 [STáQT1_0708] Add Start
  public static final String
    TOKEN_VALUE_BFA_SINGLE_BYTE_KANA_CHK = "BFA¼pJi`FbN";
  public static final String
    TOKEN_VALUE_SINGLE_BYTE_KANA_CHK    = "¼pJi`FbN";
  public static final String
    TOKEN_VALUE_DOUBLE_BYTE_CHK         = "Sp¶`FbN";
// 2009-04-27 [STáQT1_0708] Add End
// 2010-02-09 [E_{Ò®_01538] Mod Start
  public static final String 
    TOKEN_VALUE_COOPERATE_WAIT_INFO_CHK = "}X^AgÒ¿`FbN";
  public static final String 
    TOKEN_VALUE_COOPERATE_STATUS_CHK    = "}X^Ag`FbN";
  public static final String 
    TOKEN_VALUE_VALIDATE_DB_CHK         = "DBlØ`FbN";
// 2010-02-09 [E_{Ò®_01538] Mod End
// 2010-03-01 [E_{Ò®_01678] Add Start
  public static final String 
    TOKEN_VALUE_PAYMENT_TYPE_CASH_CHK   = "»àx¥Ø`FbN";
// 2010-03-01 [E_{Ò®_01678] Add End
// 2010-03-01 [E_{Ò®_01868] Add Start
  public static final String 
    TOKEN_VALUE_INSTALL_CODE_CHK        = "¨R[hØ`FbN";
// 2010-03-01 [E_{Ò®_01868] Add End
// 2015-11-30 [E_{Ò®_13345] Add Start
  public static final String
    TOKEN_VALUE_STOP_ACCOUNT_CHK        = "~ÚqØ`FbN";
  public static final String
    TOKEN_VALUE_ACCOUNT_INSTALL_CODE_CHK = "Úq¨Ø`FbN";
// 2015-11-30 [E_{Ò®_13345] Add End
// 2011-01-06 Ver1.6 [E_{Ò®_02498] Add Start
  public static final String 
    TOKEN_VALUE_BANK_BRANCH_CHK         = "âsxX}X^`FbN";
// 2011-01-06 Ver1.6 [E_{Ò®_02498] Add End
// 2011-06-06 Ver1.7 [E_{Ò®_01963] Add Start
  public static final String
    TOKEN_VALUE_SUPLLIER_MST_CHK        = "düæ}X^`FbN";
  public static final String
    TOKEN_CREATE_VENDOR_BEFORE_CONT     = "ì¬";
  public static final String
    TOKEN_VALUE_BUNK_ACCOUNT_MST_CHK    = "âsûÀ}X^`FbN";
// 2011-06-06 Ver1.7 [E_{Ò®_01963] Add End
// 2013-04-01 Ver1.9 [E_{Ò®_10413] Add Start
  public static final String
    TOKEN_VALUE_PLURAL_SUPPLIER_CHK     = "âsûÀ}X^ÏX`FbN";
// 2013-04-01 Ver1.9 [E_{Ò®_10413] Add End
// V2.3 Y.Sasaki Added START
  public static final String
    TOKEN_VALUE_SUPPLIER_CHANGE_CHK     = "tæîñÏX`FbN";
// V2.3 Y.Sasaki Added END
// [E_{Ò®_16642] Add Start
  public static final String
    TOKEN_VALUE_EMAIL_ADDRESS_CHK       = "[AhX`®`FbN";
// [E_{Ò®_16642] Add End
// Ver.2.5 Add Start
  public static final String
    TOKEN_VALUE_CHK_PAY_START_DATE      = "x¥úÔJnú`FbN";
  public static final String
    TOKEN_VALUE_CHK_PAY_ITM             = "x¥ÚÌ`FbN";
  public static final String
    TOKEN_VALUE_MEMO_RANDUM_INFO_REGION = "roêoîñ";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_PAYMENT_TYPE   = "x¥ðiÝu¦^àj";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_PAY_START_DATE = "x¥úÔJnúiÝu¦^àj";
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_PAY_END_DATE   = "x¥úÔI¹úiÝu¦^àj";
  public static final String
    TOKEN_VALUE_AD_INSTALL_SUPP_AMT         = "ziÝu¦^àj";
  public static final String
    TOKEN_VALUE_AD_ASSETS_PAYMENT_TYPE      = "x¥ðis­àYgp¿j";
  public static final String
    TOKEN_VALUE_AD_ASSETS_PAY_START_DATE    = "x¥úÔJnúis­àYgp¿j";
  public static final String
    TOKEN_VALUE_AD_ASSETS_PAY_END_DATE      = "x¥úÔI¹úis­àYgp¿j";
  public static final String
    TOKEN_VALUE_AD_ASSETS_AMT               = "zis­àYgp¿j";
  public static final String TAX_TYPE    = "Åæª";
// Ver.2.5 Add End
// Ver.2.7 Add Start
  public static final String
    TOKEN_VALUE_INSTALL_SUPP_THIS_TIME      = "¡ñx¥iÝu¦^àj";
  public static final String
    TOKEN_VALUE_AD_ASSETS_THIS_TIME         = "¡ñx¥is­àYgp¿j";
// Ver.2.7 Add End
  // PDFoÍtÁ¶¾
  public static final String
    TOKEN_VALUE_PDF_OUT                 = "PDFoÍ";
  public static final String
    TOKEN_VALUE_START                   = "N®";
}