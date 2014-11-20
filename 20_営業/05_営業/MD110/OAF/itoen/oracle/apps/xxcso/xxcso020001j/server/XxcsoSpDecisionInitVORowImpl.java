/*============================================================================
* ファイル名 : XxcsoSpDecisionInitVORowImpl
* 概要説明   : SP専決初期化用ビュー行クラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS小川浩     新規作成
* 2011-04-25 1.1  SCS桐生和幸   [E_本稼動_07224]SP専決参照権限変更対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * SP専決を初期化するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionInitVORowImpl extends OAViewRowImpl 
{


  protected static final int EMPLOYEENUMBER = 0;
  protected static final int FULLNAME = 1;
  protected static final int BASECODE = 2;
  protected static final int BASENAME = 3;
  protected static final int CURRENTDATE = 4;
  protected static final int ATTACHFILEUP = 5;
  protected static final int ATTACHFILEUPEXCERPT = 6;
  protected static final int APPLYBUTTONRENDER = 7;
  protected static final int SUBMITBUTTONRENDER = 8;
  protected static final int RETURNBUTTONRENDER = 9;
  protected static final int CONFIRMBUTTONRENDER = 10;
  protected static final int REJECTBUTTONRENDER = 11;
  protected static final int APPROVEBUTTONRENDER = 12;
  protected static final int REQUESTBUTTONRENDER = 13;
  protected static final int APPLICATIONTYPEVIEWRENDER = 14;
  protected static final int APPLICATIONTYPERENDER = 15;
  protected static final int INSTALLACCTNUMBERVIEWRENDER = 16;
  protected static final int INSTALLACCTNUMBER1RENDER = 17;
  protected static final int INSTALLACCTNUMBER2RENDER = 18;
  protected static final int INSTALLPARTYNAMEVIEWRENDER = 19;
  protected static final int INSTALLPARTYNAMERENDER = 20;
  protected static final int INSTALLPARTYNAMEALTVIEWRENDER = 21;
  protected static final int INSTALLPARTYNAMEALTRENDER = 22;
  protected static final int INSTALLNAMEVIEWRENDER = 23;
  protected static final int INSTALLNAMERENDER = 24;
  protected static final int INSTALLPOSTCDFVIEWRENDER = 25;
  protected static final int INSTALLPOSTCDFRENDER = 26;
  protected static final int INSTALLPOSTCDSVIEWRENDER = 27;
  protected static final int INSTALLPOSTCDSRENDER = 28;
  protected static final int INSTALLSTATEVIEWRENDER = 29;
  protected static final int INSTALLSTATERENDER = 30;
  protected static final int INSTALLCITYVIEWRENDER = 31;
  protected static final int INSTALLCITYRENDER = 32;
  protected static final int INSTALLADDRESS1VIEWRENDER = 33;
  protected static final int INSTALLADDRESS1RENDER = 34;
  protected static final int INSTALLADDRESS2VIEWRENDER = 35;
  protected static final int INSTALLADDRESS2RENDER = 36;
  protected static final int INSTALLADDRESSLINEVIEWRENDER = 37;
  protected static final int INSTALLADDRESSLINERENDER = 38;
  protected static final int BIZCONDTYPEVIEWRENDER = 39;
  protected static final int BIZCONDTYPERENDER = 40;
  protected static final int BUSINESSTYPEVIEWRENDER = 41;
  protected static final int BUSINESSTYPERENDER = 42;
  protected static final int INSTALLLOCATIONVIEWRENDER = 43;
  protected static final int INSTALLLOCATIONRENDER = 44;
  protected static final int EXTREFOPCLTYPEVIEWRENDER = 45;
  protected static final int EXTREFOPCLTYPERENDER = 46;
  protected static final int EMPLOYEENUMBERVIEWRENDER = 47;
  protected static final int EMPLOYEENUMBERRENDER = 48;
  protected static final int PUBLISHBASECODEVIEWRENDER = 49;
  protected static final int PUBLISHBASECODERENDER = 50;
  protected static final int INSTALLDATEREQUIREDVIEWRENDER = 51;
  protected static final int INSTALLDATEREQUIREDRENDER = 52;
  protected static final int INSTALLDATEVIEWRENDER = 53;
  protected static final int INSTALLDATERENDER = 54;
  protected static final int LEASECOMPANYVIEWRENDER = 55;
  protected static final int LEASECOMPANYRENDER = 56;
  protected static final int SAMEINSTALLACCTFLAGVIEWRENDER = 57;
  protected static final int SAMEINSTALLACCTFLAGRENDER = 58;
  protected static final int CONTRACTNUMBERVIEWRENDER = 59;
  protected static final int CONTRACTNUMBER1RENDER = 60;
  protected static final int CONTRACTNUMBER2RENDER = 61;
  protected static final int CONTRACTNAMEVIEWRENDER = 62;
  protected static final int CONTRACTNAMERENDER = 63;
  protected static final int CONTRACTNAMEALTVIEWRENDER = 64;
  protected static final int CONTRACTNAMEALTRENDER = 65;
  protected static final int CONTRACTPOSTCDFVIEWRENDER = 66;
  protected static final int CONTRACTPOSTCDFRENDER = 67;
  protected static final int CONTRACTPOSTCDSVIEWRENDER = 68;
  protected static final int CONTRACTPOSTCDSRENDER = 69;
  protected static final int CONTRACTSTATEVIEWRENDER = 70;
  protected static final int CONTRACTSTATERENDER = 71;
  protected static final int CONTRACTCITYVIEWRENDER = 72;
  protected static final int CONTRACTCITYRENDER = 73;
  protected static final int CONTRACTADDRESS1VIEWRENDER = 74;
  protected static final int CONTRACTADDRESS1RENDER = 75;
  protected static final int CONTRACTADDRESS2VIEWRENDER = 76;
  protected static final int CONTRACTADDRESS2RENDER = 77;
  protected static final int CONTRACTADDRESSLINEVIEWRENDER = 78;
  protected static final int CONTRACTADDRESSLINERENDER = 79;
  protected static final int DELEGATENAMEVIEWRENDER = 80;
  protected static final int DELEGATENAMERENDER = 81;
  protected static final int NEWOLDTYPEVIEWRENDER = 82;
  protected static final int NEWOLDTYPERENDER = 83;
  protected static final int SELENUMBERVIEWRENDER = 84;
  protected static final int SELENUMBERRENDER = 85;
  protected static final int MAKERCODEVIEWRENDER = 86;
  protected static final int MAKERCODERENDER = 87;
  protected static final int STANDARDTYPEVIEWRENDER = 88;
  protected static final int STANDARDTYPERENDER = 89;
  protected static final int VDINFO3REQUIREDLAYOUTRENDER = 90;
  protected static final int VDINFO3LAYOUTRENDER = 91;
  protected static final int UNNUMBERVIEWRENDER = 92;
  protected static final int UNNUMBERRENDER = 93;
  protected static final int CONDBIZTYPEVIEWRENDER = 94;
  protected static final int CONDBIZTYPERENDER = 95;
  protected static final int SALESCONDITIONHDRRNRENDER = 96;
  protected static final int SCBM2GRPRENDER = 97;
  protected static final int SCCONTRIBUTEGRPRENDER = 98;
  protected static final int SCACTIONFLRNRENDER = 99;
  protected static final int SCTABLEFOOTERRENDER = 100;
  protected static final int CONTAINERCONDITIONHDRRNRENDER = 101;
  protected static final int ALLCONTAINERTYPEVIEWRENDER = 102;
  protected static final int ALLCONTAINERTYPERENDER = 103;
  protected static final int ALLCCADVTBLRNRENDER = 104;
  protected static final int ALLCCBM2GRPRENDER = 105;
  protected static final int ALLCCCONTRIBUTEGRPRENDER = 106;
  protected static final int ALLCCACTIONFLRNRENDER = 107;
  protected static final int SELCCADVTBLRNRENDER = 108;
  protected static final int SELCCBM2GRPRENDER = 109;
  protected static final int SELCCCONTRIBUTEGRPRENDER = 110;
  protected static final int SELCCACTIONFLRNRENDER = 111;
  protected static final int CONTRACTYEARDATEVIEWRENDER = 112;
  protected static final int CONTRACTYEARDATERENDER = 113;
  protected static final int INSTALLSUPPORTAMTVIEWRENDER = 114;
  protected static final int INSTALLSUPPORTAMTRENDER = 115;
  protected static final int INSTALLSUPPORTAMT2VIEWRENDER = 116;
  protected static final int INSTALLSUPPORTAMT2RENDER = 117;
  protected static final int PAYMENTCYCLEVIEWRENDER = 118;
  protected static final int PAYMENTCYCLERENDER = 119;
  protected static final int ELECSTARTREQUIREDLABELRENDER = 120;
  protected static final int ELECSTARTLABELRENDER = 121;
  protected static final int ELECTRICITYTYPEVIEWRENDER = 122;
  protected static final int ELECTRICITYTYPERENDER = 123;
  protected static final int ELECTRICITYAMOUNTVIEWRENDER = 124;
  protected static final int ELECTRICITYAMOUNTRENDER = 125;
  protected static final int ELECAMOUNTLABELRENDER = 126;
  protected static final int CONDITIONREASONVIEWRENDER = 127;
  protected static final int CONDITIONREASONRENDER = 128;
  protected static final int BM1INFOHDRRNRENDER = 129;
  protected static final int BM1SENDTYPEVIEWRENDER = 130;
  protected static final int BM1SENDTYPERENDER = 131;
  protected static final int BM1VENDORNUMBERVIEWRENDER = 132;
  protected static final int BM1VENDORNUMBER1RENDER = 133;
  protected static final int BM1VENDORNUMBER2RENDER = 134;
  protected static final int BM1VENDORNAMEVIEWRENDER = 135;
  protected static final int BM1VENDORNAMERENDER = 136;
  protected static final int BM1VENDORNAMEALTVIEWRENDER = 137;
  protected static final int BM1VENDORNAMEALTRENDER = 138;
  protected static final int BM1TRANSFERTYPELAYOUTRENDER = 139;
  protected static final int BM1TRANSFERTYPEVIEWRENDER = 140;
  protected static final int BM1TRANSFERTYPERENDER = 141;
  protected static final int BM1PAYMENTTYPEVIEWRENDER = 142;
  protected static final int BM1PAYMENTTYPERENDER = 143;
  protected static final int BM1INQUIRYBASELAYOUTRENDER = 144;
  protected static final int BM1POSTALCODELAYOUTRENDER = 145;
  protected static final int BM1POSTCDFVIEWRENDER = 146;
  protected static final int BM1POSTCDFRENDER = 147;
  protected static final int BM1POSTCDSVIEWRENDER = 148;
  protected static final int BM1POSTCDSRENDER = 149;
  protected static final int BM1STATEVIEWRENDER = 150;
  protected static final int BM1STATERENDER = 151;
  protected static final int BM1CITYVIEWRENDER = 152;
  protected static final int BM1CITYRENDER = 153;
  protected static final int BM1ADDRESS1VIEWRENDER = 154;
  protected static final int BM1ADDRESS1RENDER = 155;
  protected static final int BM1ADDRESS2VIEWRENDER = 156;
  protected static final int BM1ADDRESS2RENDER = 157;
  protected static final int BM1ADDRESSLINEVIEWRENDER = 158;
  protected static final int BM1ADDRESSLINERENDER = 159;
  protected static final int BM2INFOHDRRNRENDER = 160;
  protected static final int CONTRIBUTEINFOHDRRNRENDER = 161;
  protected static final int BM2VENDORNUMBERVIEWRENDER = 162;
  protected static final int BM2VENDORNUMBER1RENDER = 163;
  protected static final int BM2VENDORNUMBER2RENDER = 164;
  protected static final int BM2VENDORNAMEVIEWRENDER = 165;
  protected static final int BM2VENDORNAMERENDER = 166;
  protected static final int BM2VENDORNAMEALTVIEWRENDER = 167;
  protected static final int BM2VENDORNAMEALTRENDER = 168;
  protected static final int BM2POSTALCODELAYOUTRENDER = 169;
  protected static final int BM2POSTCDFVIEWRENDER = 170;
  protected static final int BM2POSTCDFRENDER = 171;
  protected static final int BM2POSTCDSVIEWRENDER = 172;
  protected static final int BM2POSTCDSRENDER = 173;
  protected static final int BM2STATEVIEWRENDER = 174;
  protected static final int BM2STATERENDER = 175;
  protected static final int BM2CITYVIEWRENDER = 176;
  protected static final int BM2CITYRENDER = 177;
  protected static final int BM2ADDRESS1VIEWRENDER = 178;
  protected static final int BM2ADDRESS1RENDER = 179;
  protected static final int BM2ADDRESS2VIEWRENDER = 180;
  protected static final int BM2ADDRESS2RENDER = 181;
  protected static final int BM2ADDRESSLINEVIEWRENDER = 182;
  protected static final int BM2ADDRESSLINERENDER = 183;
  protected static final int BM2TRANSFERTYPELAYOUTRENDER = 184;
  protected static final int BM2TRANSFERTYPEVIEWRENDER = 185;
  protected static final int BM2TRANSFERTYPERENDER = 186;
  protected static final int BM2PAYMENTTYPEVIEWRENDER = 187;
  protected static final int BM2PAYMENTTYPERENDER = 188;
  protected static final int BM2INQUIRYBASELAYOUTRENDER = 189;
  protected static final int BM3INFOHDRRNRENDER = 190;
  protected static final int BM3VENDORNUMBERVIEWRENDER = 191;
  protected static final int BM3VENDORNUMBER1RENDER = 192;
  protected static final int BM3VENDORNUMBER2RENDER = 193;
  protected static final int BM3VENDORNAMEVIEWRENDER = 194;
  protected static final int BM3VENDORNAMERENDER = 195;
  protected static final int BM3VENDORNAMEALTVIEWRENDER = 196;
  protected static final int BM3VENDORNAMEALTRENDER = 197;
  protected static final int BM3POSTALCODELAYOUTRENDER = 198;
  protected static final int BM3POSTCDFVIEWRENDER = 199;
  protected static final int BM3POSTCDFRENDER = 200;
  protected static final int BM3POSTCDSVIEWRENDER = 201;
  protected static final int BM3POSTCDSRENDER = 202;
  protected static final int BM3STATEVIEWRENDER = 203;
  protected static final int BM3STATERENDER = 204;
  protected static final int BM3CITYVIEWRENDER = 205;
  protected static final int BM3CITYRENDER = 206;
  protected static final int BM3ADDRESS1VIEWRENDER = 207;
  protected static final int BM3ADDRESS1RENDER = 208;
  protected static final int BM3ADDRESS2VIEWRENDER = 209;
  protected static final int BM3ADDRESS2RENDER = 210;
  protected static final int BM3ADDRESSLINEVIEWRENDER = 211;
  protected static final int BM3ADDRESSLINERENDER = 212;
  protected static final int BM3TRANSFERTYPELAYOUTRENDER = 213;
  protected static final int BM3TRANSFERTYPEVIEWRENDER = 214;
  protected static final int BM3TRANSFERTYPERENDER = 215;
  protected static final int BM3PAYMENTTYPEVIEWRENDER = 216;
  protected static final int BM3PAYMENTTYPERENDER = 217;
  protected static final int BM3INQUIRYBASELAYOUTRENDER = 218;
  protected static final int REFLECTCONTRACTBUTTONRENDER = 219;
  protected static final int CNTRCTELECSPACER2RENDER = 220;
  protected static final int OTHERCONTENTVIEWRENDER = 221;
  protected static final int OTHERCONTENTRENDER = 222;
  protected static final int CALCPROFITBUTTONRENDER = 223;
  protected static final int SALESMONTHVIEWRENDER = 224;
  protected static final int SALESMONTHRENDER = 225;
  protected static final int BMRATEVIEWRENDER = 226;
  protected static final int BMRATERENDER = 227;
  protected static final int LEASECHARGEMONTHVIEWRENDER = 228;
  protected static final int LEASECHARGEMONTHRENDER = 229;
  protected static final int CONSTRUCTIONCHARGEVIEWRENDER = 230;
  protected static final int CONSTRUCTIONCHARGERENDER = 231;
  protected static final int ELECTRICITYAMTMONTHVIEWRENDER = 232;
  protected static final int ELECTRICITYAMTMONTHRENDER = 233;
  protected static final int ATTACHACTIONFLRNRENDER = 234;
  protected static final int ACTPOBASECODE = 235;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionInitVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmployeeNumber
   */
  public String getEmployeeNumber()
  {
    return (String)getAttributeInternal(EMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmployeeNumber
   */
  public void setEmployeeNumber(String value)
  {
    setAttributeInternal(EMPLOYEENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FullName
   */
  public String getFullName()
  {
    return (String)getAttributeInternal(FULLNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FullName
   */
  public void setFullName(String value)
  {
    setAttributeInternal(FULLNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseCode
   */
  public String getBaseCode()
  {
    return (String)getAttributeInternal(BASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseCode
   */
  public void setBaseCode(String value)
  {
    setAttributeInternal(BASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseName
   */
  public String getBaseName()
  {
    return (String)getAttributeInternal(BASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseName
   */
  public void setBaseName(String value)
  {
    setAttributeInternal(BASENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CurrentDate
   */
  public Date getCurrentDate()
  {
    return (Date)getAttributeInternal(CURRENTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CurrentDate
   */
  public void setCurrentDate(Date value)
  {
    setAttributeInternal(CURRENTDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case FULLNAME:
        return getFullName();
      case BASECODE:
        return getBaseCode();
      case BASENAME:
        return getBaseName();
      case CURRENTDATE:
        return getCurrentDate();
      case ATTACHFILEUP:
        return getAttachFileUp();
      case ATTACHFILEUPEXCERPT:
        return getAttachFileUpExcerpt();
      case APPLYBUTTONRENDER:
        return getApplyButtonRender();
      case SUBMITBUTTONRENDER:
        return getSubmitButtonRender();
      case RETURNBUTTONRENDER:
        return getReturnButtonRender();
      case CONFIRMBUTTONRENDER:
        return getConfirmButtonRender();
      case REJECTBUTTONRENDER:
        return getRejectButtonRender();
      case APPROVEBUTTONRENDER:
        return getApproveButtonRender();
      case REQUESTBUTTONRENDER:
        return getRequestButtonRender();
      case APPLICATIONTYPEVIEWRENDER:
        return getApplicationTypeViewRender();
      case APPLICATIONTYPERENDER:
        return getApplicationTypeRender();
      case INSTALLACCTNUMBERVIEWRENDER:
        return getInstallAcctNumberViewRender();
      case INSTALLACCTNUMBER1RENDER:
        return getInstallAcctNumber1Render();
      case INSTALLACCTNUMBER2RENDER:
        return getInstallAcctNumber2Render();
      case INSTALLPARTYNAMEVIEWRENDER:
        return getInstallPartyNameViewRender();
      case INSTALLPARTYNAMERENDER:
        return getInstallPartyNameRender();
      case INSTALLPARTYNAMEALTVIEWRENDER:
        return getInstallPartyNameAltViewRender();
      case INSTALLPARTYNAMEALTRENDER:
        return getInstallPartyNameAltRender();
      case INSTALLNAMEVIEWRENDER:
        return getInstallNameViewRender();
      case INSTALLNAMERENDER:
        return getInstallNameRender();
      case INSTALLPOSTCDFVIEWRENDER:
        return getInstallPostCdFViewRender();
      case INSTALLPOSTCDFRENDER:
        return getInstallPostCdFRender();
      case INSTALLPOSTCDSVIEWRENDER:
        return getInstallPostCdSViewRender();
      case INSTALLPOSTCDSRENDER:
        return getInstallPostCdSRender();
      case INSTALLSTATEVIEWRENDER:
        return getInstallStateViewRender();
      case INSTALLSTATERENDER:
        return getInstallStateRender();
      case INSTALLCITYVIEWRENDER:
        return getInstallCityViewRender();
      case INSTALLCITYRENDER:
        return getInstallCityRender();
      case INSTALLADDRESS1VIEWRENDER:
        return getInstallAddress1ViewRender();
      case INSTALLADDRESS1RENDER:
        return getInstallAddress1Render();
      case INSTALLADDRESS2VIEWRENDER:
        return getInstallAddress2ViewRender();
      case INSTALLADDRESS2RENDER:
        return getInstallAddress2Render();
      case INSTALLADDRESSLINEVIEWRENDER:
        return getInstallAddressLineViewRender();
      case INSTALLADDRESSLINERENDER:
        return getInstallAddressLineRender();
      case BIZCONDTYPEVIEWRENDER:
        return getBizCondTypeViewRender();
      case BIZCONDTYPERENDER:
        return getBizCondTypeRender();
      case BUSINESSTYPEVIEWRENDER:
        return getBusinessTypeViewRender();
      case BUSINESSTYPERENDER:
        return getBusinessTypeRender();
      case INSTALLLOCATIONVIEWRENDER:
        return getInstallLocationViewRender();
      case INSTALLLOCATIONRENDER:
        return getInstallLocationRender();
      case EXTREFOPCLTYPEVIEWRENDER:
        return getExtRefOpclTypeViewRender();
      case EXTREFOPCLTYPERENDER:
        return getExtRefOpclTypeRender();
      case EMPLOYEENUMBERVIEWRENDER:
        return getEmployeeNumberViewRender();
      case EMPLOYEENUMBERRENDER:
        return getEmployeeNumberRender();
      case PUBLISHBASECODEVIEWRENDER:
        return getPublishBaseCodeViewRender();
      case PUBLISHBASECODERENDER:
        return getPublishBaseCodeRender();
      case INSTALLDATEREQUIREDVIEWRENDER:
        return getInstallDateRequiredViewRender();
      case INSTALLDATEREQUIREDRENDER:
        return getInstallDateRequiredRender();
      case INSTALLDATEVIEWRENDER:
        return getInstallDateViewRender();
      case INSTALLDATERENDER:
        return getInstallDateRender();
      case LEASECOMPANYVIEWRENDER:
        return getLeaseCompanyViewRender();
      case LEASECOMPANYRENDER:
        return getLeaseCompanyRender();
      case SAMEINSTALLACCTFLAGVIEWRENDER:
        return getSameInstallAcctFlagViewRender();
      case SAMEINSTALLACCTFLAGRENDER:
        return getSameInstallAcctFlagRender();
      case CONTRACTNUMBERVIEWRENDER:
        return getContractNumberViewRender();
      case CONTRACTNUMBER1RENDER:
        return getContractNumber1Render();
      case CONTRACTNUMBER2RENDER:
        return getContractNumber2Render();
      case CONTRACTNAMEVIEWRENDER:
        return getContractNameViewRender();
      case CONTRACTNAMERENDER:
        return getContractNameRender();
      case CONTRACTNAMEALTVIEWRENDER:
        return getContractNameAltViewRender();
      case CONTRACTNAMEALTRENDER:
        return getContractNameAltRender();
      case CONTRACTPOSTCDFVIEWRENDER:
        return getContractPostCdFViewRender();
      case CONTRACTPOSTCDFRENDER:
        return getContractPostCdFRender();
      case CONTRACTPOSTCDSVIEWRENDER:
        return getContractPostCdSViewRender();
      case CONTRACTPOSTCDSRENDER:
        return getContractPostCdSRender();
      case CONTRACTSTATEVIEWRENDER:
        return getContractStateViewRender();
      case CONTRACTSTATERENDER:
        return getContractStateRender();
      case CONTRACTCITYVIEWRENDER:
        return getContractCityViewRender();
      case CONTRACTCITYRENDER:
        return getContractCityRender();
      case CONTRACTADDRESS1VIEWRENDER:
        return getContractAddress1ViewRender();
      case CONTRACTADDRESS1RENDER:
        return getContractAddress1Render();
      case CONTRACTADDRESS2VIEWRENDER:
        return getContractAddress2ViewRender();
      case CONTRACTADDRESS2RENDER:
        return getContractAddress2Render();
      case CONTRACTADDRESSLINEVIEWRENDER:
        return getContractAddressLineViewRender();
      case CONTRACTADDRESSLINERENDER:
        return getContractAddressLineRender();
      case DELEGATENAMEVIEWRENDER:
        return getDelegateNameViewRender();
      case DELEGATENAMERENDER:
        return getDelegateNameRender();
      case NEWOLDTYPEVIEWRENDER:
        return getNewoldTypeViewRender();
      case NEWOLDTYPERENDER:
        return getNewoldTypeRender();
      case SELENUMBERVIEWRENDER:
        return getSeleNumberViewRender();
      case SELENUMBERRENDER:
        return getSeleNumberRender();
      case MAKERCODEVIEWRENDER:
        return getMakerCodeViewRender();
      case MAKERCODERENDER:
        return getMakerCodeRender();
      case STANDARDTYPEVIEWRENDER:
        return getStandardTypeViewRender();
      case STANDARDTYPERENDER:
        return getStandardTypeRender();
      case VDINFO3REQUIREDLAYOUTRENDER:
        return getVdInfo3RequiredLayoutRender();
      case VDINFO3LAYOUTRENDER:
        return getVdInfo3LayoutRender();
      case UNNUMBERVIEWRENDER:
        return getUnNumberViewRender();
      case UNNUMBERRENDER:
        return getUnNumberRender();
      case CONDBIZTYPEVIEWRENDER:
        return getCondBizTypeViewRender();
      case CONDBIZTYPERENDER:
        return getCondBizTypeRender();
      case SALESCONDITIONHDRRNRENDER:
        return getSalesConditionHdrRNRender();
      case SCBM2GRPRENDER:
        return getScBm2GrpRender();
      case SCCONTRIBUTEGRPRENDER:
        return getScContributeGrpRender();
      case SCACTIONFLRNRENDER:
        return getScActionFlRNRender();
      case SCTABLEFOOTERRENDER:
        return getScTableFooterRender();
      case CONTAINERCONDITIONHDRRNRENDER:
        return getContainerConditionHdrRNRender();
      case ALLCONTAINERTYPEVIEWRENDER:
        return getAllContainerTypeViewRender();
      case ALLCONTAINERTYPERENDER:
        return getAllContainerTypeRender();
      case ALLCCADVTBLRNRENDER:
        return getAllCcAdvTblRNRender();
      case ALLCCBM2GRPRENDER:
        return getAllCcBm2GrpRender();
      case ALLCCCONTRIBUTEGRPRENDER:
        return getAllCcContributeGrpRender();
      case ALLCCACTIONFLRNRENDER:
        return getAllCcActionFlRNRender();
      case SELCCADVTBLRNRENDER:
        return getSelCcAdvTblRNRender();
      case SELCCBM2GRPRENDER:
        return getSelCcBm2GrpRender();
      case SELCCCONTRIBUTEGRPRENDER:
        return getSelCcContributeGrpRender();
      case SELCCACTIONFLRNRENDER:
        return getSelCcActionFlRNRender();
      case CONTRACTYEARDATEVIEWRENDER:
        return getContractYearDateViewRender();
      case CONTRACTYEARDATERENDER:
        return getContractYearDateRender();
      case INSTALLSUPPORTAMTVIEWRENDER:
        return getInstallSupportAmtViewRender();
      case INSTALLSUPPORTAMTRENDER:
        return getInstallSupportAmtRender();
      case INSTALLSUPPORTAMT2VIEWRENDER:
        return getInstallSupportAmt2ViewRender();
      case INSTALLSUPPORTAMT2RENDER:
        return getInstallSupportAmt2Render();
      case PAYMENTCYCLEVIEWRENDER:
        return getPaymentCycleViewRender();
      case PAYMENTCYCLERENDER:
        return getPaymentCycleRender();
      case ELECSTARTREQUIREDLABELRENDER:
        return getElecStartRequiredLabelRender();
      case ELECSTARTLABELRENDER:
        return getElecStartLabelRender();
      case ELECTRICITYTYPEVIEWRENDER:
        return getElectricityTypeViewRender();
      case ELECTRICITYTYPERENDER:
        return getElectricityTypeRender();
      case ELECTRICITYAMOUNTVIEWRENDER:
        return getElectricityAmountViewRender();
      case ELECTRICITYAMOUNTRENDER:
        return getElectricityAmountRender();
      case ELECAMOUNTLABELRENDER:
        return getElecAmountLabelRender();
      case CONDITIONREASONVIEWRENDER:
        return getConditionReasonViewRender();
      case CONDITIONREASONRENDER:
        return getConditionReasonRender();
      case BM1INFOHDRRNRENDER:
        return getBm1InfoHdrRNRender();
      case BM1SENDTYPEVIEWRENDER:
        return getBm1SendTypeViewRender();
      case BM1SENDTYPERENDER:
        return getBm1SendTypeRender();
      case BM1VENDORNUMBERVIEWRENDER:
        return getBm1VendorNumberViewRender();
      case BM1VENDORNUMBER1RENDER:
        return getBm1VendorNumber1Render();
      case BM1VENDORNUMBER2RENDER:
        return getBm1VendorNumber2Render();
      case BM1VENDORNAMEVIEWRENDER:
        return getBm1VendorNameViewRender();
      case BM1VENDORNAMERENDER:
        return getBm1VendorNameRender();
      case BM1VENDORNAMEALTVIEWRENDER:
        return getBm1VendorNameAltViewRender();
      case BM1VENDORNAMEALTRENDER:
        return getBm1VendorNameAltRender();
      case BM1TRANSFERTYPELAYOUTRENDER:
        return getBm1TransferTypeLayoutRender();
      case BM1TRANSFERTYPEVIEWRENDER:
        return getBm1TransferTypeViewRender();
      case BM1TRANSFERTYPERENDER:
        return getBm1TransferTypeRender();
      case BM1PAYMENTTYPEVIEWRENDER:
        return getBm1PaymentTypeViewRender();
      case BM1PAYMENTTYPERENDER:
        return getBm1PaymentTypeRender();
      case BM1INQUIRYBASELAYOUTRENDER:
        return getBm1InquiryBaseLayoutRender();
      case BM1POSTALCODELAYOUTRENDER:
        return getBm1PostalCodeLayoutRender();
      case BM1POSTCDFVIEWRENDER:
        return getBm1PostCdFViewRender();
      case BM1POSTCDFRENDER:
        return getBm1PostCdFRender();
      case BM1POSTCDSVIEWRENDER:
        return getBm1PostCdSViewRender();
      case BM1POSTCDSRENDER:
        return getBm1PostCdSRender();
      case BM1STATEVIEWRENDER:
        return getBm1StateViewRender();
      case BM1STATERENDER:
        return getBm1StateRender();
      case BM1CITYVIEWRENDER:
        return getBm1CityViewRender();
      case BM1CITYRENDER:
        return getBm1CityRender();
      case BM1ADDRESS1VIEWRENDER:
        return getBm1Address1ViewRender();
      case BM1ADDRESS1RENDER:
        return getBm1Address1Render();
      case BM1ADDRESS2VIEWRENDER:
        return getBm1Address2ViewRender();
      case BM1ADDRESS2RENDER:
        return getBm1Address2Render();
      case BM1ADDRESSLINEVIEWRENDER:
        return getBm1AddressLineViewRender();
      case BM1ADDRESSLINERENDER:
        return getBm1AddressLineRender();
      case BM2INFOHDRRNRENDER:
        return getBm2InfoHdrRNRender();
      case CONTRIBUTEINFOHDRRNRENDER:
        return getContributeInfoHdrRNRender();
      case BM2VENDORNUMBERVIEWRENDER:
        return getBm2VendorNumberViewRender();
      case BM2VENDORNUMBER1RENDER:
        return getBm2VendorNumber1Render();
      case BM2VENDORNUMBER2RENDER:
        return getBm2VendorNumber2Render();
      case BM2VENDORNAMEVIEWRENDER:
        return getBm2VendorNameViewRender();
      case BM2VENDORNAMERENDER:
        return getBm2VendorNameRender();
      case BM2VENDORNAMEALTVIEWRENDER:
        return getBm2VendorNameAltViewRender();
      case BM2VENDORNAMEALTRENDER:
        return getBm2VendorNameAltRender();
      case BM2POSTALCODELAYOUTRENDER:
        return getBm2PostalCodeLayoutRender();
      case BM2POSTCDFVIEWRENDER:
        return getBm2PostCdFViewRender();
      case BM2POSTCDFRENDER:
        return getBm2PostCdFRender();
      case BM2POSTCDSVIEWRENDER:
        return getBm2PostCdSViewRender();
      case BM2POSTCDSRENDER:
        return getBm2PostCdSRender();
      case BM2STATEVIEWRENDER:
        return getBm2StateViewRender();
      case BM2STATERENDER:
        return getBm2StateRender();
      case BM2CITYVIEWRENDER:
        return getBm2CityViewRender();
      case BM2CITYRENDER:
        return getBm2CityRender();
      case BM2ADDRESS1VIEWRENDER:
        return getBm2Address1ViewRender();
      case BM2ADDRESS1RENDER:
        return getBm2Address1Render();
      case BM2ADDRESS2VIEWRENDER:
        return getBm2Address2ViewRender();
      case BM2ADDRESS2RENDER:
        return getBm2Address2Render();
      case BM2ADDRESSLINEVIEWRENDER:
        return getBm2AddressLineViewRender();
      case BM2ADDRESSLINERENDER:
        return getBm2AddressLineRender();
      case BM2TRANSFERTYPELAYOUTRENDER:
        return getBm2TransferTypeLayoutRender();
      case BM2TRANSFERTYPEVIEWRENDER:
        return getBm2TransferTypeViewRender();
      case BM2TRANSFERTYPERENDER:
        return getBm2TransferTypeRender();
      case BM2PAYMENTTYPEVIEWRENDER:
        return getBm2PaymentTypeViewRender();
      case BM2PAYMENTTYPERENDER:
        return getBm2PaymentTypeRender();
      case BM2INQUIRYBASELAYOUTRENDER:
        return getBm2InquiryBaseLayoutRender();
      case BM3INFOHDRRNRENDER:
        return getBm3InfoHdrRNRender();
      case BM3VENDORNUMBERVIEWRENDER:
        return getBm3VendorNumberViewRender();
      case BM3VENDORNUMBER1RENDER:
        return getBm3VendorNumber1Render();
      case BM3VENDORNUMBER2RENDER:
        return getBm3VendorNumber2Render();
      case BM3VENDORNAMEVIEWRENDER:
        return getBm3VendorNameViewRender();
      case BM3VENDORNAMERENDER:
        return getBm3VendorNameRender();
      case BM3VENDORNAMEALTVIEWRENDER:
        return getBm3VendorNameAltViewRender();
      case BM3VENDORNAMEALTRENDER:
        return getBm3VendorNameAltRender();
      case BM3POSTALCODELAYOUTRENDER:
        return getBm3PostalCodeLayoutRender();
      case BM3POSTCDFVIEWRENDER:
        return getBm3PostCdFViewRender();
      case BM3POSTCDFRENDER:
        return getBm3PostCdFRender();
      case BM3POSTCDSVIEWRENDER:
        return getBm3PostCdSViewRender();
      case BM3POSTCDSRENDER:
        return getBm3PostCdSRender();
      case BM3STATEVIEWRENDER:
        return getBm3StateViewRender();
      case BM3STATERENDER:
        return getBm3StateRender();
      case BM3CITYVIEWRENDER:
        return getBm3CityViewRender();
      case BM3CITYRENDER:
        return getBm3CityRender();
      case BM3ADDRESS1VIEWRENDER:
        return getBm3Address1ViewRender();
      case BM3ADDRESS1RENDER:
        return getBm3Address1Render();
      case BM3ADDRESS2VIEWRENDER:
        return getBm3Address2ViewRender();
      case BM3ADDRESS2RENDER:
        return getBm3Address2Render();
      case BM3ADDRESSLINEVIEWRENDER:
        return getBm3AddressLineViewRender();
      case BM3ADDRESSLINERENDER:
        return getBm3AddressLineRender();
      case BM3TRANSFERTYPELAYOUTRENDER:
        return getBm3TransferTypeLayoutRender();
      case BM3TRANSFERTYPEVIEWRENDER:
        return getBm3TransferTypeViewRender();
      case BM3TRANSFERTYPERENDER:
        return getBm3TransferTypeRender();
      case BM3PAYMENTTYPEVIEWRENDER:
        return getBm3PaymentTypeViewRender();
      case BM3PAYMENTTYPERENDER:
        return getBm3PaymentTypeRender();
      case BM3INQUIRYBASELAYOUTRENDER:
        return getBm3InquiryBaseLayoutRender();
      case REFLECTCONTRACTBUTTONRENDER:
        return getReflectContractButtonRender();
      case CNTRCTELECSPACER2RENDER:
        return getCntrctElecSpacer2Render();
      case OTHERCONTENTVIEWRENDER:
        return getOtherContentViewRender();
      case OTHERCONTENTRENDER:
        return getOtherContentRender();
      case CALCPROFITBUTTONRENDER:
        return getCalcProfitButtonRender();
      case SALESMONTHVIEWRENDER:
        return getSalesMonthViewRender();
      case SALESMONTHRENDER:
        return getSalesMonthRender();
      case BMRATEVIEWRENDER:
        return getBmRateViewRender();
      case BMRATERENDER:
        return getBmRateRender();
      case LEASECHARGEMONTHVIEWRENDER:
        return getLeaseChargeMonthViewRender();
      case LEASECHARGEMONTHRENDER:
        return getLeaseChargeMonthRender();
      case CONSTRUCTIONCHARGEVIEWRENDER:
        return getConstructionChargeViewRender();
      case CONSTRUCTIONCHARGERENDER:
        return getConstructionChargeRender();
      case ELECTRICITYAMTMONTHVIEWRENDER:
        return getElectricityAmtMonthViewRender();
      case ELECTRICITYAMTMONTHRENDER:
        return getElectricityAmtMonthRender();
      case ATTACHACTIONFLRNRENDER:
        return getAttachActionFlRNRender();
      case ACTPOBASECODE:
        return getActPoBaseCode();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case FULLNAME:
        setFullName((String)value);
        return;
      case BASECODE:
        setBaseCode((String)value);
        return;
      case BASENAME:
        setBaseName((String)value);
        return;
      case CURRENTDATE:
        setCurrentDate((Date)value);
        return;
      case ATTACHFILEUP:
        setAttachFileUp((String)value);
        return;
      case ATTACHFILEUPEXCERPT:
        setAttachFileUpExcerpt((String)value);
        return;
      case APPLYBUTTONRENDER:
        setApplyButtonRender((Boolean)value);
        return;
      case SUBMITBUTTONRENDER:
        setSubmitButtonRender((Boolean)value);
        return;
      case RETURNBUTTONRENDER:
        setReturnButtonRender((Boolean)value);
        return;
      case CONFIRMBUTTONRENDER:
        setConfirmButtonRender((Boolean)value);
        return;
      case REJECTBUTTONRENDER:
        setRejectButtonRender((Boolean)value);
        return;
      case APPROVEBUTTONRENDER:
        setApproveButtonRender((Boolean)value);
        return;
      case REQUESTBUTTONRENDER:
        setRequestButtonRender((Boolean)value);
        return;
      case APPLICATIONTYPEVIEWRENDER:
        setApplicationTypeViewRender((Boolean)value);
        return;
      case APPLICATIONTYPERENDER:
        setApplicationTypeRender((Boolean)value);
        return;
      case INSTALLACCTNUMBERVIEWRENDER:
        setInstallAcctNumberViewRender((Boolean)value);
        return;
      case INSTALLACCTNUMBER1RENDER:
        setInstallAcctNumber1Render((Boolean)value);
        return;
      case INSTALLACCTNUMBER2RENDER:
        setInstallAcctNumber2Render((Boolean)value);
        return;
      case INSTALLPARTYNAMEVIEWRENDER:
        setInstallPartyNameViewRender((Boolean)value);
        return;
      case INSTALLPARTYNAMERENDER:
        setInstallPartyNameRender((Boolean)value);
        return;
      case INSTALLPARTYNAMEALTVIEWRENDER:
        setInstallPartyNameAltViewRender((Boolean)value);
        return;
      case INSTALLPARTYNAMEALTRENDER:
        setInstallPartyNameAltRender((Boolean)value);
        return;
      case INSTALLNAMEVIEWRENDER:
        setInstallNameViewRender((Boolean)value);
        return;
      case INSTALLNAMERENDER:
        setInstallNameRender((Boolean)value);
        return;
      case INSTALLPOSTCDFVIEWRENDER:
        setInstallPostCdFViewRender((Boolean)value);
        return;
      case INSTALLPOSTCDFRENDER:
        setInstallPostCdFRender((Boolean)value);
        return;
      case INSTALLPOSTCDSVIEWRENDER:
        setInstallPostCdSViewRender((Boolean)value);
        return;
      case INSTALLPOSTCDSRENDER:
        setInstallPostCdSRender((Boolean)value);
        return;
      case INSTALLSTATEVIEWRENDER:
        setInstallStateViewRender((Boolean)value);
        return;
      case INSTALLSTATERENDER:
        setInstallStateRender((Boolean)value);
        return;
      case INSTALLCITYVIEWRENDER:
        setInstallCityViewRender((Boolean)value);
        return;
      case INSTALLCITYRENDER:
        setInstallCityRender((Boolean)value);
        return;
      case INSTALLADDRESS1VIEWRENDER:
        setInstallAddress1ViewRender((Boolean)value);
        return;
      case INSTALLADDRESS1RENDER:
        setInstallAddress1Render((Boolean)value);
        return;
      case INSTALLADDRESS2VIEWRENDER:
        setInstallAddress2ViewRender((Boolean)value);
        return;
      case INSTALLADDRESS2RENDER:
        setInstallAddress2Render((Boolean)value);
        return;
      case INSTALLADDRESSLINEVIEWRENDER:
        setInstallAddressLineViewRender((Boolean)value);
        return;
      case INSTALLADDRESSLINERENDER:
        setInstallAddressLineRender((Boolean)value);
        return;
      case BIZCONDTYPEVIEWRENDER:
        setBizCondTypeViewRender((Boolean)value);
        return;
      case BIZCONDTYPERENDER:
        setBizCondTypeRender((Boolean)value);
        return;
      case BUSINESSTYPEVIEWRENDER:
        setBusinessTypeViewRender((Boolean)value);
        return;
      case BUSINESSTYPERENDER:
        setBusinessTypeRender((Boolean)value);
        return;
      case INSTALLLOCATIONVIEWRENDER:
        setInstallLocationViewRender((Boolean)value);
        return;
      case INSTALLLOCATIONRENDER:
        setInstallLocationRender((Boolean)value);
        return;
      case EXTREFOPCLTYPEVIEWRENDER:
        setExtRefOpclTypeViewRender((Boolean)value);
        return;
      case EXTREFOPCLTYPERENDER:
        setExtRefOpclTypeRender((Boolean)value);
        return;
      case EMPLOYEENUMBERVIEWRENDER:
        setEmployeeNumberViewRender((Boolean)value);
        return;
      case EMPLOYEENUMBERRENDER:
        setEmployeeNumberRender((Boolean)value);
        return;
      case PUBLISHBASECODEVIEWRENDER:
        setPublishBaseCodeViewRender((Boolean)value);
        return;
      case PUBLISHBASECODERENDER:
        setPublishBaseCodeRender((Boolean)value);
        return;
      case INSTALLDATEREQUIREDVIEWRENDER:
        setInstallDateRequiredViewRender((Boolean)value);
        return;
      case INSTALLDATEREQUIREDRENDER:
        setInstallDateRequiredRender((Boolean)value);
        return;
      case INSTALLDATEVIEWRENDER:
        setInstallDateViewRender((Boolean)value);
        return;
      case INSTALLDATERENDER:
        setInstallDateRender((Boolean)value);
        return;
      case LEASECOMPANYVIEWRENDER:
        setLeaseCompanyViewRender((Boolean)value);
        return;
      case LEASECOMPANYRENDER:
        setLeaseCompanyRender((Boolean)value);
        return;
      case SAMEINSTALLACCTFLAGVIEWRENDER:
        setSameInstallAcctFlagViewRender((Boolean)value);
        return;
      case SAMEINSTALLACCTFLAGRENDER:
        setSameInstallAcctFlagRender((Boolean)value);
        return;
      case CONTRACTNUMBERVIEWRENDER:
        setContractNumberViewRender((Boolean)value);
        return;
      case CONTRACTNUMBER1RENDER:
        setContractNumber1Render((Boolean)value);
        return;
      case CONTRACTNUMBER2RENDER:
        setContractNumber2Render((Boolean)value);
        return;
      case CONTRACTNAMEVIEWRENDER:
        setContractNameViewRender((Boolean)value);
        return;
      case CONTRACTNAMERENDER:
        setContractNameRender((Boolean)value);
        return;
      case CONTRACTNAMEALTVIEWRENDER:
        setContractNameAltViewRender((Boolean)value);
        return;
      case CONTRACTNAMEALTRENDER:
        setContractNameAltRender((Boolean)value);
        return;
      case CONTRACTPOSTCDFVIEWRENDER:
        setContractPostCdFViewRender((Boolean)value);
        return;
      case CONTRACTPOSTCDFRENDER:
        setContractPostCdFRender((Boolean)value);
        return;
      case CONTRACTPOSTCDSVIEWRENDER:
        setContractPostCdSViewRender((Boolean)value);
        return;
      case CONTRACTPOSTCDSRENDER:
        setContractPostCdSRender((Boolean)value);
        return;
      case CONTRACTSTATEVIEWRENDER:
        setContractStateViewRender((Boolean)value);
        return;
      case CONTRACTSTATERENDER:
        setContractStateRender((Boolean)value);
        return;
      case CONTRACTCITYVIEWRENDER:
        setContractCityViewRender((Boolean)value);
        return;
      case CONTRACTCITYRENDER:
        setContractCityRender((Boolean)value);
        return;
      case CONTRACTADDRESS1VIEWRENDER:
        setContractAddress1ViewRender((Boolean)value);
        return;
      case CONTRACTADDRESS1RENDER:
        setContractAddress1Render((Boolean)value);
        return;
      case CONTRACTADDRESS2VIEWRENDER:
        setContractAddress2ViewRender((Boolean)value);
        return;
      case CONTRACTADDRESS2RENDER:
        setContractAddress2Render((Boolean)value);
        return;
      case CONTRACTADDRESSLINEVIEWRENDER:
        setContractAddressLineViewRender((Boolean)value);
        return;
      case CONTRACTADDRESSLINERENDER:
        setContractAddressLineRender((Boolean)value);
        return;
      case DELEGATENAMEVIEWRENDER:
        setDelegateNameViewRender((Boolean)value);
        return;
      case DELEGATENAMERENDER:
        setDelegateNameRender((Boolean)value);
        return;
      case NEWOLDTYPEVIEWRENDER:
        setNewoldTypeViewRender((Boolean)value);
        return;
      case NEWOLDTYPERENDER:
        setNewoldTypeRender((Boolean)value);
        return;
      case SELENUMBERVIEWRENDER:
        setSeleNumberViewRender((Boolean)value);
        return;
      case SELENUMBERRENDER:
        setSeleNumberRender((Boolean)value);
        return;
      case MAKERCODEVIEWRENDER:
        setMakerCodeViewRender((Boolean)value);
        return;
      case MAKERCODERENDER:
        setMakerCodeRender((Boolean)value);
        return;
      case STANDARDTYPEVIEWRENDER:
        setStandardTypeViewRender((Boolean)value);
        return;
      case STANDARDTYPERENDER:
        setStandardTypeRender((Boolean)value);
        return;
      case VDINFO3REQUIREDLAYOUTRENDER:
        setVdInfo3RequiredLayoutRender((Boolean)value);
        return;
      case VDINFO3LAYOUTRENDER:
        setVdInfo3LayoutRender((Boolean)value);
        return;
      case UNNUMBERVIEWRENDER:
        setUnNumberViewRender((Boolean)value);
        return;
      case UNNUMBERRENDER:
        setUnNumberRender((Boolean)value);
        return;
      case CONDBIZTYPEVIEWRENDER:
        setCondBizTypeViewRender((Boolean)value);
        return;
      case CONDBIZTYPERENDER:
        setCondBizTypeRender((Boolean)value);
        return;
      case SALESCONDITIONHDRRNRENDER:
        setSalesConditionHdrRNRender((Boolean)value);
        return;
      case SCBM2GRPRENDER:
        setScBm2GrpRender((Boolean)value);
        return;
      case SCCONTRIBUTEGRPRENDER:
        setScContributeGrpRender((Boolean)value);
        return;
      case SCACTIONFLRNRENDER:
        setScActionFlRNRender((Boolean)value);
        return;
      case SCTABLEFOOTERRENDER:
        setScTableFooterRender((Boolean)value);
        return;
      case CONTAINERCONDITIONHDRRNRENDER:
        setContainerConditionHdrRNRender((Boolean)value);
        return;
      case ALLCONTAINERTYPEVIEWRENDER:
        setAllContainerTypeViewRender((Boolean)value);
        return;
      case ALLCONTAINERTYPERENDER:
        setAllContainerTypeRender((Boolean)value);
        return;
      case ALLCCADVTBLRNRENDER:
        setAllCcAdvTblRNRender((Boolean)value);
        return;
      case ALLCCBM2GRPRENDER:
        setAllCcBm2GrpRender((Boolean)value);
        return;
      case ALLCCCONTRIBUTEGRPRENDER:
        setAllCcContributeGrpRender((Boolean)value);
        return;
      case ALLCCACTIONFLRNRENDER:
        setAllCcActionFlRNRender((Boolean)value);
        return;
      case SELCCADVTBLRNRENDER:
        setSelCcAdvTblRNRender((Boolean)value);
        return;
      case SELCCBM2GRPRENDER:
        setSelCcBm2GrpRender((Boolean)value);
        return;
      case SELCCCONTRIBUTEGRPRENDER:
        setSelCcContributeGrpRender((Boolean)value);
        return;
      case SELCCACTIONFLRNRENDER:
        setSelCcActionFlRNRender((Boolean)value);
        return;
      case CONTRACTYEARDATEVIEWRENDER:
        setContractYearDateViewRender((Boolean)value);
        return;
      case CONTRACTYEARDATERENDER:
        setContractYearDateRender((Boolean)value);
        return;
      case INSTALLSUPPORTAMTVIEWRENDER:
        setInstallSupportAmtViewRender((Boolean)value);
        return;
      case INSTALLSUPPORTAMTRENDER:
        setInstallSupportAmtRender((Boolean)value);
        return;
      case INSTALLSUPPORTAMT2VIEWRENDER:
        setInstallSupportAmt2ViewRender((Boolean)value);
        return;
      case INSTALLSUPPORTAMT2RENDER:
        setInstallSupportAmt2Render((Boolean)value);
        return;
      case PAYMENTCYCLEVIEWRENDER:
        setPaymentCycleViewRender((Boolean)value);
        return;
      case PAYMENTCYCLERENDER:
        setPaymentCycleRender((Boolean)value);
        return;
      case ELECSTARTREQUIREDLABELRENDER:
        setElecStartRequiredLabelRender((Boolean)value);
        return;
      case ELECSTARTLABELRENDER:
        setElecStartLabelRender((Boolean)value);
        return;
      case ELECTRICITYTYPEVIEWRENDER:
        setElectricityTypeViewRender((Boolean)value);
        return;
      case ELECTRICITYTYPERENDER:
        setElectricityTypeRender((Boolean)value);
        return;
      case ELECTRICITYAMOUNTVIEWRENDER:
        setElectricityAmountViewRender((Boolean)value);
        return;
      case ELECTRICITYAMOUNTRENDER:
        setElectricityAmountRender((Boolean)value);
        return;
      case ELECAMOUNTLABELRENDER:
        setElecAmountLabelRender((Boolean)value);
        return;
      case CONDITIONREASONVIEWRENDER:
        setConditionReasonViewRender((Boolean)value);
        return;
      case CONDITIONREASONRENDER:
        setConditionReasonRender((Boolean)value);
        return;
      case BM1INFOHDRRNRENDER:
        setBm1InfoHdrRNRender((Boolean)value);
        return;
      case BM1SENDTYPEVIEWRENDER:
        setBm1SendTypeViewRender((Boolean)value);
        return;
      case BM1SENDTYPERENDER:
        setBm1SendTypeRender((Boolean)value);
        return;
      case BM1VENDORNUMBERVIEWRENDER:
        setBm1VendorNumberViewRender((Boolean)value);
        return;
      case BM1VENDORNUMBER1RENDER:
        setBm1VendorNumber1Render((Boolean)value);
        return;
      case BM1VENDORNUMBER2RENDER:
        setBm1VendorNumber2Render((Boolean)value);
        return;
      case BM1VENDORNAMEVIEWRENDER:
        setBm1VendorNameViewRender((Boolean)value);
        return;
      case BM1VENDORNAMERENDER:
        setBm1VendorNameRender((Boolean)value);
        return;
      case BM1VENDORNAMEALTVIEWRENDER:
        setBm1VendorNameAltViewRender((Boolean)value);
        return;
      case BM1VENDORNAMEALTRENDER:
        setBm1VendorNameAltRender((Boolean)value);
        return;
      case BM1TRANSFERTYPELAYOUTRENDER:
        setBm1TransferTypeLayoutRender((Boolean)value);
        return;
      case BM1TRANSFERTYPEVIEWRENDER:
        setBm1TransferTypeViewRender((Boolean)value);
        return;
      case BM1TRANSFERTYPERENDER:
        setBm1TransferTypeRender((Boolean)value);
        return;
      case BM1PAYMENTTYPEVIEWRENDER:
        setBm1PaymentTypeViewRender((Boolean)value);
        return;
      case BM1PAYMENTTYPERENDER:
        setBm1PaymentTypeRender((Boolean)value);
        return;
      case BM1INQUIRYBASELAYOUTRENDER:
        setBm1InquiryBaseLayoutRender((Boolean)value);
        return;
      case BM1POSTALCODELAYOUTRENDER:
        setBm1PostalCodeLayoutRender((Boolean)value);
        return;
      case BM1POSTCDFVIEWRENDER:
        setBm1PostCdFViewRender((Boolean)value);
        return;
      case BM1POSTCDFRENDER:
        setBm1PostCdFRender((Boolean)value);
        return;
      case BM1POSTCDSVIEWRENDER:
        setBm1PostCdSViewRender((Boolean)value);
        return;
      case BM1POSTCDSRENDER:
        setBm1PostCdSRender((Boolean)value);
        return;
      case BM1STATEVIEWRENDER:
        setBm1StateViewRender((Boolean)value);
        return;
      case BM1STATERENDER:
        setBm1StateRender((Boolean)value);
        return;
      case BM1CITYVIEWRENDER:
        setBm1CityViewRender((Boolean)value);
        return;
      case BM1CITYRENDER:
        setBm1CityRender((Boolean)value);
        return;
      case BM1ADDRESS1VIEWRENDER:
        setBm1Address1ViewRender((Boolean)value);
        return;
      case BM1ADDRESS1RENDER:
        setBm1Address1Render((Boolean)value);
        return;
      case BM1ADDRESS2VIEWRENDER:
        setBm1Address2ViewRender((Boolean)value);
        return;
      case BM1ADDRESS2RENDER:
        setBm1Address2Render((Boolean)value);
        return;
      case BM1ADDRESSLINEVIEWRENDER:
        setBm1AddressLineViewRender((Boolean)value);
        return;
      case BM1ADDRESSLINERENDER:
        setBm1AddressLineRender((Boolean)value);
        return;
      case BM2INFOHDRRNRENDER:
        setBm2InfoHdrRNRender((Boolean)value);
        return;
      case CONTRIBUTEINFOHDRRNRENDER:
        setContributeInfoHdrRNRender((Boolean)value);
        return;
      case BM2VENDORNUMBERVIEWRENDER:
        setBm2VendorNumberViewRender((Boolean)value);
        return;
      case BM2VENDORNUMBER1RENDER:
        setBm2VendorNumber1Render((Boolean)value);
        return;
      case BM2VENDORNUMBER2RENDER:
        setBm2VendorNumber2Render((Boolean)value);
        return;
      case BM2VENDORNAMEVIEWRENDER:
        setBm2VendorNameViewRender((Boolean)value);
        return;
      case BM2VENDORNAMERENDER:
        setBm2VendorNameRender((Boolean)value);
        return;
      case BM2VENDORNAMEALTVIEWRENDER:
        setBm2VendorNameAltViewRender((Boolean)value);
        return;
      case BM2VENDORNAMEALTRENDER:
        setBm2VendorNameAltRender((Boolean)value);
        return;
      case BM2POSTALCODELAYOUTRENDER:
        setBm2PostalCodeLayoutRender((Boolean)value);
        return;
      case BM2POSTCDFVIEWRENDER:
        setBm2PostCdFViewRender((Boolean)value);
        return;
      case BM2POSTCDFRENDER:
        setBm2PostCdFRender((Boolean)value);
        return;
      case BM2POSTCDSVIEWRENDER:
        setBm2PostCdSViewRender((Boolean)value);
        return;
      case BM2POSTCDSRENDER:
        setBm2PostCdSRender((Boolean)value);
        return;
      case BM2STATEVIEWRENDER:
        setBm2StateViewRender((Boolean)value);
        return;
      case BM2STATERENDER:
        setBm2StateRender((Boolean)value);
        return;
      case BM2CITYVIEWRENDER:
        setBm2CityViewRender((Boolean)value);
        return;
      case BM2CITYRENDER:
        setBm2CityRender((Boolean)value);
        return;
      case BM2ADDRESS1VIEWRENDER:
        setBm2Address1ViewRender((Boolean)value);
        return;
      case BM2ADDRESS1RENDER:
        setBm2Address1Render((Boolean)value);
        return;
      case BM2ADDRESS2VIEWRENDER:
        setBm2Address2ViewRender((Boolean)value);
        return;
      case BM2ADDRESS2RENDER:
        setBm2Address2Render((Boolean)value);
        return;
      case BM2ADDRESSLINEVIEWRENDER:
        setBm2AddressLineViewRender((Boolean)value);
        return;
      case BM2ADDRESSLINERENDER:
        setBm2AddressLineRender((Boolean)value);
        return;
      case BM2TRANSFERTYPELAYOUTRENDER:
        setBm2TransferTypeLayoutRender((Boolean)value);
        return;
      case BM2TRANSFERTYPEVIEWRENDER:
        setBm2TransferTypeViewRender((Boolean)value);
        return;
      case BM2TRANSFERTYPERENDER:
        setBm2TransferTypeRender((Boolean)value);
        return;
      case BM2PAYMENTTYPEVIEWRENDER:
        setBm2PaymentTypeViewRender((Boolean)value);
        return;
      case BM2PAYMENTTYPERENDER:
        setBm2PaymentTypeRender((Boolean)value);
        return;
      case BM2INQUIRYBASELAYOUTRENDER:
        setBm2InquiryBaseLayoutRender((Boolean)value);
        return;
      case BM3INFOHDRRNRENDER:
        setBm3InfoHdrRNRender((Boolean)value);
        return;
      case BM3VENDORNUMBERVIEWRENDER:
        setBm3VendorNumberViewRender((Boolean)value);
        return;
      case BM3VENDORNUMBER1RENDER:
        setBm3VendorNumber1Render((Boolean)value);
        return;
      case BM3VENDORNUMBER2RENDER:
        setBm3VendorNumber2Render((Boolean)value);
        return;
      case BM3VENDORNAMEVIEWRENDER:
        setBm3VendorNameViewRender((Boolean)value);
        return;
      case BM3VENDORNAMERENDER:
        setBm3VendorNameRender((Boolean)value);
        return;
      case BM3VENDORNAMEALTVIEWRENDER:
        setBm3VendorNameAltViewRender((Boolean)value);
        return;
      case BM3VENDORNAMEALTRENDER:
        setBm3VendorNameAltRender((Boolean)value);
        return;
      case BM3POSTALCODELAYOUTRENDER:
        setBm3PostalCodeLayoutRender((Boolean)value);
        return;
      case BM3POSTCDFVIEWRENDER:
        setBm3PostCdFViewRender((Boolean)value);
        return;
      case BM3POSTCDFRENDER:
        setBm3PostCdFRender((Boolean)value);
        return;
      case BM3POSTCDSVIEWRENDER:
        setBm3PostCdSViewRender((Boolean)value);
        return;
      case BM3POSTCDSRENDER:
        setBm3PostCdSRender((Boolean)value);
        return;
      case BM3STATEVIEWRENDER:
        setBm3StateViewRender((Boolean)value);
        return;
      case BM3STATERENDER:
        setBm3StateRender((Boolean)value);
        return;
      case BM3CITYVIEWRENDER:
        setBm3CityViewRender((Boolean)value);
        return;
      case BM3CITYRENDER:
        setBm3CityRender((Boolean)value);
        return;
      case BM3ADDRESS1VIEWRENDER:
        setBm3Address1ViewRender((Boolean)value);
        return;
      case BM3ADDRESS1RENDER:
        setBm3Address1Render((Boolean)value);
        return;
      case BM3ADDRESS2VIEWRENDER:
        setBm3Address2ViewRender((Boolean)value);
        return;
      case BM3ADDRESS2RENDER:
        setBm3Address2Render((Boolean)value);
        return;
      case BM3ADDRESSLINEVIEWRENDER:
        setBm3AddressLineViewRender((Boolean)value);
        return;
      case BM3ADDRESSLINERENDER:
        setBm3AddressLineRender((Boolean)value);
        return;
      case BM3TRANSFERTYPELAYOUTRENDER:
        setBm3TransferTypeLayoutRender((Boolean)value);
        return;
      case BM3TRANSFERTYPEVIEWRENDER:
        setBm3TransferTypeViewRender((Boolean)value);
        return;
      case BM3TRANSFERTYPERENDER:
        setBm3TransferTypeRender((Boolean)value);
        return;
      case BM3PAYMENTTYPEVIEWRENDER:
        setBm3PaymentTypeViewRender((Boolean)value);
        return;
      case BM3PAYMENTTYPERENDER:
        setBm3PaymentTypeRender((Boolean)value);
        return;
      case BM3INQUIRYBASELAYOUTRENDER:
        setBm3InquiryBaseLayoutRender((Boolean)value);
        return;
      case REFLECTCONTRACTBUTTONRENDER:
        setReflectContractButtonRender((Boolean)value);
        return;
      case CNTRCTELECSPACER2RENDER:
        setCntrctElecSpacer2Render((Boolean)value);
        return;
      case OTHERCONTENTVIEWRENDER:
        setOtherContentViewRender((Boolean)value);
        return;
      case OTHERCONTENTRENDER:
        setOtherContentRender((Boolean)value);
        return;
      case CALCPROFITBUTTONRENDER:
        setCalcProfitButtonRender((Boolean)value);
        return;
      case SALESMONTHVIEWRENDER:
        setSalesMonthViewRender((Boolean)value);
        return;
      case SALESMONTHRENDER:
        setSalesMonthRender((Boolean)value);
        return;
      case BMRATEVIEWRENDER:
        setBmRateViewRender((Boolean)value);
        return;
      case BMRATERENDER:
        setBmRateRender((Boolean)value);
        return;
      case LEASECHARGEMONTHVIEWRENDER:
        setLeaseChargeMonthViewRender((Boolean)value);
        return;
      case LEASECHARGEMONTHRENDER:
        setLeaseChargeMonthRender((Boolean)value);
        return;
      case CONSTRUCTIONCHARGEVIEWRENDER:
        setConstructionChargeViewRender((Boolean)value);
        return;
      case CONSTRUCTIONCHARGERENDER:
        setConstructionChargeRender((Boolean)value);
        return;
      case ELECTRICITYAMTMONTHVIEWRENDER:
        setElectricityAmtMonthViewRender((Boolean)value);
        return;
      case ELECTRICITYAMTMONTHRENDER:
        setElectricityAmtMonthRender((Boolean)value);
        return;
      case ATTACHACTIONFLRNRENDER:
        setAttachActionFlRNRender((Boolean)value);
        return;
      case ACTPOBASECODE:
        setActPoBaseCode((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AttachFileUp
   */
  public String getAttachFileUp()
  {
    return (String)getAttributeInternal(ATTACHFILEUP);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AttachFileUp
   */
  public void setAttachFileUp(String value)
  {
    setAttributeInternal(ATTACHFILEUP, value);
  }

















  /**
   * 
   * Gets the attribute value for the calculated attribute ApplyButtonRender
   */
  public Boolean getApplyButtonRender()
  {
    return (Boolean)getAttributeInternal(APPLYBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApplyButtonRender
   */
  public void setApplyButtonRender(Boolean value)
  {
    setAttributeInternal(APPLYBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SubmitButtonRender
   */
  public Boolean getSubmitButtonRender()
  {
    return (Boolean)getAttributeInternal(SUBMITBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SubmitButtonRender
   */
  public void setSubmitButtonRender(Boolean value)
  {
    setAttributeInternal(SUBMITBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ReturnButtonRender
   */
  public Boolean getReturnButtonRender()
  {
    return (Boolean)getAttributeInternal(RETURNBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ReturnButtonRender
   */
  public void setReturnButtonRender(Boolean value)
  {
    setAttributeInternal(RETURNBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ConfirmButtonRender
   */
  public Boolean getConfirmButtonRender()
  {
    return (Boolean)getAttributeInternal(CONFIRMBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ConfirmButtonRender
   */
  public void setConfirmButtonRender(Boolean value)
  {
    setAttributeInternal(CONFIRMBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RejectButtonRender
   */
  public Boolean getRejectButtonRender()
  {
    return (Boolean)getAttributeInternal(REJECTBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RejectButtonRender
   */
  public void setRejectButtonRender(Boolean value)
  {
    setAttributeInternal(REJECTBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApproveButtonRender
   */
  public Boolean getApproveButtonRender()
  {
    return (Boolean)getAttributeInternal(APPROVEBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApproveButtonRender
   */
  public void setApproveButtonRender(Boolean value)
  {
    setAttributeInternal(APPROVEBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RequestButtonRender
   */
  public Boolean getRequestButtonRender()
  {
    return (Boolean)getAttributeInternal(REQUESTBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RequestButtonRender
   */
  public void setRequestButtonRender(Boolean value)
  {
    setAttributeInternal(REQUESTBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApplicationTypeViewRender
   */
  public Boolean getApplicationTypeViewRender()
  {
    return (Boolean)getAttributeInternal(APPLICATIONTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApplicationTypeViewRender
   */
  public void setApplicationTypeViewRender(Boolean value)
  {
    setAttributeInternal(APPLICATIONTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApplicationTypeRender
   */
  public Boolean getApplicationTypeRender()
  {
    return (Boolean)getAttributeInternal(APPLICATIONTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApplicationTypeRender
   */
  public void setApplicationTypeRender(Boolean value)
  {
    setAttributeInternal(APPLICATIONTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAcctNumberViewRender
   */
  public Boolean getInstallAcctNumberViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLACCTNUMBERVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAcctNumberViewRender
   */
  public void setInstallAcctNumberViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLACCTNUMBERVIEWRENDER, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute InstallPartyNameViewRender
   */
  public Boolean getInstallPartyNameViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLPARTYNAMEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallPartyNameViewRender
   */
  public void setInstallPartyNameViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLPARTYNAMEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallPartyNameRender
   */
  public Boolean getInstallPartyNameRender()
  {
    return (Boolean)getAttributeInternal(INSTALLPARTYNAMERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallPartyNameRender
   */
  public void setInstallPartyNameRender(Boolean value)
  {
    setAttributeInternal(INSTALLPARTYNAMERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallPartyNameAltViewRender
   */
  public Boolean getInstallPartyNameAltViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLPARTYNAMEALTVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallPartyNameAltViewRender
   */
  public void setInstallPartyNameAltViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLPARTYNAMEALTVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallPartyNameAltRender
   */
  public Boolean getInstallPartyNameAltRender()
  {
    return (Boolean)getAttributeInternal(INSTALLPARTYNAMEALTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallPartyNameAltRender
   */
  public void setInstallPartyNameAltRender(Boolean value)
  {
    setAttributeInternal(INSTALLPARTYNAMEALTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallNameViewRender
   */
  public Boolean getInstallNameViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLNAMEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallNameViewRender
   */
  public void setInstallNameViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLNAMEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallNameRender
   */
  public Boolean getInstallNameRender()
  {
    return (Boolean)getAttributeInternal(INSTALLNAMERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallNameRender
   */
  public void setInstallNameRender(Boolean value)
  {
    setAttributeInternal(INSTALLNAMERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallPostCdFViewRender
   */
  public Boolean getInstallPostCdFViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLPOSTCDFVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallPostCdFViewRender
   */
  public void setInstallPostCdFViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLPOSTCDFVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallPostCdFRender
   */
  public Boolean getInstallPostCdFRender()
  {
    return (Boolean)getAttributeInternal(INSTALLPOSTCDFRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallPostCdFRender
   */
  public void setInstallPostCdFRender(Boolean value)
  {
    setAttributeInternal(INSTALLPOSTCDFRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallPostCdSViewRender
   */
  public Boolean getInstallPostCdSViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLPOSTCDSVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallPostCdSViewRender
   */
  public void setInstallPostCdSViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLPOSTCDSVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallPostCdSRender
   */
  public Boolean getInstallPostCdSRender()
  {
    return (Boolean)getAttributeInternal(INSTALLPOSTCDSRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallPostCdSRender
   */
  public void setInstallPostCdSRender(Boolean value)
  {
    setAttributeInternal(INSTALLPOSTCDSRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallStateViewRender
   */
  public Boolean getInstallStateViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSTATEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallStateViewRender
   */
  public void setInstallStateViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLSTATEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallStateRender
   */
  public Boolean getInstallStateRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSTATERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallStateRender
   */
  public void setInstallStateRender(Boolean value)
  {
    setAttributeInternal(INSTALLSTATERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallCityViewRender
   */
  public Boolean getInstallCityViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLCITYVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallCityViewRender
   */
  public void setInstallCityViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLCITYVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallCityRender
   */
  public Boolean getInstallCityRender()
  {
    return (Boolean)getAttributeInternal(INSTALLCITYRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallCityRender
   */
  public void setInstallCityRender(Boolean value)
  {
    setAttributeInternal(INSTALLCITYRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAddress1ViewRender
   */
  public Boolean getInstallAddress1ViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLADDRESS1VIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAddress1ViewRender
   */
  public void setInstallAddress1ViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLADDRESS1VIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAddress1Render
   */
  public Boolean getInstallAddress1Render()
  {
    return (Boolean)getAttributeInternal(INSTALLADDRESS1RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAddress1Render
   */
  public void setInstallAddress1Render(Boolean value)
  {
    setAttributeInternal(INSTALLADDRESS1RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAddress2ViewRender
   */
  public Boolean getInstallAddress2ViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLADDRESS2VIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAddress2ViewRender
   */
  public void setInstallAddress2ViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLADDRESS2VIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAddress2Render
   */
  public Boolean getInstallAddress2Render()
  {
    return (Boolean)getAttributeInternal(INSTALLADDRESS2RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAddress2Render
   */
  public void setInstallAddress2Render(Boolean value)
  {
    setAttributeInternal(INSTALLADDRESS2RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAddressLineViewRender
   */
  public Boolean getInstallAddressLineViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLADDRESSLINEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAddressLineViewRender
   */
  public void setInstallAddressLineViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLADDRESSLINEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAddressLineRender
   */
  public Boolean getInstallAddressLineRender()
  {
    return (Boolean)getAttributeInternal(INSTALLADDRESSLINERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAddressLineRender
   */
  public void setInstallAddressLineRender(Boolean value)
  {
    setAttributeInternal(INSTALLADDRESSLINERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BizCondTypeViewRender
   */
  public Boolean getBizCondTypeViewRender()
  {
    return (Boolean)getAttributeInternal(BIZCONDTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BizCondTypeViewRender
   */
  public void setBizCondTypeViewRender(Boolean value)
  {
    setAttributeInternal(BIZCONDTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BizCondTypeRender
   */
  public Boolean getBizCondTypeRender()
  {
    return (Boolean)getAttributeInternal(BIZCONDTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BizCondTypeRender
   */
  public void setBizCondTypeRender(Boolean value)
  {
    setAttributeInternal(BIZCONDTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BusinessTypeViewRender
   */
  public Boolean getBusinessTypeViewRender()
  {
    return (Boolean)getAttributeInternal(BUSINESSTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BusinessTypeViewRender
   */
  public void setBusinessTypeViewRender(Boolean value)
  {
    setAttributeInternal(BUSINESSTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BusinessTypeRender
   */
  public Boolean getBusinessTypeRender()
  {
    return (Boolean)getAttributeInternal(BUSINESSTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BusinessTypeRender
   */
  public void setBusinessTypeRender(Boolean value)
  {
    setAttributeInternal(BUSINESSTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallLocationViewRender
   */
  public Boolean getInstallLocationViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLLOCATIONVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallLocationViewRender
   */
  public void setInstallLocationViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLLOCATIONVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallLocationRender
   */
  public Boolean getInstallLocationRender()
  {
    return (Boolean)getAttributeInternal(INSTALLLOCATIONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallLocationRender
   */
  public void setInstallLocationRender(Boolean value)
  {
    setAttributeInternal(INSTALLLOCATIONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtRefOpclTypeViewRender
   */
  public Boolean getExtRefOpclTypeViewRender()
  {
    return (Boolean)getAttributeInternal(EXTREFOPCLTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtRefOpclTypeViewRender
   */
  public void setExtRefOpclTypeViewRender(Boolean value)
  {
    setAttributeInternal(EXTREFOPCLTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtRefOpclTypeRender
   */
  public Boolean getExtRefOpclTypeRender()
  {
    return (Boolean)getAttributeInternal(EXTREFOPCLTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtRefOpclTypeRender
   */
  public void setExtRefOpclTypeRender(Boolean value)
  {
    setAttributeInternal(EXTREFOPCLTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmployeeNumberViewRender
   */
  public Boolean getEmployeeNumberViewRender()
  {
    return (Boolean)getAttributeInternal(EMPLOYEENUMBERVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmployeeNumberViewRender
   */
  public void setEmployeeNumberViewRender(Boolean value)
  {
    setAttributeInternal(EMPLOYEENUMBERVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmployeeNumberRender
   */
  public Boolean getEmployeeNumberRender()
  {
    return (Boolean)getAttributeInternal(EMPLOYEENUMBERRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmployeeNumberRender
   */
  public void setEmployeeNumberRender(Boolean value)
  {
    setAttributeInternal(EMPLOYEENUMBERRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PublishBaseCodeViewRender
   */
  public Boolean getPublishBaseCodeViewRender()
  {
    return (Boolean)getAttributeInternal(PUBLISHBASECODEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PublishBaseCodeViewRender
   */
  public void setPublishBaseCodeViewRender(Boolean value)
  {
    setAttributeInternal(PUBLISHBASECODEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PublishBaseCodeRender
   */
  public Boolean getPublishBaseCodeRender()
  {
    return (Boolean)getAttributeInternal(PUBLISHBASECODERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PublishBaseCodeRender
   */
  public void setPublishBaseCodeRender(Boolean value)
  {
    setAttributeInternal(PUBLISHBASECODERENDER, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute InstallDateRender
   */
  public Boolean getInstallDateRender()
  {
    return (Boolean)getAttributeInternal(INSTALLDATERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallDateRender
   */
  public void setInstallDateRender(Boolean value)
  {
    setAttributeInternal(INSTALLDATERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LeaseCompanyViewRender
   */
  public Boolean getLeaseCompanyViewRender()
  {
    return (Boolean)getAttributeInternal(LEASECOMPANYVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeaseCompanyViewRender
   */
  public void setLeaseCompanyViewRender(Boolean value)
  {
    setAttributeInternal(LEASECOMPANYVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LeaseCompanyRender
   */
  public Boolean getLeaseCompanyRender()
  {
    return (Boolean)getAttributeInternal(LEASECOMPANYRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeaseCompanyRender
   */
  public void setLeaseCompanyRender(Boolean value)
  {
    setAttributeInternal(LEASECOMPANYRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SameInstallAcctFlagViewRender
   */
  public Boolean getSameInstallAcctFlagViewRender()
  {
    return (Boolean)getAttributeInternal(SAMEINSTALLACCTFLAGVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SameInstallAcctFlagViewRender
   */
  public void setSameInstallAcctFlagViewRender(Boolean value)
  {
    setAttributeInternal(SAMEINSTALLACCTFLAGVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SameInstallAcctFlagRender
   */
  public Boolean getSameInstallAcctFlagRender()
  {
    return (Boolean)getAttributeInternal(SAMEINSTALLACCTFLAGRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SameInstallAcctFlagRender
   */
  public void setSameInstallAcctFlagRender(Boolean value)
  {
    setAttributeInternal(SAMEINSTALLACCTFLAGRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractNumberViewRender
   */
  public Boolean getContractNumberViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTNUMBERVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractNumberViewRender
   */
  public void setContractNumberViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTNUMBERVIEWRENDER, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute ContractNameViewRender
   */
  public Boolean getContractNameViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTNAMEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractNameViewRender
   */
  public void setContractNameViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTNAMEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractNameRender
   */
  public Boolean getContractNameRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTNAMERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractNameRender
   */
  public void setContractNameRender(Boolean value)
  {
    setAttributeInternal(CONTRACTNAMERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractNameAltViewRender
   */
  public Boolean getContractNameAltViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTNAMEALTVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractNameAltViewRender
   */
  public void setContractNameAltViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTNAMEALTVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractNameAltRender
   */
  public Boolean getContractNameAltRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTNAMEALTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractNameAltRender
   */
  public void setContractNameAltRender(Boolean value)
  {
    setAttributeInternal(CONTRACTNAMEALTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractPostCdFViewRender
   */
  public Boolean getContractPostCdFViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTPOSTCDFVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractPostCdFViewRender
   */
  public void setContractPostCdFViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTPOSTCDFVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractPostCdFRender
   */
  public Boolean getContractPostCdFRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTPOSTCDFRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractPostCdFRender
   */
  public void setContractPostCdFRender(Boolean value)
  {
    setAttributeInternal(CONTRACTPOSTCDFRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractPostCdSViewRender
   */
  public Boolean getContractPostCdSViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTPOSTCDSVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractPostCdSViewRender
   */
  public void setContractPostCdSViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTPOSTCDSVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractPostCdSRender
   */
  public Boolean getContractPostCdSRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTPOSTCDSRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractPostCdSRender
   */
  public void setContractPostCdSRender(Boolean value)
  {
    setAttributeInternal(CONTRACTPOSTCDSRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractStateViewRender
   */
  public Boolean getContractStateViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTSTATEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractStateViewRender
   */
  public void setContractStateViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTSTATEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractStateRender
   */
  public Boolean getContractStateRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTSTATERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractStateRender
   */
  public void setContractStateRender(Boolean value)
  {
    setAttributeInternal(CONTRACTSTATERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractCityViewRender
   */
  public Boolean getContractCityViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTCITYVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractCityViewRender
   */
  public void setContractCityViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTCITYVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractCityRender
   */
  public Boolean getContractCityRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTCITYRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractCityRender
   */
  public void setContractCityRender(Boolean value)
  {
    setAttributeInternal(CONTRACTCITYRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractAddress1ViewRender
   */
  public Boolean getContractAddress1ViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTADDRESS1VIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractAddress1ViewRender
   */
  public void setContractAddress1ViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTADDRESS1VIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractAddress1Render
   */
  public Boolean getContractAddress1Render()
  {
    return (Boolean)getAttributeInternal(CONTRACTADDRESS1RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractAddress1Render
   */
  public void setContractAddress1Render(Boolean value)
  {
    setAttributeInternal(CONTRACTADDRESS1RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractAddress2ViewRender
   */
  public Boolean getContractAddress2ViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTADDRESS2VIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractAddress2ViewRender
   */
  public void setContractAddress2ViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTADDRESS2VIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractAddress2Render
   */
  public Boolean getContractAddress2Render()
  {
    return (Boolean)getAttributeInternal(CONTRACTADDRESS2RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractAddress2Render
   */
  public void setContractAddress2Render(Boolean value)
  {
    setAttributeInternal(CONTRACTADDRESS2RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractAddressLineViewRender
   */
  public Boolean getContractAddressLineViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTADDRESSLINEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractAddressLineViewRender
   */
  public void setContractAddressLineViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTADDRESSLINEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractAddressLineRender
   */
  public Boolean getContractAddressLineRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTADDRESSLINERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractAddressLineRender
   */
  public void setContractAddressLineRender(Boolean value)
  {
    setAttributeInternal(CONTRACTADDRESSLINERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DelegateNameViewRender
   */
  public Boolean getDelegateNameViewRender()
  {
    return (Boolean)getAttributeInternal(DELEGATENAMEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DelegateNameViewRender
   */
  public void setDelegateNameViewRender(Boolean value)
  {
    setAttributeInternal(DELEGATENAMEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DelegateNameRender
   */
  public Boolean getDelegateNameRender()
  {
    return (Boolean)getAttributeInternal(DELEGATENAMERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DelegateNameRender
   */
  public void setDelegateNameRender(Boolean value)
  {
    setAttributeInternal(DELEGATENAMERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NewoldTypeViewRender
   */
  public Boolean getNewoldTypeViewRender()
  {
    return (Boolean)getAttributeInternal(NEWOLDTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NewoldTypeViewRender
   */
  public void setNewoldTypeViewRender(Boolean value)
  {
    setAttributeInternal(NEWOLDTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NewoldTypeRender
   */
  public Boolean getNewoldTypeRender()
  {
    return (Boolean)getAttributeInternal(NEWOLDTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NewoldTypeRender
   */
  public void setNewoldTypeRender(Boolean value)
  {
    setAttributeInternal(NEWOLDTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SeleNumberViewRender
   */
  public Boolean getSeleNumberViewRender()
  {
    return (Boolean)getAttributeInternal(SELENUMBERVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SeleNumberViewRender
   */
  public void setSeleNumberViewRender(Boolean value)
  {
    setAttributeInternal(SELENUMBERVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SeleNumberRender
   */
  public Boolean getSeleNumberRender()
  {
    return (Boolean)getAttributeInternal(SELENUMBERRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SeleNumberRender
   */
  public void setSeleNumberRender(Boolean value)
  {
    setAttributeInternal(SELENUMBERRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MakerCodeViewRender
   */
  public Boolean getMakerCodeViewRender()
  {
    return (Boolean)getAttributeInternal(MAKERCODEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MakerCodeViewRender
   */
  public void setMakerCodeViewRender(Boolean value)
  {
    setAttributeInternal(MAKERCODEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MakerCodeRender
   */
  public Boolean getMakerCodeRender()
  {
    return (Boolean)getAttributeInternal(MAKERCODERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MakerCodeRender
   */
  public void setMakerCodeRender(Boolean value)
  {
    setAttributeInternal(MAKERCODERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StandardTypeViewRender
   */
  public Boolean getStandardTypeViewRender()
  {
    return (Boolean)getAttributeInternal(STANDARDTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StandardTypeViewRender
   */
  public void setStandardTypeViewRender(Boolean value)
  {
    setAttributeInternal(STANDARDTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StandardTypeRender
   */
  public Boolean getStandardTypeRender()
  {
    return (Boolean)getAttributeInternal(STANDARDTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StandardTypeRender
   */
  public void setStandardTypeRender(Boolean value)
  {
    setAttributeInternal(STANDARDTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UnNumberViewRender
   */
  public Boolean getUnNumberViewRender()
  {
    return (Boolean)getAttributeInternal(UNNUMBERVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UnNumberViewRender
   */
  public void setUnNumberViewRender(Boolean value)
  {
    setAttributeInternal(UNNUMBERVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UnNumberRender
   */
  public Boolean getUnNumberRender()
  {
    return (Boolean)getAttributeInternal(UNNUMBERRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UnNumberRender
   */
  public void setUnNumberRender(Boolean value)
  {
    setAttributeInternal(UNNUMBERRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CondBizTypeViewRender
   */
  public Boolean getCondBizTypeViewRender()
  {
    return (Boolean)getAttributeInternal(CONDBIZTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CondBizTypeViewRender
   */
  public void setCondBizTypeViewRender(Boolean value)
  {
    setAttributeInternal(CONDBIZTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CondBizTypeRender
   */
  public Boolean getCondBizTypeRender()
  {
    return (Boolean)getAttributeInternal(CONDBIZTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CondBizTypeRender
   */
  public void setCondBizTypeRender(Boolean value)
  {
    setAttributeInternal(CONDBIZTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ScActionFlRNRender
   */
  public Boolean getScActionFlRNRender()
  {
    return (Boolean)getAttributeInternal(SCACTIONFLRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ScActionFlRNRender
   */
  public void setScActionFlRNRender(Boolean value)
  {
    setAttributeInternal(SCACTIONFLRNRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ScTableFooterRender
   */
  public Boolean getScTableFooterRender()
  {
    return (Boolean)getAttributeInternal(SCTABLEFOOTERRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ScTableFooterRender
   */
  public void setScTableFooterRender(Boolean value)
  {
    setAttributeInternal(SCTABLEFOOTERRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AllContainerTypeViewRender
   */
  public Boolean getAllContainerTypeViewRender()
  {
    return (Boolean)getAttributeInternal(ALLCONTAINERTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AllContainerTypeViewRender
   */
  public void setAllContainerTypeViewRender(Boolean value)
  {
    setAttributeInternal(ALLCONTAINERTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AllContainerTypeRender
   */
  public Boolean getAllContainerTypeRender()
  {
    return (Boolean)getAttributeInternal(ALLCONTAINERTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AllContainerTypeRender
   */
  public void setAllContainerTypeRender(Boolean value)
  {
    setAttributeInternal(ALLCONTAINERTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AllCcActionFlRNRender
   */
  public Boolean getAllCcActionFlRNRender()
  {
    return (Boolean)getAttributeInternal(ALLCCACTIONFLRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AllCcActionFlRNRender
   */
  public void setAllCcActionFlRNRender(Boolean value)
  {
    setAttributeInternal(ALLCCACTIONFLRNRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SelCcActionFlRNRender
   */
  public Boolean getSelCcActionFlRNRender()
  {
    return (Boolean)getAttributeInternal(SELCCACTIONFLRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SelCcActionFlRNRender
   */
  public void setSelCcActionFlRNRender(Boolean value)
  {
    setAttributeInternal(SELCCACTIONFLRNRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractYearDateViewRender
   */
  public Boolean getContractYearDateViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTYEARDATEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractYearDateViewRender
   */
  public void setContractYearDateViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTYEARDATEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractYearDateRender
   */
  public Boolean getContractYearDateRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTYEARDATERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractYearDateRender
   */
  public void setContractYearDateRender(Boolean value)
  {
    setAttributeInternal(CONTRACTYEARDATERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSupportAmtViewRender
   */
  public Boolean getInstallSupportAmtViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPORTAMTVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSupportAmtViewRender
   */
  public void setInstallSupportAmtViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPORTAMTVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSupportAmtRender
   */
  public Boolean getInstallSupportAmtRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPORTAMTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSupportAmtRender
   */
  public void setInstallSupportAmtRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPORTAMTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSupportAmt2ViewRender
   */
  public Boolean getInstallSupportAmt2ViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPORTAMT2VIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSupportAmt2ViewRender
   */
  public void setInstallSupportAmt2ViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPORTAMT2VIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSupportAmt2Render
   */
  public Boolean getInstallSupportAmt2Render()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPORTAMT2RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSupportAmt2Render
   */
  public void setInstallSupportAmt2Render(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPORTAMT2RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PaymentCycleViewRender
   */
  public Boolean getPaymentCycleViewRender()
  {
    return (Boolean)getAttributeInternal(PAYMENTCYCLEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PaymentCycleViewRender
   */
  public void setPaymentCycleViewRender(Boolean value)
  {
    setAttributeInternal(PAYMENTCYCLEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PaymentCycleRender
   */
  public Boolean getPaymentCycleRender()
  {
    return (Boolean)getAttributeInternal(PAYMENTCYCLERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PaymentCycleRender
   */
  public void setPaymentCycleRender(Boolean value)
  {
    setAttributeInternal(PAYMENTCYCLERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricityTypeViewRender
   */
  public Boolean getElectricityTypeViewRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICITYTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricityTypeViewRender
   */
  public void setElectricityTypeViewRender(Boolean value)
  {
    setAttributeInternal(ELECTRICITYTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricityTypeRender
   */
  public Boolean getElectricityTypeRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICITYTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricityTypeRender
   */
  public void setElectricityTypeRender(Boolean value)
  {
    setAttributeInternal(ELECTRICITYTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricityAmountViewRender
   */
  public Boolean getElectricityAmountViewRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICITYAMOUNTVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricityAmountViewRender
   */
  public void setElectricityAmountViewRender(Boolean value)
  {
    setAttributeInternal(ELECTRICITYAMOUNTVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricityAmountRender
   */
  public Boolean getElectricityAmountRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICITYAMOUNTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricityAmountRender
   */
  public void setElectricityAmountRender(Boolean value)
  {
    setAttributeInternal(ELECTRICITYAMOUNTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ConditionReasonViewRender
   */
  public Boolean getConditionReasonViewRender()
  {
    return (Boolean)getAttributeInternal(CONDITIONREASONVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ConditionReasonViewRender
   */
  public void setConditionReasonViewRender(Boolean value)
  {
    setAttributeInternal(CONDITIONREASONVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ConditionReasonRender
   */
  public Boolean getConditionReasonRender()
  {
    return (Boolean)getAttributeInternal(CONDITIONREASONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ConditionReasonRender
   */
  public void setConditionReasonRender(Boolean value)
  {
    setAttributeInternal(CONDITIONREASONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1SendTypeViewRender
   */
  public Boolean getBm1SendTypeViewRender()
  {
    return (Boolean)getAttributeInternal(BM1SENDTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1SendTypeViewRender
   */
  public void setBm1SendTypeViewRender(Boolean value)
  {
    setAttributeInternal(BM1SENDTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1SendTypeRender
   */
  public Boolean getBm1SendTypeRender()
  {
    return (Boolean)getAttributeInternal(BM1SENDTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1SendTypeRender
   */
  public void setBm1SendTypeRender(Boolean value)
  {
    setAttributeInternal(BM1SENDTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1VendorNumberViewRender
   */
  public Boolean getBm1VendorNumberViewRender()
  {
    return (Boolean)getAttributeInternal(BM1VENDORNUMBERVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1VendorNumberViewRender
   */
  public void setBm1VendorNumberViewRender(Boolean value)
  {
    setAttributeInternal(BM1VENDORNUMBERVIEWRENDER, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1VendorNameViewRender
   */
  public Boolean getBm1VendorNameViewRender()
  {
    return (Boolean)getAttributeInternal(BM1VENDORNAMEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1VendorNameViewRender
   */
  public void setBm1VendorNameViewRender(Boolean value)
  {
    setAttributeInternal(BM1VENDORNAMEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1VendorNameRender
   */
  public Boolean getBm1VendorNameRender()
  {
    return (Boolean)getAttributeInternal(BM1VENDORNAMERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1VendorNameRender
   */
  public void setBm1VendorNameRender(Boolean value)
  {
    setAttributeInternal(BM1VENDORNAMERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1VendorNameAltViewRender
   */
  public Boolean getBm1VendorNameAltViewRender()
  {
    return (Boolean)getAttributeInternal(BM1VENDORNAMEALTVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1VendorNameAltViewRender
   */
  public void setBm1VendorNameAltViewRender(Boolean value)
  {
    setAttributeInternal(BM1VENDORNAMEALTVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1VendorNameAltRender
   */
  public Boolean getBm1VendorNameAltRender()
  {
    return (Boolean)getAttributeInternal(BM1VENDORNAMEALTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1VendorNameAltRender
   */
  public void setBm1VendorNameAltRender(Boolean value)
  {
    setAttributeInternal(BM1VENDORNAMEALTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1TransferTypeViewRender
   */
  public Boolean getBm1TransferTypeViewRender()
  {
    return (Boolean)getAttributeInternal(BM1TRANSFERTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1TransferTypeViewRender
   */
  public void setBm1TransferTypeViewRender(Boolean value)
  {
    setAttributeInternal(BM1TRANSFERTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1TransferTypeRender
   */
  public Boolean getBm1TransferTypeRender()
  {
    return (Boolean)getAttributeInternal(BM1TRANSFERTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1TransferTypeRender
   */
  public void setBm1TransferTypeRender(Boolean value)
  {
    setAttributeInternal(BM1TRANSFERTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1PaymentTypeViewRender
   */
  public Boolean getBm1PaymentTypeViewRender()
  {
    return (Boolean)getAttributeInternal(BM1PAYMENTTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1PaymentTypeViewRender
   */
  public void setBm1PaymentTypeViewRender(Boolean value)
  {
    setAttributeInternal(BM1PAYMENTTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1PaymentTypeRender
   */
  public Boolean getBm1PaymentTypeRender()
  {
    return (Boolean)getAttributeInternal(BM1PAYMENTTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1PaymentTypeRender
   */
  public void setBm1PaymentTypeRender(Boolean value)
  {
    setAttributeInternal(BM1PAYMENTTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1InquiryBaseLayoutRender
   */
  public Boolean getBm1InquiryBaseLayoutRender()
  {
    return (Boolean)getAttributeInternal(BM1INQUIRYBASELAYOUTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1InquiryBaseLayoutRender
   */
  public void setBm1InquiryBaseLayoutRender(Boolean value)
  {
    setAttributeInternal(BM1INQUIRYBASELAYOUTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1PostCdFViewRender
   */
  public Boolean getBm1PostCdFViewRender()
  {
    return (Boolean)getAttributeInternal(BM1POSTCDFVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1PostCdFViewRender
   */
  public void setBm1PostCdFViewRender(Boolean value)
  {
    setAttributeInternal(BM1POSTCDFVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1PostCdFRender
   */
  public Boolean getBm1PostCdFRender()
  {
    return (Boolean)getAttributeInternal(BM1POSTCDFRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1PostCdFRender
   */
  public void setBm1PostCdFRender(Boolean value)
  {
    setAttributeInternal(BM1POSTCDFRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1PostCdSViewRender
   */
  public Boolean getBm1PostCdSViewRender()
  {
    return (Boolean)getAttributeInternal(BM1POSTCDSVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1PostCdSViewRender
   */
  public void setBm1PostCdSViewRender(Boolean value)
  {
    setAttributeInternal(BM1POSTCDSVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1PostCdSRender
   */
  public Boolean getBm1PostCdSRender()
  {
    return (Boolean)getAttributeInternal(BM1POSTCDSRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1PostCdSRender
   */
  public void setBm1PostCdSRender(Boolean value)
  {
    setAttributeInternal(BM1POSTCDSRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1StateViewRender
   */
  public Boolean getBm1StateViewRender()
  {
    return (Boolean)getAttributeInternal(BM1STATEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1StateViewRender
   */
  public void setBm1StateViewRender(Boolean value)
  {
    setAttributeInternal(BM1STATEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1StateRender
   */
  public Boolean getBm1StateRender()
  {
    return (Boolean)getAttributeInternal(BM1STATERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1StateRender
   */
  public void setBm1StateRender(Boolean value)
  {
    setAttributeInternal(BM1STATERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1CityViewRender
   */
  public Boolean getBm1CityViewRender()
  {
    return (Boolean)getAttributeInternal(BM1CITYVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1CityViewRender
   */
  public void setBm1CityViewRender(Boolean value)
  {
    setAttributeInternal(BM1CITYVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1CityRender
   */
  public Boolean getBm1CityRender()
  {
    return (Boolean)getAttributeInternal(BM1CITYRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1CityRender
   */
  public void setBm1CityRender(Boolean value)
  {
    setAttributeInternal(BM1CITYRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1Address1ViewRender
   */
  public Boolean getBm1Address1ViewRender()
  {
    return (Boolean)getAttributeInternal(BM1ADDRESS1VIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1Address1ViewRender
   */
  public void setBm1Address1ViewRender(Boolean value)
  {
    setAttributeInternal(BM1ADDRESS1VIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1Address1Render
   */
  public Boolean getBm1Address1Render()
  {
    return (Boolean)getAttributeInternal(BM1ADDRESS1RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1Address1Render
   */
  public void setBm1Address1Render(Boolean value)
  {
    setAttributeInternal(BM1ADDRESS1RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1Address2ViewRender
   */
  public Boolean getBm1Address2ViewRender()
  {
    return (Boolean)getAttributeInternal(BM1ADDRESS2VIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1Address2ViewRender
   */
  public void setBm1Address2ViewRender(Boolean value)
  {
    setAttributeInternal(BM1ADDRESS2VIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1Address2Render
   */
  public Boolean getBm1Address2Render()
  {
    return (Boolean)getAttributeInternal(BM1ADDRESS2RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1Address2Render
   */
  public void setBm1Address2Render(Boolean value)
  {
    setAttributeInternal(BM1ADDRESS2RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1AddressLineViewRender
   */
  public Boolean getBm1AddressLineViewRender()
  {
    return (Boolean)getAttributeInternal(BM1ADDRESSLINEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1AddressLineViewRender
   */
  public void setBm1AddressLineViewRender(Boolean value)
  {
    setAttributeInternal(BM1ADDRESSLINEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1AddressLineRender
   */
  public Boolean getBm1AddressLineRender()
  {
    return (Boolean)getAttributeInternal(BM1ADDRESSLINERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1AddressLineRender
   */
  public void setBm1AddressLineRender(Boolean value)
  {
    setAttributeInternal(BM1ADDRESSLINERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2VendorNumberViewRender
   */
  public Boolean getBm2VendorNumberViewRender()
  {
    return (Boolean)getAttributeInternal(BM2VENDORNUMBERVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2VendorNumberViewRender
   */
  public void setBm2VendorNumberViewRender(Boolean value)
  {
    setAttributeInternal(BM2VENDORNUMBERVIEWRENDER, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2VendorNameViewRender
   */
  public Boolean getBm2VendorNameViewRender()
  {
    return (Boolean)getAttributeInternal(BM2VENDORNAMEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2VendorNameViewRender
   */
  public void setBm2VendorNameViewRender(Boolean value)
  {
    setAttributeInternal(BM2VENDORNAMEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2VendorNameRender
   */
  public Boolean getBm2VendorNameRender()
  {
    return (Boolean)getAttributeInternal(BM2VENDORNAMERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2VendorNameRender
   */
  public void setBm2VendorNameRender(Boolean value)
  {
    setAttributeInternal(BM2VENDORNAMERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2VendorNameAltViewRender
   */
  public Boolean getBm2VendorNameAltViewRender()
  {
    return (Boolean)getAttributeInternal(BM2VENDORNAMEALTVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2VendorNameAltViewRender
   */
  public void setBm2VendorNameAltViewRender(Boolean value)
  {
    setAttributeInternal(BM2VENDORNAMEALTVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2VendorNameAltRender
   */
  public Boolean getBm2VendorNameAltRender()
  {
    return (Boolean)getAttributeInternal(BM2VENDORNAMEALTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2VendorNameAltRender
   */
  public void setBm2VendorNameAltRender(Boolean value)
  {
    setAttributeInternal(BM2VENDORNAMEALTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2PostCdFViewRender
   */
  public Boolean getBm2PostCdFViewRender()
  {
    return (Boolean)getAttributeInternal(BM2POSTCDFVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2PostCdFViewRender
   */
  public void setBm2PostCdFViewRender(Boolean value)
  {
    setAttributeInternal(BM2POSTCDFVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2PostCdFRender
   */
  public Boolean getBm2PostCdFRender()
  {
    return (Boolean)getAttributeInternal(BM2POSTCDFRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2PostCdFRender
   */
  public void setBm2PostCdFRender(Boolean value)
  {
    setAttributeInternal(BM2POSTCDFRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2PostCdSViewRender
   */
  public Boolean getBm2PostCdSViewRender()
  {
    return (Boolean)getAttributeInternal(BM2POSTCDSVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2PostCdSViewRender
   */
  public void setBm2PostCdSViewRender(Boolean value)
  {
    setAttributeInternal(BM2POSTCDSVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2PostCdSRender
   */
  public Boolean getBm2PostCdSRender()
  {
    return (Boolean)getAttributeInternal(BM2POSTCDSRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2PostCdSRender
   */
  public void setBm2PostCdSRender(Boolean value)
  {
    setAttributeInternal(BM2POSTCDSRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2StateViewRender
   */
  public Boolean getBm2StateViewRender()
  {
    return (Boolean)getAttributeInternal(BM2STATEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2StateViewRender
   */
  public void setBm2StateViewRender(Boolean value)
  {
    setAttributeInternal(BM2STATEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2StateRender
   */
  public Boolean getBm2StateRender()
  {
    return (Boolean)getAttributeInternal(BM2STATERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2StateRender
   */
  public void setBm2StateRender(Boolean value)
  {
    setAttributeInternal(BM2STATERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2CityViewRender
   */
  public Boolean getBm2CityViewRender()
  {
    return (Boolean)getAttributeInternal(BM2CITYVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2CityViewRender
   */
  public void setBm2CityViewRender(Boolean value)
  {
    setAttributeInternal(BM2CITYVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2CityRender
   */
  public Boolean getBm2CityRender()
  {
    return (Boolean)getAttributeInternal(BM2CITYRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2CityRender
   */
  public void setBm2CityRender(Boolean value)
  {
    setAttributeInternal(BM2CITYRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2Address1ViewRender
   */
  public Boolean getBm2Address1ViewRender()
  {
    return (Boolean)getAttributeInternal(BM2ADDRESS1VIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2Address1ViewRender
   */
  public void setBm2Address1ViewRender(Boolean value)
  {
    setAttributeInternal(BM2ADDRESS1VIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2Address1Render
   */
  public Boolean getBm2Address1Render()
  {
    return (Boolean)getAttributeInternal(BM2ADDRESS1RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2Address1Render
   */
  public void setBm2Address1Render(Boolean value)
  {
    setAttributeInternal(BM2ADDRESS1RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2Address2ViewRender
   */
  public Boolean getBm2Address2ViewRender()
  {
    return (Boolean)getAttributeInternal(BM2ADDRESS2VIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2Address2ViewRender
   */
  public void setBm2Address2ViewRender(Boolean value)
  {
    setAttributeInternal(BM2ADDRESS2VIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2Address2Render
   */
  public Boolean getBm2Address2Render()
  {
    return (Boolean)getAttributeInternal(BM2ADDRESS2RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2Address2Render
   */
  public void setBm2Address2Render(Boolean value)
  {
    setAttributeInternal(BM2ADDRESS2RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2AddressLineViewRender
   */
  public Boolean getBm2AddressLineViewRender()
  {
    return (Boolean)getAttributeInternal(BM2ADDRESSLINEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2AddressLineViewRender
   */
  public void setBm2AddressLineViewRender(Boolean value)
  {
    setAttributeInternal(BM2ADDRESSLINEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2AddressLineRender
   */
  public Boolean getBm2AddressLineRender()
  {
    return (Boolean)getAttributeInternal(BM2ADDRESSLINERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2AddressLineRender
   */
  public void setBm2AddressLineRender(Boolean value)
  {
    setAttributeInternal(BM2ADDRESSLINERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2TransferTypeViewRender
   */
  public Boolean getBm2TransferTypeViewRender()
  {
    return (Boolean)getAttributeInternal(BM2TRANSFERTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2TransferTypeViewRender
   */
  public void setBm2TransferTypeViewRender(Boolean value)
  {
    setAttributeInternal(BM2TRANSFERTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2TransferTypeRender
   */
  public Boolean getBm2TransferTypeRender()
  {
    return (Boolean)getAttributeInternal(BM2TRANSFERTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2TransferTypeRender
   */
  public void setBm2TransferTypeRender(Boolean value)
  {
    setAttributeInternal(BM2TRANSFERTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2PaymentTypeViewRender
   */
  public Boolean getBm2PaymentTypeViewRender()
  {
    return (Boolean)getAttributeInternal(BM2PAYMENTTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2PaymentTypeViewRender
   */
  public void setBm2PaymentTypeViewRender(Boolean value)
  {
    setAttributeInternal(BM2PAYMENTTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2PaymentTypeRender
   */
  public Boolean getBm2PaymentTypeRender()
  {
    return (Boolean)getAttributeInternal(BM2PAYMENTTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2PaymentTypeRender
   */
  public void setBm2PaymentTypeRender(Boolean value)
  {
    setAttributeInternal(BM2PAYMENTTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2InquiryBaseLayoutRender
   */
  public Boolean getBm2InquiryBaseLayoutRender()
  {
    return (Boolean)getAttributeInternal(BM2INQUIRYBASELAYOUTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2InquiryBaseLayoutRender
   */
  public void setBm2InquiryBaseLayoutRender(Boolean value)
  {
    setAttributeInternal(BM2INQUIRYBASELAYOUTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3VendorNumberViewRender
   */
  public Boolean getBm3VendorNumberViewRender()
  {
    return (Boolean)getAttributeInternal(BM3VENDORNUMBERVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3VendorNumberViewRender
   */
  public void setBm3VendorNumberViewRender(Boolean value)
  {
    setAttributeInternal(BM3VENDORNUMBERVIEWRENDER, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3VendorNameViewRender
   */
  public Boolean getBm3VendorNameViewRender()
  {
    return (Boolean)getAttributeInternal(BM3VENDORNAMEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3VendorNameViewRender
   */
  public void setBm3VendorNameViewRender(Boolean value)
  {
    setAttributeInternal(BM3VENDORNAMEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3VendorNameRender
   */
  public Boolean getBm3VendorNameRender()
  {
    return (Boolean)getAttributeInternal(BM3VENDORNAMERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3VendorNameRender
   */
  public void setBm3VendorNameRender(Boolean value)
  {
    setAttributeInternal(BM3VENDORNAMERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3VendorNameAltViewRender
   */
  public Boolean getBm3VendorNameAltViewRender()
  {
    return (Boolean)getAttributeInternal(BM3VENDORNAMEALTVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3VendorNameAltViewRender
   */
  public void setBm3VendorNameAltViewRender(Boolean value)
  {
    setAttributeInternal(BM3VENDORNAMEALTVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3VendorNameAltRender
   */
  public Boolean getBm3VendorNameAltRender()
  {
    return (Boolean)getAttributeInternal(BM3VENDORNAMEALTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3VendorNameAltRender
   */
  public void setBm3VendorNameAltRender(Boolean value)
  {
    setAttributeInternal(BM3VENDORNAMEALTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3PostCdFRender
   */
  public Boolean getBm3PostCdFRender()
  {
    return (Boolean)getAttributeInternal(BM3POSTCDFRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3PostCdFRender
   */
  public void setBm3PostCdFRender(Boolean value)
  {
    setAttributeInternal(BM3POSTCDFRENDER, value);
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3StateViewRender
   */
  public Boolean getBm3StateViewRender()
  {
    return (Boolean)getAttributeInternal(BM3STATEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3StateViewRender
   */
  public void setBm3StateViewRender(Boolean value)
  {
    setAttributeInternal(BM3STATEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3StateRender
   */
  public Boolean getBm3StateRender()
  {
    return (Boolean)getAttributeInternal(BM3STATERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3StateRender
   */
  public void setBm3StateRender(Boolean value)
  {
    setAttributeInternal(BM3STATERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3CityViewRender
   */
  public Boolean getBm3CityViewRender()
  {
    return (Boolean)getAttributeInternal(BM3CITYVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3CityViewRender
   */
  public void setBm3CityViewRender(Boolean value)
  {
    setAttributeInternal(BM3CITYVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3CityRender
   */
  public Boolean getBm3CityRender()
  {
    return (Boolean)getAttributeInternal(BM3CITYRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3CityRender
   */
  public void setBm3CityRender(Boolean value)
  {
    setAttributeInternal(BM3CITYRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3Address1ViewRender
   */
  public Boolean getBm3Address1ViewRender()
  {
    return (Boolean)getAttributeInternal(BM3ADDRESS1VIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3Address1ViewRender
   */
  public void setBm3Address1ViewRender(Boolean value)
  {
    setAttributeInternal(BM3ADDRESS1VIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3Address1Render
   */
  public Boolean getBm3Address1Render()
  {
    return (Boolean)getAttributeInternal(BM3ADDRESS1RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3Address1Render
   */
  public void setBm3Address1Render(Boolean value)
  {
    setAttributeInternal(BM3ADDRESS1RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3Address2ViewRender
   */
  public Boolean getBm3Address2ViewRender()
  {
    return (Boolean)getAttributeInternal(BM3ADDRESS2VIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3Address2ViewRender
   */
  public void setBm3Address2ViewRender(Boolean value)
  {
    setAttributeInternal(BM3ADDRESS2VIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3Address2Render
   */
  public Boolean getBm3Address2Render()
  {
    return (Boolean)getAttributeInternal(BM3ADDRESS2RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3Address2Render
   */
  public void setBm3Address2Render(Boolean value)
  {
    setAttributeInternal(BM3ADDRESS2RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3AddressLineViewRender
   */
  public Boolean getBm3AddressLineViewRender()
  {
    return (Boolean)getAttributeInternal(BM3ADDRESSLINEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3AddressLineViewRender
   */
  public void setBm3AddressLineViewRender(Boolean value)
  {
    setAttributeInternal(BM3ADDRESSLINEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3AddressLineRender
   */
  public Boolean getBm3AddressLineRender()
  {
    return (Boolean)getAttributeInternal(BM3ADDRESSLINERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3AddressLineRender
   */
  public void setBm3AddressLineRender(Boolean value)
  {
    setAttributeInternal(BM3ADDRESSLINERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3TransferTypeViewRender
   */
  public Boolean getBm3TransferTypeViewRender()
  {
    return (Boolean)getAttributeInternal(BM3TRANSFERTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3TransferTypeViewRender
   */
  public void setBm3TransferTypeViewRender(Boolean value)
  {
    setAttributeInternal(BM3TRANSFERTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3TransferTypeRender
   */
  public Boolean getBm3TransferTypeRender()
  {
    return (Boolean)getAttributeInternal(BM3TRANSFERTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3TransferTypeRender
   */
  public void setBm3TransferTypeRender(Boolean value)
  {
    setAttributeInternal(BM3TRANSFERTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3PaymentTypeViewRender
   */
  public Boolean getBm3PaymentTypeViewRender()
  {
    return (Boolean)getAttributeInternal(BM3PAYMENTTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3PaymentTypeViewRender
   */
  public void setBm3PaymentTypeViewRender(Boolean value)
  {
    setAttributeInternal(BM3PAYMENTTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3PaymentTypeRender
   */
  public Boolean getBm3PaymentTypeRender()
  {
    return (Boolean)getAttributeInternal(BM3PAYMENTTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3PaymentTypeRender
   */
  public void setBm3PaymentTypeRender(Boolean value)
  {
    setAttributeInternal(BM3PAYMENTTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3InquiryBaseLayoutRender
   */
  public Boolean getBm3InquiryBaseLayoutRender()
  {
    return (Boolean)getAttributeInternal(BM3INQUIRYBASELAYOUTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3InquiryBaseLayoutRender
   */
  public void setBm3InquiryBaseLayoutRender(Boolean value)
  {
    setAttributeInternal(BM3INQUIRYBASELAYOUTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OtherContentViewRender
   */
  public Boolean getOtherContentViewRender()
  {
    return (Boolean)getAttributeInternal(OTHERCONTENTVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OtherContentViewRender
   */
  public void setOtherContentViewRender(Boolean value)
  {
    setAttributeInternal(OTHERCONTENTVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OtherContentRender
   */
  public Boolean getOtherContentRender()
  {
    return (Boolean)getAttributeInternal(OTHERCONTENTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OtherContentRender
   */
  public void setOtherContentRender(Boolean value)
  {
    setAttributeInternal(OTHERCONTENTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CalcProfitButtonRender
   */
  public Boolean getCalcProfitButtonRender()
  {
    return (Boolean)getAttributeInternal(CALCPROFITBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CalcProfitButtonRender
   */
  public void setCalcProfitButtonRender(Boolean value)
  {
    setAttributeInternal(CALCPROFITBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SalesMonthViewRender
   */
  public Boolean getSalesMonthViewRender()
  {
    return (Boolean)getAttributeInternal(SALESMONTHVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SalesMonthViewRender
   */
  public void setSalesMonthViewRender(Boolean value)
  {
    setAttributeInternal(SALESMONTHVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SalesMonthRender
   */
  public Boolean getSalesMonthRender()
  {
    return (Boolean)getAttributeInternal(SALESMONTHRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SalesMonthRender
   */
  public void setSalesMonthRender(Boolean value)
  {
    setAttributeInternal(SALESMONTHRENDER, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute BmRateViewRender
   */
  public Boolean getBmRateViewRender()
  {
    return (Boolean)getAttributeInternal(BMRATEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BmRateViewRender
   */
  public void setBmRateViewRender(Boolean value)
  {
    setAttributeInternal(BMRATEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BmRateRender
   */
  public Boolean getBmRateRender()
  {
    return (Boolean)getAttributeInternal(BMRATERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BmRateRender
   */
  public void setBmRateRender(Boolean value)
  {
    setAttributeInternal(BMRATERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LeaseChargeMonthViewRender
   */
  public Boolean getLeaseChargeMonthViewRender()
  {
    return (Boolean)getAttributeInternal(LEASECHARGEMONTHVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeaseChargeMonthViewRender
   */
  public void setLeaseChargeMonthViewRender(Boolean value)
  {
    setAttributeInternal(LEASECHARGEMONTHVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LeaseChargeMonthRender
   */
  public Boolean getLeaseChargeMonthRender()
  {
    return (Boolean)getAttributeInternal(LEASECHARGEMONTHRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeaseChargeMonthRender
   */
  public void setLeaseChargeMonthRender(Boolean value)
  {
    setAttributeInternal(LEASECHARGEMONTHRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ConstructionChargeViewRender
   */
  public Boolean getConstructionChargeViewRender()
  {
    return (Boolean)getAttributeInternal(CONSTRUCTIONCHARGEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ConstructionChargeViewRender
   */
  public void setConstructionChargeViewRender(Boolean value)
  {
    setAttributeInternal(CONSTRUCTIONCHARGEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ConstructionChargeRender
   */
  public Boolean getConstructionChargeRender()
  {
    return (Boolean)getAttributeInternal(CONSTRUCTIONCHARGERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ConstructionChargeRender
   */
  public void setConstructionChargeRender(Boolean value)
  {
    setAttributeInternal(CONSTRUCTIONCHARGERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricityAmtMonthViewRender
   */
  public Boolean getElectricityAmtMonthViewRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICITYAMTMONTHVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricityAmtMonthViewRender
   */
  public void setElectricityAmtMonthViewRender(Boolean value)
  {
    setAttributeInternal(ELECTRICITYAMTMONTHVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricityAmtMonthRender
   */
  public Boolean getElectricityAmtMonthRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICITYAMTMONTHRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricityAmtMonthRender
   */
  public void setElectricityAmtMonthRender(Boolean value)
  {
    setAttributeInternal(ELECTRICITYAMTMONTHRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AttachActionFlRNRender
   */
  public Boolean getAttachActionFlRNRender()
  {
    return (Boolean)getAttributeInternal(ATTACHACTIONFLRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AttachActionFlRNRender
   */
  public void setAttachActionFlRNRender(Boolean value)
  {
    setAttributeInternal(ATTACHACTIONFLRNRENDER, value);
  }







  /**
   * 
   * Gets the attribute value for the calculated attribute InstallDateViewRender
   */
  public Boolean getInstallDateViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLDATEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallDateViewRender
   */
  public void setInstallDateViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLDATEVIEWRENDER, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3PostCdSRender
   */
  public Boolean getBm3PostCdSRender()
  {
    return (Boolean)getAttributeInternal(BM3POSTCDSRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3PostCdSRender
   */
  public void setBm3PostCdSRender(Boolean value)
  {
    setAttributeInternal(BM3POSTCDSRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AttachFileUpExcerpt
   */
  public String getAttachFileUpExcerpt()
  {
    return (String)getAttributeInternal(ATTACHFILEUPEXCERPT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AttachFileUpExcerpt
   */
  public void setAttachFileUpExcerpt(String value)
  {
    setAttributeInternal(ATTACHFILEUPEXCERPT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3PostCdFViewRender
   */
  public Boolean getBm3PostCdFViewRender()
  {
    return (Boolean)getAttributeInternal(BM3POSTCDFVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3PostCdFViewRender
   */
  public void setBm3PostCdFViewRender(Boolean value)
  {
    setAttributeInternal(BM3POSTCDFVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3PostCdSViewRender
   */
  public Boolean getBm3PostCdSViewRender()
  {
    return (Boolean)getAttributeInternal(BM3POSTCDSVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3PostCdSViewRender
   */
  public void setBm3PostCdSViewRender(Boolean value)
  {
    setAttributeInternal(BM3POSTCDSVIEWRENDER, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute ScBm2GrpRender
   */
  public Boolean getScBm2GrpRender()
  {
    return (Boolean)getAttributeInternal(SCBM2GRPRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ScBm2GrpRender
   */
  public void setScBm2GrpRender(Boolean value)
  {
    setAttributeInternal(SCBM2GRPRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ScContributeGrpRender
   */
  public Boolean getScContributeGrpRender()
  {
    return (Boolean)getAttributeInternal(SCCONTRIBUTEGRPRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ScContributeGrpRender
   */
  public void setScContributeGrpRender(Boolean value)
  {
    setAttributeInternal(SCCONTRIBUTEGRPRENDER, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute AllCcBm2GrpRender
   */
  public Boolean getAllCcBm2GrpRender()
  {
    return (Boolean)getAttributeInternal(ALLCCBM2GRPRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AllCcBm2GrpRender
   */
  public void setAllCcBm2GrpRender(Boolean value)
  {
    setAttributeInternal(ALLCCBM2GRPRENDER, value);
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute SelCcBm2GrpRender
   */
  public Boolean getSelCcBm2GrpRender()
  {
    return (Boolean)getAttributeInternal(SELCCBM2GRPRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SelCcBm2GrpRender
   */
  public void setSelCcBm2GrpRender(Boolean value)
  {
    setAttributeInternal(SELCCBM2GRPRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SelCcContributeGrpRender
   */
  public Boolean getSelCcContributeGrpRender()
  {
    return (Boolean)getAttributeInternal(SELCCCONTRIBUTEGRPRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SelCcContributeGrpRender
   */
  public void setSelCcContributeGrpRender(Boolean value)
  {
    setAttributeInternal(SELCCCONTRIBUTEGRPRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1InfoHdrRNRender
   */
  public Boolean getBm1InfoHdrRNRender()
  {
    return (Boolean)getAttributeInternal(BM1INFOHDRRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1InfoHdrRNRender
   */
  public void setBm1InfoHdrRNRender(Boolean value)
  {
    setAttributeInternal(BM1INFOHDRRNRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2InfoHdrRNRender
   */
  public Boolean getBm2InfoHdrRNRender()
  {
    return (Boolean)getAttributeInternal(BM2INFOHDRRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2InfoHdrRNRender
   */
  public void setBm2InfoHdrRNRender(Boolean value)
  {
    setAttributeInternal(BM2INFOHDRRNRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContributeInfoHdrRNRender
   */
  public Boolean getContributeInfoHdrRNRender()
  {
    return (Boolean)getAttributeInternal(CONTRIBUTEINFOHDRRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContributeInfoHdrRNRender
   */
  public void setContributeInfoHdrRNRender(Boolean value)
  {
    setAttributeInternal(CONTRIBUTEINFOHDRRNRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3InfoHdrRNRender
   */
  public Boolean getBm3InfoHdrRNRender()
  {
    return (Boolean)getAttributeInternal(BM3INFOHDRRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3InfoHdrRNRender
   */
  public void setBm3InfoHdrRNRender(Boolean value)
  {
    setAttributeInternal(BM3INFOHDRRNRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AllCcContributeGrpRender
   */
  public Boolean getAllCcContributeGrpRender()
  {
    return (Boolean)getAttributeInternal(ALLCCCONTRIBUTEGRPRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AllCcContributeGrpRender
   */
  public void setAllCcContributeGrpRender(Boolean value)
  {
    setAttributeInternal(ALLCCCONTRIBUTEGRPRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SalesConditionHdrRNRender
   */
  public Boolean getSalesConditionHdrRNRender()
  {
    return (Boolean)getAttributeInternal(SALESCONDITIONHDRRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SalesConditionHdrRNRender
   */
  public void setSalesConditionHdrRNRender(Boolean value)
  {
    setAttributeInternal(SALESCONDITIONHDRRNRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AllCcAdvTblRNRender
   */
  public Boolean getAllCcAdvTblRNRender()
  {
    return (Boolean)getAttributeInternal(ALLCCADVTBLRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AllCcAdvTblRNRender
   */
  public void setAllCcAdvTblRNRender(Boolean value)
  {
    setAttributeInternal(ALLCCADVTBLRNRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SelCcAdvTblRNRender
   */
  public Boolean getSelCcAdvTblRNRender()
  {
    return (Boolean)getAttributeInternal(SELCCADVTBLRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SelCcAdvTblRNRender
   */
  public void setSelCcAdvTblRNRender(Boolean value)
  {
    setAttributeInternal(SELCCADVTBLRNRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContainerConditionHdrRNRender
   */
  public Boolean getContainerConditionHdrRNRender()
  {
    return (Boolean)getAttributeInternal(CONTAINERCONDITIONHDRRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContainerConditionHdrRNRender
   */
  public void setContainerConditionHdrRNRender(Boolean value)
  {
    setAttributeInternal(CONTAINERCONDITIONHDRRNRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1PostalCodeLayoutRender
   */
  public Boolean getBm1PostalCodeLayoutRender()
  {
    return (Boolean)getAttributeInternal(BM1POSTALCODELAYOUTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1PostalCodeLayoutRender
   */
  public void setBm1PostalCodeLayoutRender(Boolean value)
  {
    setAttributeInternal(BM1POSTALCODELAYOUTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2PostalCodeLayoutRender
   */
  public Boolean getBm2PostalCodeLayoutRender()
  {
    return (Boolean)getAttributeInternal(BM2POSTALCODELAYOUTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2PostalCodeLayoutRender
   */
  public void setBm2PostalCodeLayoutRender(Boolean value)
  {
    setAttributeInternal(BM2POSTALCODELAYOUTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3PostalCodeLayoutRender
   */
  public Boolean getBm3PostalCodeLayoutRender()
  {
    return (Boolean)getAttributeInternal(BM3POSTALCODELAYOUTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3PostalCodeLayoutRender
   */
  public void setBm3PostalCodeLayoutRender(Boolean value)
  {
    setAttributeInternal(BM3POSTALCODELAYOUTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ReflectContractButtonRender
   */
  public Boolean getReflectContractButtonRender()
  {
    return (Boolean)getAttributeInternal(REFLECTCONTRACTBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ReflectContractButtonRender
   */
  public void setReflectContractButtonRender(Boolean value)
  {
    setAttributeInternal(REFLECTCONTRACTBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1TransferTypeLayoutRender
   */
  public Boolean getBm1TransferTypeLayoutRender()
  {
    return (Boolean)getAttributeInternal(BM1TRANSFERTYPELAYOUTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1TransferTypeLayoutRender
   */
  public void setBm1TransferTypeLayoutRender(Boolean value)
  {
    setAttributeInternal(BM1TRANSFERTYPELAYOUTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2TransferTypeLayoutRender
   */
  public Boolean getBm2TransferTypeLayoutRender()
  {
    return (Boolean)getAttributeInternal(BM2TRANSFERTYPELAYOUTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2TransferTypeLayoutRender
   */
  public void setBm2TransferTypeLayoutRender(Boolean value)
  {
    setAttributeInternal(BM2TRANSFERTYPELAYOUTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3TransferTypeLayoutRender
   */
  public Boolean getBm3TransferTypeLayoutRender()
  {
    return (Boolean)getAttributeInternal(BM3TRANSFERTYPELAYOUTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3TransferTypeLayoutRender
   */
  public void setBm3TransferTypeLayoutRender(Boolean value)
  {
    setAttributeInternal(BM3TRANSFERTYPELAYOUTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallDateRequiredViewRender
   */
  public Boolean getInstallDateRequiredViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLDATEREQUIREDVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallDateRequiredViewRender
   */
  public void setInstallDateRequiredViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLDATEREQUIREDVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallDateRequiredRender
   */
  public Boolean getInstallDateRequiredRender()
  {
    return (Boolean)getAttributeInternal(INSTALLDATEREQUIREDRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallDateRequiredRender
   */
  public void setInstallDateRequiredRender(Boolean value)
  {
    setAttributeInternal(INSTALLDATEREQUIREDRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VdInfo3RequiredLayoutRender
   */
  public Boolean getVdInfo3RequiredLayoutRender()
  {
    return (Boolean)getAttributeInternal(VDINFO3REQUIREDLAYOUTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VdInfo3RequiredLayoutRender
   */
  public void setVdInfo3RequiredLayoutRender(Boolean value)
  {
    setAttributeInternal(VDINFO3REQUIREDLAYOUTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VdInfo3LayoutRender
   */
  public Boolean getVdInfo3LayoutRender()
  {
    return (Boolean)getAttributeInternal(VDINFO3LAYOUTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VdInfo3LayoutRender
   */
  public void setVdInfo3LayoutRender(Boolean value)
  {
    setAttributeInternal(VDINFO3LAYOUTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElecStartRequiredLabelRender
   */
  public Boolean getElecStartRequiredLabelRender()
  {
    return (Boolean)getAttributeInternal(ELECSTARTREQUIREDLABELRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElecStartRequiredLabelRender
   */
  public void setElecStartRequiredLabelRender(Boolean value)
  {
    setAttributeInternal(ELECSTARTREQUIREDLABELRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElecStartLabelRender
   */
  public Boolean getElecStartLabelRender()
  {
    return (Boolean)getAttributeInternal(ELECSTARTLABELRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElecStartLabelRender
   */
  public void setElecStartLabelRender(Boolean value)
  {
    setAttributeInternal(ELECSTARTLABELRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElecAmountLabelRender
   */
  public Boolean getElecAmountLabelRender()
  {
    return (Boolean)getAttributeInternal(ELECAMOUNTLABELRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElecAmountLabelRender
   */
  public void setElecAmountLabelRender(Boolean value)
  {
    setAttributeInternal(ELECAMOUNTLABELRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CntrctElecSpacer2Render
   */
  public Boolean getCntrctElecSpacer2Render()
  {
    return (Boolean)getAttributeInternal(CNTRCTELECSPACER2RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CntrctElecSpacer2Render
   */
  public void setCntrctElecSpacer2Render(Boolean value)
  {
    setAttributeInternal(CNTRCTELECSPACER2RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAcctNumber1Render
   */
  public Boolean getInstallAcctNumber1Render()
  {
    return (Boolean)getAttributeInternal(INSTALLACCTNUMBER1RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAcctNumber1Render
   */
  public void setInstallAcctNumber1Render(Boolean value)
  {
    setAttributeInternal(INSTALLACCTNUMBER1RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAcctNumber2Render
   */
  public Boolean getInstallAcctNumber2Render()
  {
    return (Boolean)getAttributeInternal(INSTALLACCTNUMBER2RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAcctNumber2Render
   */
  public void setInstallAcctNumber2Render(Boolean value)
  {
    setAttributeInternal(INSTALLACCTNUMBER2RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractNumber1Render
   */
  public Boolean getContractNumber1Render()
  {
    return (Boolean)getAttributeInternal(CONTRACTNUMBER1RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractNumber1Render
   */
  public void setContractNumber1Render(Boolean value)
  {
    setAttributeInternal(CONTRACTNUMBER1RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractNumber2Render
   */
  public Boolean getContractNumber2Render()
  {
    return (Boolean)getAttributeInternal(CONTRACTNUMBER2RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractNumber2Render
   */
  public void setContractNumber2Render(Boolean value)
  {
    setAttributeInternal(CONTRACTNUMBER2RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1VendorNumber1Render
   */
  public Boolean getBm1VendorNumber1Render()
  {
    return (Boolean)getAttributeInternal(BM1VENDORNUMBER1RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1VendorNumber1Render
   */
  public void setBm1VendorNumber1Render(Boolean value)
  {
    setAttributeInternal(BM1VENDORNUMBER1RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1VendorNumber2Render
   */
  public Boolean getBm1VendorNumber2Render()
  {
    return (Boolean)getAttributeInternal(BM1VENDORNUMBER2RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1VendorNumber2Render
   */
  public void setBm1VendorNumber2Render(Boolean value)
  {
    setAttributeInternal(BM1VENDORNUMBER2RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2VendorNumber1Render
   */
  public Boolean getBm2VendorNumber1Render()
  {
    return (Boolean)getAttributeInternal(BM2VENDORNUMBER1RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2VendorNumber1Render
   */
  public void setBm2VendorNumber1Render(Boolean value)
  {
    setAttributeInternal(BM2VENDORNUMBER1RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2VendorNumber2Render
   */
  public Boolean getBm2VendorNumber2Render()
  {
    return (Boolean)getAttributeInternal(BM2VENDORNUMBER2RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2VendorNumber2Render
   */
  public void setBm2VendorNumber2Render(Boolean value)
  {
    setAttributeInternal(BM2VENDORNUMBER2RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3VendorNumber1Render
   */
  public Boolean getBm3VendorNumber1Render()
  {
    return (Boolean)getAttributeInternal(BM3VENDORNUMBER1RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3VendorNumber1Render
   */
  public void setBm3VendorNumber1Render(Boolean value)
  {
    setAttributeInternal(BM3VENDORNUMBER1RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3VendorNumber2Render
   */
  public Boolean getBm3VendorNumber2Render()
  {
    return (Boolean)getAttributeInternal(BM3VENDORNUMBER2RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3VendorNumber2Render
   */
  public void setBm3VendorNumber2Render(Boolean value)
  {
    setAttributeInternal(BM3VENDORNUMBER2RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ActPoBaseCode
   */
  public String getActPoBaseCode()
  {
    return (String)getAttributeInternal(ACTPOBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ActPoBaseCode
   */
  public void setActPoBaseCode(String value)
  {
    setAttributeInternal(ACTPOBASECODE, value);
  }



































}