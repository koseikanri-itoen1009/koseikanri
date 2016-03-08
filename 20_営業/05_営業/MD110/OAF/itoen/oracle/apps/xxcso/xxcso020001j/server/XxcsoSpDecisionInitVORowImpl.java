/*============================================================================
* ファイル名 : XxcsoSpDecisionInitVORowImpl
* 概要説明   : SP専決初期化用ビュー行クラス
* バージョン : 1.3
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS小川浩     新規作成
* 2011-04-25 1.1  SCS桐生和幸   [E_本稼動_07224]SP専決参照権限変更対応
* 2014-12-30 1.2  SCSK桐生和幸  [E_本稼動_12565]SP・契約書画面改修対応
* 2016-01-07 1.3  SCSK山下翔太  [E_本稼動_13456]自販機管理システム代替対応
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
  protected static final int APPLICATIONTYPEVIEWRENDER = 13;
  protected static final int APPLICATIONTYPERENDER = 14;
  protected static final int INSTALLACCTNUMBERVIEWRENDER = 15;
  protected static final int INSTALLACCTNUMBER1RENDER = 16;
  protected static final int INSTALLACCTNUMBER2RENDER = 17;
  protected static final int INSTALLPARTYNAMEVIEWRENDER = 18;
  protected static final int INSTALLPARTYNAMERENDER = 19;
  protected static final int INSTALLPARTYNAMEALTVIEWRENDER = 20;
  protected static final int INSTALLPARTYNAMEALTRENDER = 21;
  protected static final int INSTALLNAMEVIEWRENDER = 22;
  protected static final int INSTALLNAMERENDER = 23;
  protected static final int INSTALLPOSTCDFVIEWRENDER = 24;
  protected static final int INSTALLPOSTCDFRENDER = 25;
  protected static final int INSTALLPOSTCDSVIEWRENDER = 26;
  protected static final int INSTALLPOSTCDSRENDER = 27;
  protected static final int INSTALLSTATEVIEWRENDER = 28;
  protected static final int INSTALLSTATERENDER = 29;
  protected static final int INSTALLCITYVIEWRENDER = 30;
  protected static final int INSTALLCITYRENDER = 31;
  protected static final int INSTALLADDRESS1VIEWRENDER = 32;
  protected static final int INSTALLADDRESS1RENDER = 33;
  protected static final int INSTALLADDRESS2VIEWRENDER = 34;
  protected static final int INSTALLADDRESS2RENDER = 35;
  protected static final int INSTALLADDRESSLINEVIEWRENDER = 36;
  protected static final int INSTALLADDRESSLINERENDER = 37;
  protected static final int BIZCONDTYPEVIEWRENDER = 38;
  protected static final int BIZCONDTYPERENDER = 39;
  protected static final int BUSINESSTYPEVIEWRENDER = 40;
  protected static final int BUSINESSTYPERENDER = 41;
  protected static final int INSTALLLOCATIONVIEWRENDER = 42;
  protected static final int INSTALLLOCATIONRENDER = 43;
  protected static final int EXTREFOPCLTYPEVIEWRENDER = 44;
  protected static final int EXTREFOPCLTYPERENDER = 45;
  protected static final int EMPLOYEENUMBERVIEWRENDER = 46;
  protected static final int EMPLOYEENUMBERRENDER = 47;
  protected static final int PUBLISHBASECODEVIEWRENDER = 48;
  protected static final int PUBLISHBASECODERENDER = 49;
  protected static final int INSTALLDATEREQUIREDVIEWRENDER = 50;
  protected static final int INSTALLDATEREQUIREDRENDER = 51;
  protected static final int INSTALLDATEVIEWRENDER = 52;
  protected static final int INSTALLDATERENDER = 53;
  protected static final int LEASECOMPANYVIEWRENDER = 54;
  protected static final int LEASECOMPANYRENDER = 55;
  protected static final int SAMEINSTALLACCTFLAGVIEWRENDER = 56;
  protected static final int SAMEINSTALLACCTFLAGRENDER = 57;
  protected static final int CONTRACTNUMBERVIEWRENDER = 58;
  protected static final int CONTRACTNUMBER1RENDER = 59;
  protected static final int CONTRACTNUMBER2RENDER = 60;
  protected static final int CONTRACTNAMEVIEWRENDER = 61;
  protected static final int CONTRACTNAMERENDER = 62;
  protected static final int CONTRACTNAMEALTVIEWRENDER = 63;
  protected static final int CONTRACTNAMEALTRENDER = 64;
  protected static final int CONTRACTPOSTCDFVIEWRENDER = 65;
  protected static final int CONTRACTPOSTCDFRENDER = 66;
  protected static final int CONTRACTPOSTCDSVIEWRENDER = 67;
  protected static final int CONTRACTPOSTCDSRENDER = 68;
  protected static final int CONTRACTSTATEVIEWRENDER = 69;
  protected static final int CONTRACTSTATERENDER = 70;
  protected static final int CONTRACTCITYVIEWRENDER = 71;
  protected static final int CONTRACTCITYRENDER = 72;
  protected static final int CONTRACTADDRESS1VIEWRENDER = 73;
  protected static final int CONTRACTADDRESS1RENDER = 74;
  protected static final int CONTRACTADDRESS2VIEWRENDER = 75;
  protected static final int CONTRACTADDRESS2RENDER = 76;
  protected static final int CONTRACTADDRESSLINEVIEWRENDER = 77;
  protected static final int CONTRACTADDRESSLINERENDER = 78;
  protected static final int DELEGATENAMEVIEWRENDER = 79;
  protected static final int DELEGATENAMERENDER = 80;
  protected static final int NEWOLDTYPEVIEWRENDER = 81;
  protected static final int NEWOLDTYPERENDER = 82;
  protected static final int SELENUMBERVIEWRENDER = 83;
  protected static final int SELENUMBERRENDER = 84;
  protected static final int MAKERCODEVIEWRENDER = 85;
  protected static final int MAKERCODERENDER = 86;
  protected static final int STANDARDTYPEVIEWRENDER = 87;
  protected static final int STANDARDTYPERENDER = 88;
  protected static final int UNNUMBERVIEWRENDER = 89;
  protected static final int UNNUMBERRENDER = 90;
  protected static final int CONDBIZTYPEVIEWRENDER = 91;
  protected static final int CONDBIZTYPERENDER = 92;
  protected static final int SALESCONDITIONHDRRNRENDER = 93;
  protected static final int SCBM2GRPRENDER = 94;
  protected static final int SCCONTRIBUTEGRPRENDER = 95;
  protected static final int SCACTIONFLRNRENDER = 96;
  protected static final int SCTABLEFOOTERRENDER = 97;
  protected static final int CONTAINERCONDITIONHDRRNRENDER = 98;
  protected static final int ALLCONTAINERTYPEVIEWRENDER = 99;
  protected static final int ALLCONTAINERTYPERENDER = 100;
  protected static final int ALLCCADVTBLRNRENDER = 101;
  protected static final int ALLCCBM2GRPRENDER = 102;
  protected static final int ALLCCCONTRIBUTEGRPRENDER = 103;
  protected static final int ALLCCACTIONFLRNRENDER = 104;
  protected static final int SELCCADVTBLRNRENDER = 105;
  protected static final int SELCCBM2GRPRENDER = 106;
  protected static final int SELCCCONTRIBUTEGRPRENDER = 107;
  protected static final int SELCCACTIONFLRNRENDER = 108;
  protected static final int CONTRACTYEARDATEVIEWRENDER = 109;
  protected static final int CONTRACTYEARDATERENDER = 110;
  protected static final int INSTALLSUPPORTAMTVIEWRENDER = 111;
  protected static final int INSTALLSUPPORTAMTRENDER = 112;
  protected static final int INSTALLSUPPORTAMT2VIEWRENDER = 113;
  protected static final int INSTALLSUPPORTAMT2RENDER = 114;
  protected static final int PAYMENTCYCLEVIEWRENDER = 115;
  protected static final int PAYMENTCYCLERENDER = 116;
  protected static final int ELECSTARTREQUIREDLABELRENDER = 117;
  protected static final int ELECSTARTLABELRENDER = 118;
  protected static final int ELECTRICITYTYPEVIEWRENDER = 119;
  protected static final int ELECTRICITYTYPERENDER = 120;
  protected static final int ELECTRICITYAMOUNTVIEWRENDER = 121;
  protected static final int ELECTRICITYAMOUNTRENDER = 122;
  protected static final int ELECAMOUNTLABELRENDER = 123;
  protected static final int CONDITIONREASONVIEWRENDER = 124;
  protected static final int CONDITIONREASONRENDER = 125;
  protected static final int BM1INFOHDRRNRENDER = 126;
  protected static final int BM1SENDTYPEVIEWRENDER = 127;
  protected static final int BM1SENDTYPERENDER = 128;
  protected static final int BM1VENDORNUMBERVIEWRENDER = 129;
  protected static final int BM1VENDORNUMBER1RENDER = 130;
  protected static final int BM1VENDORNUMBER2RENDER = 131;
  protected static final int BM1VENDORNAMEVIEWRENDER = 132;
  protected static final int BM1VENDORNAMERENDER = 133;
  protected static final int BM1VENDORNAMEALTVIEWRENDER = 134;
  protected static final int BM1VENDORNAMEALTRENDER = 135;
  protected static final int BM1TRANSFERTYPELAYOUTRENDER = 136;
  protected static final int BM1TRANSFERTYPEVIEWRENDER = 137;
  protected static final int BM1TRANSFERTYPERENDER = 138;
  protected static final int BM1PAYMENTTYPEVIEWRENDER = 139;
  protected static final int BM1PAYMENTTYPERENDER = 140;
  protected static final int BM1INQUIRYBASELAYOUTRENDER = 141;
  protected static final int BM1POSTALCODELAYOUTRENDER = 142;
  protected static final int BM1POSTCDFVIEWRENDER = 143;
  protected static final int BM1POSTCDFRENDER = 144;
  protected static final int BM1POSTCDSVIEWRENDER = 145;
  protected static final int BM1POSTCDSRENDER = 146;
  protected static final int BM1STATEVIEWRENDER = 147;
  protected static final int BM1STATERENDER = 148;
  protected static final int BM1CITYVIEWRENDER = 149;
  protected static final int BM1CITYRENDER = 150;
  protected static final int BM1ADDRESS1VIEWRENDER = 151;
  protected static final int BM1ADDRESS1RENDER = 152;
  protected static final int BM1ADDRESS2VIEWRENDER = 153;
  protected static final int BM1ADDRESS2RENDER = 154;
  protected static final int BM1ADDRESSLINEVIEWRENDER = 155;
  protected static final int BM1ADDRESSLINERENDER = 156;
  protected static final int BM2INFOHDRRNRENDER = 157;
  protected static final int CONTRIBUTEINFOHDRRNRENDER = 158;
  protected static final int BM2VENDORNUMBERVIEWRENDER = 159;
  protected static final int BM2VENDORNUMBER1RENDER = 160;
  protected static final int BM2VENDORNUMBER2RENDER = 161;
  protected static final int BM2VENDORNAMEVIEWRENDER = 162;
  protected static final int BM2VENDORNAMERENDER = 163;
  protected static final int BM2VENDORNAMEALTVIEWRENDER = 164;
  protected static final int BM2VENDORNAMEALTRENDER = 165;
  protected static final int BM2POSTALCODELAYOUTRENDER = 166;
  protected static final int BM2POSTCDFVIEWRENDER = 167;
  protected static final int BM2POSTCDFRENDER = 168;
  protected static final int BM2POSTCDSVIEWRENDER = 169;
  protected static final int BM2POSTCDSRENDER = 170;
  protected static final int BM2STATEVIEWRENDER = 171;
  protected static final int BM2STATERENDER = 172;
  protected static final int BM2CITYVIEWRENDER = 173;
  protected static final int BM2CITYRENDER = 174;
  protected static final int BM2ADDRESS1VIEWRENDER = 175;
  protected static final int BM2ADDRESS1RENDER = 176;
  protected static final int BM2ADDRESS2VIEWRENDER = 177;
  protected static final int BM2ADDRESS2RENDER = 178;
  protected static final int BM2ADDRESSLINEVIEWRENDER = 179;
  protected static final int BM2ADDRESSLINERENDER = 180;
  protected static final int BM2TRANSFERTYPELAYOUTRENDER = 181;
  protected static final int BM2TRANSFERTYPEVIEWRENDER = 182;
  protected static final int BM2TRANSFERTYPERENDER = 183;
  protected static final int BM2PAYMENTTYPEVIEWRENDER = 184;
  protected static final int BM2PAYMENTTYPERENDER = 185;
  protected static final int BM2INQUIRYBASELAYOUTRENDER = 186;
  protected static final int BM3INFOHDRRNRENDER = 187;
  protected static final int BM3VENDORNUMBERVIEWRENDER = 188;
  protected static final int BM3VENDORNUMBER1RENDER = 189;
  protected static final int BM3VENDORNUMBER2RENDER = 190;
  protected static final int BM3VENDORNAMEVIEWRENDER = 191;
  protected static final int BM3VENDORNAMERENDER = 192;
  protected static final int BM3VENDORNAMEALTVIEWRENDER = 193;
  protected static final int BM3VENDORNAMEALTRENDER = 194;
  protected static final int BM3POSTALCODELAYOUTRENDER = 195;
  protected static final int BM3POSTCDFVIEWRENDER = 196;
  protected static final int BM3POSTCDFRENDER = 197;
  protected static final int BM3POSTCDSVIEWRENDER = 198;
  protected static final int BM3POSTCDSRENDER = 199;
  protected static final int BM3STATEVIEWRENDER = 200;
  protected static final int BM3STATERENDER = 201;
  protected static final int BM3CITYVIEWRENDER = 202;
  protected static final int BM3CITYRENDER = 203;
  protected static final int BM3ADDRESS1VIEWRENDER = 204;
  protected static final int BM3ADDRESS1RENDER = 205;
  protected static final int BM3ADDRESS2VIEWRENDER = 206;
  protected static final int BM3ADDRESS2RENDER = 207;
  protected static final int BM3ADDRESSLINEVIEWRENDER = 208;
  protected static final int BM3ADDRESSLINERENDER = 209;
  protected static final int BM3TRANSFERTYPELAYOUTRENDER = 210;
  protected static final int BM3TRANSFERTYPEVIEWRENDER = 211;
  protected static final int BM3TRANSFERTYPERENDER = 212;
  protected static final int BM3PAYMENTTYPEVIEWRENDER = 213;
  protected static final int BM3PAYMENTTYPERENDER = 214;
  protected static final int BM3INQUIRYBASELAYOUTRENDER = 215;
  protected static final int REFLECTCONTRACTBUTTONRENDER = 216;
  protected static final int CNTRCTELECSPACER2RENDER = 217;
  protected static final int OTHERCONTENTVIEWRENDER = 218;
  protected static final int OTHERCONTENTRENDER = 219;
  protected static final int CALCPROFITBUTTONRENDER = 220;
  protected static final int SALESMONTHVIEWRENDER = 221;
  protected static final int SALESMONTHRENDER = 222;
  protected static final int BMRATEVIEWRENDER = 223;
  protected static final int BMRATERENDER = 224;
  protected static final int LEASECHARGEMONTHVIEWRENDER = 225;
  protected static final int LEASECHARGEMONTHRENDER = 226;
  protected static final int CONSTRUCTIONCHARGEVIEWRENDER = 227;
  protected static final int CONSTRUCTIONCHARGERENDER = 228;
  protected static final int ELECTRICITYAMTMONTHVIEWRENDER = 229;
  protected static final int ELECTRICITYAMTMONTHRENDER = 230;
  protected static final int ATTACHACTIONFLRNRENDER = 231;
  protected static final int ACTPOBASECODE = 232;
  protected static final int CONTRACTYEARMONTHRENDER = 233;
  protected static final int CONTRACTYEARMONTHVIEWRENDER = 234;
  protected static final int CONTRACTSTARTYEARRENDER = 235;
  protected static final int CONTRACTSTARTYEARVIEWRENDER = 236;
  protected static final int CONTRACTSTARTMONTHRENDER = 237;
  protected static final int CONTRACTSTARTMONTHVIEWRENDER = 238;
  protected static final int CONTRACTENDYEARRENDER = 239;
  protected static final int CONTRACTENDYEARVIEWRENDER = 240;
  protected static final int CONTRACTENDMONTHRENDER = 241;
  protected static final int CONTRACTENDMONTHVIEWRENDER = 242;
  protected static final int BIDDINGITEMRENDER = 243;
  protected static final int BIDDINGITEMVIEWRENDER = 244;
  protected static final int CANCELLBEFOREMATURITYRENDER = 245;
  protected static final int CANCELLBEFOREMATURITYVIEWRENDER = 246;
  protected static final int ADASSETSTYPERENDER = 247;
  protected static final int ADASSETSTYPEVIEWRENDER = 248;
  protected static final int OTHERCONDITIONRLRN06RENDER = 249;
  protected static final int ADASSETSAMTRENDER = 250;
  protected static final int ADASSETSAMTVIEWRENDER = 251;
  protected static final int ADASSETSTHISTIMERENDER = 252;
  protected static final int ADASSETSTHISTIMEVIEWRENDER = 253;
  protected static final int ADASSETSPAYMENTYEARRENDER = 254;
  protected static final int ADASSETSPAYMENTYEARVIEWRENDER = 255;
  protected static final int ADASSETSPAYMENTDATERENDER = 256;
  protected static final int ADASSETSPAYMENTDATEVIEWRENDER = 257;
  protected static final int OTHERCONDITIONRLRN07RENDER = 258;
  protected static final int TAXTYPERENDER = 259;
  protected static final int TAXTYPEVIEWRENDER = 260;
  protected static final int INSTALLSUPPTYPERENDER = 261;
  protected static final int INSTALLSUPPTYPEVIEWRENDER = 262;
  protected static final int INSTALLSUPPPAYMENTTYPERENDER = 263;
  protected static final int INSTALLSUPPPAYMENTTYPEVIEWRENDER = 264;
  protected static final int INSTALLSUPPAMTRENDER = 265;
  protected static final int INSTALLSUPPAMTVIEWRENDER = 266;
  protected static final int INSTALLSUPPTHISTIMERENDER = 267;
  protected static final int INSTALLSUPPTHISTIMEVIEWRENDER = 268;
  protected static final int INSTALLSUPPPAYMENTYEARRENDER = 269;
  protected static final int INSTALLSUPPPAYMENTYEARVIEWRENDER = 270;
  protected static final int INSTALLSUPPPAYMENTDATERENDER = 271;
  protected static final int INSTALLSUPPPAYMENTDATEVIEWRENDER = 272;
  protected static final int ELECTRICTYPERENDER = 273;
  protected static final int ELECTRICTYPEVIEWRENDER = 274;
  protected static final int ELECTRICPAYMENTTYPERENDER = 275;
  protected static final int ELECTRICPAYMENTTYPEVIEWRENDER = 276;
  protected static final int ELECTRICPAYMENTCHANGETYPERENDER = 277;
  protected static final int ELECTRICPAYMENTCHANGETYPEVIEWRENDER = 278;
  protected static final int ELECTRICPAYMENTCYCLERENDER = 279;
  protected static final int ELECTRICPAYMENTCYCLEVIEWRENDER = 280;
  protected static final int ELECTRICCLOSINGDATERENDER = 281;
  protected static final int ELECTRICCLOSINGDATEVIEWRENDER = 282;
  protected static final int ELECTRICTRANSMONTHRENDER = 283;
  protected static final int ELECTRICTRANSMONTHVIEWRENDER = 284;
  protected static final int ELECTRICTRANSDATERENDER = 285;
  protected static final int ELECTRICTRANSDATEVIEWRENDER = 286;
  protected static final int ELECTRICTRANSNAMERENDER = 287;
  protected static final int ELECTRICTRANSNAMEVIEWRENDER = 288;
  protected static final int ELECTRICTRANSNAMEALTRENDER = 289;
  protected static final int ELECTRICTRANSNAMEALTVIEWRENDER = 290;
  protected static final int INTROCHGTYPERENDER = 291;
  protected static final int INTROCHGTYPEVIEWRENDER = 292;
  protected static final int INTROCHGTYPEHDRRNRENDER = 293;
  protected static final int INTROCHGPAYMENTTYPERENDER = 294;
  protected static final int INTROCHGPAYMENTTYPEVIEWRENDER = 295;
  protected static final int INTROCHGAMTRENDER = 296;
  protected static final int INTROCHGAMTVIEWRENDER = 297;
  protected static final int INTROCHGTHISTIMERENDER = 298;
  protected static final int INTROCHGTHISTIMEVIEWRENDER = 299;
  protected static final int INTROCHGPAYMENTYEARRENDER = 300;
  protected static final int INTROCHGPAYMENTYEARVIEWRENDER = 301;
  protected static final int INTROCHGPAYMENTDATERENDER = 302;
  protected static final int INTROCHGPAYMENTDATEVIEWRENDER = 303;
  protected static final int INTROCHGPERSALESPRICERENDER = 304;
  protected static final int INTROCHGPERSALESPRICEVIEWRENDER = 305;
  protected static final int INTROCHGPERPIECERENDER = 306;
  protected static final int INTROCHGPERPIECEVIEWRENDER = 307;
  protected static final int INTROCHGCLOSINGDATERENDER = 308;
  protected static final int INTROCHGCLOSINGDATEVIEWRENDER = 309;
  protected static final int INTROCHGTRANSMONTHRENDER = 310;
  protected static final int INTROCHGTRANSMONTHVIEWRENDER = 311;
  protected static final int INTROCHGTRANSDATERENDER = 312;
  protected static final int INTROCHGTRANSDATEVIEWRENDER = 313;
  protected static final int INTROCHGTRANSNAMERENDER = 314;
  protected static final int INTROCHGTRANSNAMEVIEWRENDER = 315;
  protected static final int INTROCHGTRANSNAMEALTRENDER = 316;
  protected static final int INTROCHGTRANSNAMEALTVIEWRENDER = 317;
  protected static final int INSTALLSUPPPAYMENTTYPEHDRRNRENDER = 318;
  protected static final int INSTALLSUPPTHISTIMELABELRENDER = 319;
  protected static final int INSTALLSUPPTHISTIMEENDLABELRENDER = 320;
  protected static final int INSTALLSUPPPAYMENTYEARENDLABEL1RENDER = 321;
  protected static final int INSTALLSUPPPAYMENTYEARENDLABEL2RENDER = 322;
  protected static final int ELECTRICPAYMENTTYPEHDRRNRENDER = 323;
  protected static final int ELECTRICINFORIRN02RENDER = 324;
  protected static final int ELECTRICINFORIRN03RENDER = 325;
  protected static final int ELECTRICINFORIRN04RENDER = 326;
  protected static final int ELECTRICINFORIRN05RENDER = 327;
  protected static final int ELECTRICINFORIRN06RENDER = 328;
  protected static final int INTROCHGINFORIRN01RENDER = 329;
  protected static final int INTROCHGINFORIRN02RENDER = 330;
  protected static final int INTROCHGPERSALESPRICELABELRENDER = 331;
  protected static final int INTROCHGPERPIECELABELRENDER = 332;
  protected static final int INTROCHGPERSALESPRICEENDLABELRENDER = 333;
  protected static final int INTROCHGPERPIECEENDLABELRENDER = 334;
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
      case CONTRACTYEARMONTHRENDER:
        return getContractYearMonthRender();
      case CONTRACTYEARMONTHVIEWRENDER:
        return getContractYearMonthViewRender();
      case CONTRACTSTARTYEARRENDER:
        return getContractStartYearRender();
      case CONTRACTSTARTYEARVIEWRENDER:
        return getContractStartYearViewRender();
      case CONTRACTSTARTMONTHRENDER:
        return getContractStartMonthRender();
      case CONTRACTSTARTMONTHVIEWRENDER:
        return getContractStartMonthViewRender();
      case CONTRACTENDYEARRENDER:
        return getContractEndYearRender();
      case CONTRACTENDYEARVIEWRENDER:
        return getContractEndYearViewRender();
      case CONTRACTENDMONTHRENDER:
        return getContractEndMonthRender();
      case CONTRACTENDMONTHVIEWRENDER:
        return getContractEndMonthViewRender();
      case BIDDINGITEMRENDER:
        return getBiddingItemRender();
      case BIDDINGITEMVIEWRENDER:
        return getBiddingItemViewRender();
      case CANCELLBEFOREMATURITYRENDER:
        return getCancellBeforeMaturityRender();
      case CANCELLBEFOREMATURITYVIEWRENDER:
        return getCancellBeforeMaturityViewRender();
      case ADASSETSTYPERENDER:
        return getAdAssetsTypeRender();
      case ADASSETSTYPEVIEWRENDER:
        return getAdAssetsTypeViewRender();
      case OTHERCONDITIONRLRN06RENDER:
        return getOtherConditionRlRN06Render();
      case ADASSETSAMTRENDER:
        return getAdAssetsAmtRender();
      case ADASSETSAMTVIEWRENDER:
        return getAdAssetsAmtViewRender();
      case ADASSETSTHISTIMERENDER:
        return getAdAssetsThisTimeRender();
      case ADASSETSTHISTIMEVIEWRENDER:
        return getAdAssetsThisTimeViewRender();
      case ADASSETSPAYMENTYEARRENDER:
        return getAdAssetsPaymentYearRender();
      case ADASSETSPAYMENTYEARVIEWRENDER:
        return getAdAssetsPaymentYearViewRender();
      case ADASSETSPAYMENTDATERENDER:
        return getAdAssetsPaymentDateRender();
      case ADASSETSPAYMENTDATEVIEWRENDER:
        return getAdAssetsPaymentDateViewRender();
      case OTHERCONDITIONRLRN07RENDER:
        return getOtherConditionRlRN07Render();
      case TAXTYPERENDER:
        return getTaxTypeRender();
      case TAXTYPEVIEWRENDER:
        return getTaxTypeViewRender();
      case INSTALLSUPPTYPERENDER:
        return getInstallSuppTypeRender();
      case INSTALLSUPPTYPEVIEWRENDER:
        return getInstallSuppTypeViewRender();
      case INSTALLSUPPPAYMENTTYPERENDER:
        return getInstallSuppPaymentTypeRender();
      case INSTALLSUPPPAYMENTTYPEVIEWRENDER:
        return getInstallSuppPaymentTypeViewRender();
      case INSTALLSUPPAMTRENDER:
        return getInstallSuppAmtRender();
      case INSTALLSUPPAMTVIEWRENDER:
        return getInstallSuppAmtViewRender();
      case INSTALLSUPPTHISTIMERENDER:
        return getInstallSuppThisTimeRender();
      case INSTALLSUPPTHISTIMEVIEWRENDER:
        return getInstallSuppThisTimeViewRender();
      case INSTALLSUPPPAYMENTYEARRENDER:
        return getInstallSuppPaymentYearRender();
      case INSTALLSUPPPAYMENTYEARVIEWRENDER:
        return getInstallSuppPaymentYearViewRender();
      case INSTALLSUPPPAYMENTDATERENDER:
        return getInstallSuppPaymentDateRender();
      case INSTALLSUPPPAYMENTDATEVIEWRENDER:
        return getInstallSuppPaymentDateViewRender();
      case ELECTRICTYPERENDER:
        return getElectricTypeRender();
      case ELECTRICTYPEVIEWRENDER:
        return getElectricTypeViewRender();
      case ELECTRICPAYMENTTYPERENDER:
        return getElectricPaymentTypeRender();
      case ELECTRICPAYMENTTYPEVIEWRENDER:
        return getElectricPaymentTypeViewRender();
      case ELECTRICPAYMENTCHANGETYPERENDER:
        return getElectricPaymentChangeTypeRender();
      case ELECTRICPAYMENTCHANGETYPEVIEWRENDER:
        return getElectricPaymentChangeTypeViewRender();
      case ELECTRICPAYMENTCYCLERENDER:
        return getElectricPaymentCycleRender();
      case ELECTRICPAYMENTCYCLEVIEWRENDER:
        return getElectricPaymentCycleViewRender();
      case ELECTRICCLOSINGDATERENDER:
        return getElectricClosingDateRender();
      case ELECTRICCLOSINGDATEVIEWRENDER:
        return getElectricClosingDateViewRender();
      case ELECTRICTRANSMONTHRENDER:
        return getElectricTransMonthRender();
      case ELECTRICTRANSMONTHVIEWRENDER:
        return getElectricTransMonthViewRender();
      case ELECTRICTRANSDATERENDER:
        return getElectricTransDateRender();
      case ELECTRICTRANSDATEVIEWRENDER:
        return getElectricTransDateViewRender();
      case ELECTRICTRANSNAMERENDER:
        return getElectricTransNameRender();
      case ELECTRICTRANSNAMEVIEWRENDER:
        return getElectricTransNameViewRender();
      case ELECTRICTRANSNAMEALTRENDER:
        return getElectricTransNameAltRender();
      case ELECTRICTRANSNAMEALTVIEWRENDER:
        return getElectricTransNameAltViewRender();
      case INTROCHGTYPERENDER:
        return getIntroChgTypeRender();
      case INTROCHGTYPEVIEWRENDER:
        return getIntroChgTypeViewRender();
      case INTROCHGTYPEHDRRNRENDER:
        return getIntroChgTypeHdrRNRender();
      case INTROCHGPAYMENTTYPERENDER:
        return getIntroChgPaymentTypeRender();
      case INTROCHGPAYMENTTYPEVIEWRENDER:
        return getIntroChgPaymentTypeViewRender();
      case INTROCHGAMTRENDER:
        return getIntroChgAmtRender();
      case INTROCHGAMTVIEWRENDER:
        return getIntroChgAmtViewRender();
      case INTROCHGTHISTIMERENDER:
        return getIntroChgThisTimeRender();
      case INTROCHGTHISTIMEVIEWRENDER:
        return getIntroChgThisTimeViewRender();
      case INTROCHGPAYMENTYEARRENDER:
        return getIntroChgPaymentYearRender();
      case INTROCHGPAYMENTYEARVIEWRENDER:
        return getIntroChgPaymentYearViewRender();
      case INTROCHGPAYMENTDATERENDER:
        return getIntroChgPaymentDateRender();
      case INTROCHGPAYMENTDATEVIEWRENDER:
        return getIntroChgPaymentDateViewRender();
      case INTROCHGPERSALESPRICERENDER:
        return getIntroChgPerSalesPriceRender();
      case INTROCHGPERSALESPRICEVIEWRENDER:
        return getIntroChgPerSalesPriceViewRender();
      case INTROCHGPERPIECERENDER:
        return getIntroChgPerPieceRender();
      case INTROCHGPERPIECEVIEWRENDER:
        return getIntroChgPerPieceViewRender();
      case INTROCHGCLOSINGDATERENDER:
        return getIntroChgClosingDateRender();
      case INTROCHGCLOSINGDATEVIEWRENDER:
        return getIntroChgClosingDateViewRender();
      case INTROCHGTRANSMONTHRENDER:
        return getIntroChgTransMonthRender();
      case INTROCHGTRANSMONTHVIEWRENDER:
        return getIntroChgTransMonthViewRender();
      case INTROCHGTRANSDATERENDER:
        return getIntroChgTransDateRender();
      case INTROCHGTRANSDATEVIEWRENDER:
        return getIntroChgTransDateViewRender();
      case INTROCHGTRANSNAMERENDER:
        return getIntroChgTransNameRender();
      case INTROCHGTRANSNAMEVIEWRENDER:
        return getIntroChgTransNameViewRender();
      case INTROCHGTRANSNAMEALTRENDER:
        return getIntroChgTransNameAltRender();
      case INTROCHGTRANSNAMEALTVIEWRENDER:
        return getIntroChgTransNameAltViewRender();
      case INSTALLSUPPPAYMENTTYPEHDRRNRENDER:
        return getInstallSuppPaymentTypeHdrRNRender();
      case INSTALLSUPPTHISTIMELABELRENDER:
        return getInstallSuppThisTimeLabelRender();
      case INSTALLSUPPTHISTIMEENDLABELRENDER:
        return getInstallSuppThisTimeEndLabelRender();
      case INSTALLSUPPPAYMENTYEARENDLABEL1RENDER:
        return getInstallSuppPaymentYearEndLabel1Render();
      case INSTALLSUPPPAYMENTYEARENDLABEL2RENDER:
        return getInstallSuppPaymentYearEndLabel2Render();
      case ELECTRICPAYMENTTYPEHDRRNRENDER:
        return getElectricPaymentTypeHdrRNRender();
      case ELECTRICINFORIRN02RENDER:
        return getElectricInfoRIRN02Render();
      case ELECTRICINFORIRN03RENDER:
        return getElectricInfoRIRN03Render();
      case ELECTRICINFORIRN04RENDER:
        return getElectricInfoRIRN04Render();
      case ELECTRICINFORIRN05RENDER:
        return getElectricInfoRIRN05Render();
      case ELECTRICINFORIRN06RENDER:
        return getElectricInfoRIRN06Render();
      case INTROCHGINFORIRN01RENDER:
        return getIntroChgInfoRIRN01Render();
      case INTROCHGINFORIRN02RENDER:
        return getIntroChgInfoRIRN02Render();
      case INTROCHGPERSALESPRICELABELRENDER:
        return getIntroChgPerSalesPriceLabelRender();
      case INTROCHGPERPIECELABELRENDER:
        return getIntroChgPerPieceLabelRender();
      case INTROCHGPERSALESPRICEENDLABELRENDER:
        return getIntroChgPerSalesPriceEndLabelRender();
      case INTROCHGPERPIECEENDLABELRENDER:
        return getIntroChgPerPieceEndLabelRender();
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
      case CONTRACTYEARMONTHRENDER:
        setContractYearMonthRender((Boolean)value);
        return;
      case CONTRACTYEARMONTHVIEWRENDER:
        setContractYearMonthViewRender((Boolean)value);
        return;
      case CONTRACTSTARTYEARRENDER:
        setContractStartYearRender((Boolean)value);
        return;
      case CONTRACTSTARTYEARVIEWRENDER:
        setContractStartYearViewRender((Boolean)value);
        return;
      case CONTRACTSTARTMONTHRENDER:
        setContractStartMonthRender((Boolean)value);
        return;
      case CONTRACTSTARTMONTHVIEWRENDER:
        setContractStartMonthViewRender((Boolean)value);
        return;
      case CONTRACTENDYEARRENDER:
        setContractEndYearRender((Boolean)value);
        return;
      case CONTRACTENDYEARVIEWRENDER:
        setContractEndYearViewRender((Boolean)value);
        return;
      case CONTRACTENDMONTHRENDER:
        setContractEndMonthRender((Boolean)value);
        return;
      case CONTRACTENDMONTHVIEWRENDER:
        setContractEndMonthViewRender((Boolean)value);
        return;
      case BIDDINGITEMRENDER:
        setBiddingItemRender((Boolean)value);
        return;
      case BIDDINGITEMVIEWRENDER:
        setBiddingItemViewRender((Boolean)value);
        return;
      case CANCELLBEFOREMATURITYRENDER:
        setCancellBeforeMaturityRender((Boolean)value);
        return;
      case CANCELLBEFOREMATURITYVIEWRENDER:
        setCancellBeforeMaturityViewRender((Boolean)value);
        return;
      case ADASSETSTYPERENDER:
        setAdAssetsTypeRender((Boolean)value);
        return;
      case ADASSETSTYPEVIEWRENDER:
        setAdAssetsTypeViewRender((Boolean)value);
        return;
      case OTHERCONDITIONRLRN06RENDER:
        setOtherConditionRlRN06Render((Boolean)value);
        return;
      case ADASSETSAMTRENDER:
        setAdAssetsAmtRender((Boolean)value);
        return;
      case ADASSETSAMTVIEWRENDER:
        setAdAssetsAmtViewRender((Boolean)value);
        return;
      case ADASSETSTHISTIMERENDER:
        setAdAssetsThisTimeRender((Boolean)value);
        return;
      case ADASSETSTHISTIMEVIEWRENDER:
        setAdAssetsThisTimeViewRender((Boolean)value);
        return;
      case ADASSETSPAYMENTYEARRENDER:
        setAdAssetsPaymentYearRender((Boolean)value);
        return;
      case ADASSETSPAYMENTYEARVIEWRENDER:
        setAdAssetsPaymentYearViewRender((Boolean)value);
        return;
      case ADASSETSPAYMENTDATERENDER:
        setAdAssetsPaymentDateRender((Boolean)value);
        return;
      case ADASSETSPAYMENTDATEVIEWRENDER:
        setAdAssetsPaymentDateViewRender((Boolean)value);
        return;
      case OTHERCONDITIONRLRN07RENDER:
        setOtherConditionRlRN07Render((Boolean)value);
        return;
      case TAXTYPERENDER:
        setTaxTypeRender((Boolean)value);
        return;
      case TAXTYPEVIEWRENDER:
        setTaxTypeViewRender((Boolean)value);
        return;
      case INSTALLSUPPTYPERENDER:
        setInstallSuppTypeRender((Boolean)value);
        return;
      case INSTALLSUPPTYPEVIEWRENDER:
        setInstallSuppTypeViewRender((Boolean)value);
        return;
      case INSTALLSUPPPAYMENTTYPERENDER:
        setInstallSuppPaymentTypeRender((Boolean)value);
        return;
      case INSTALLSUPPPAYMENTTYPEVIEWRENDER:
        setInstallSuppPaymentTypeViewRender((Boolean)value);
        return;
      case INSTALLSUPPAMTRENDER:
        setInstallSuppAmtRender((Boolean)value);
        return;
      case INSTALLSUPPAMTVIEWRENDER:
        setInstallSuppAmtViewRender((Boolean)value);
        return;
      case INSTALLSUPPTHISTIMERENDER:
        setInstallSuppThisTimeRender((Boolean)value);
        return;
      case INSTALLSUPPTHISTIMEVIEWRENDER:
        setInstallSuppThisTimeViewRender((Boolean)value);
        return;
      case INSTALLSUPPPAYMENTYEARRENDER:
        setInstallSuppPaymentYearRender((Boolean)value);
        return;
      case INSTALLSUPPPAYMENTYEARVIEWRENDER:
        setInstallSuppPaymentYearViewRender((Boolean)value);
        return;
      case INSTALLSUPPPAYMENTDATERENDER:
        setInstallSuppPaymentDateRender((Boolean)value);
        return;
      case INSTALLSUPPPAYMENTDATEVIEWRENDER:
        setInstallSuppPaymentDateViewRender((Boolean)value);
        return;
      case ELECTRICTYPERENDER:
        setElectricTypeRender((Boolean)value);
        return;
      case ELECTRICTYPEVIEWRENDER:
        setElectricTypeViewRender((Boolean)value);
        return;
      case ELECTRICPAYMENTTYPERENDER:
        setElectricPaymentTypeRender((Boolean)value);
        return;
      case ELECTRICPAYMENTTYPEVIEWRENDER:
        setElectricPaymentTypeViewRender((Boolean)value);
        return;
      case ELECTRICPAYMENTCHANGETYPERENDER:
        setElectricPaymentChangeTypeRender((Boolean)value);
        return;
      case ELECTRICPAYMENTCHANGETYPEVIEWRENDER:
        setElectricPaymentChangeTypeViewRender((Boolean)value);
        return;
      case ELECTRICPAYMENTCYCLERENDER:
        setElectricPaymentCycleRender((Boolean)value);
        return;
      case ELECTRICPAYMENTCYCLEVIEWRENDER:
        setElectricPaymentCycleViewRender((Boolean)value);
        return;
      case ELECTRICCLOSINGDATERENDER:
        setElectricClosingDateRender((Boolean)value);
        return;
      case ELECTRICCLOSINGDATEVIEWRENDER:
        setElectricClosingDateViewRender((Boolean)value);
        return;
      case ELECTRICTRANSMONTHRENDER:
        setElectricTransMonthRender((Boolean)value);
        return;
      case ELECTRICTRANSMONTHVIEWRENDER:
        setElectricTransMonthViewRender((Boolean)value);
        return;
      case ELECTRICTRANSDATERENDER:
        setElectricTransDateRender((Boolean)value);
        return;
      case ELECTRICTRANSDATEVIEWRENDER:
        setElectricTransDateViewRender((Boolean)value);
        return;
      case ELECTRICTRANSNAMERENDER:
        setElectricTransNameRender((Boolean)value);
        return;
      case ELECTRICTRANSNAMEVIEWRENDER:
        setElectricTransNameViewRender((Boolean)value);
        return;
      case ELECTRICTRANSNAMEALTRENDER:
        setElectricTransNameAltRender((Boolean)value);
        return;
      case ELECTRICTRANSNAMEALTVIEWRENDER:
        setElectricTransNameAltViewRender((Boolean)value);
        return;
      case INTROCHGTYPERENDER:
        setIntroChgTypeRender((Boolean)value);
        return;
      case INTROCHGTYPEVIEWRENDER:
        setIntroChgTypeViewRender((Boolean)value);
        return;
      case INTROCHGTYPEHDRRNRENDER:
        setIntroChgTypeHdrRNRender((Boolean)value);
        return;
      case INTROCHGPAYMENTTYPERENDER:
        setIntroChgPaymentTypeRender((Boolean)value);
        return;
      case INTROCHGPAYMENTTYPEVIEWRENDER:
        setIntroChgPaymentTypeViewRender((Boolean)value);
        return;
      case INTROCHGAMTRENDER:
        setIntroChgAmtRender((Boolean)value);
        return;
      case INTROCHGAMTVIEWRENDER:
        setIntroChgAmtViewRender((Boolean)value);
        return;
      case INTROCHGTHISTIMERENDER:
        setIntroChgThisTimeRender((Boolean)value);
        return;
      case INTROCHGTHISTIMEVIEWRENDER:
        setIntroChgThisTimeViewRender((Boolean)value);
        return;
      case INTROCHGPAYMENTYEARRENDER:
        setIntroChgPaymentYearRender((Boolean)value);
        return;
      case INTROCHGPAYMENTYEARVIEWRENDER:
        setIntroChgPaymentYearViewRender((Boolean)value);
        return;
      case INTROCHGPAYMENTDATERENDER:
        setIntroChgPaymentDateRender((Boolean)value);
        return;
      case INTROCHGPAYMENTDATEVIEWRENDER:
        setIntroChgPaymentDateViewRender((Boolean)value);
        return;
      case INTROCHGPERSALESPRICERENDER:
        setIntroChgPerSalesPriceRender((Boolean)value);
        return;
      case INTROCHGPERSALESPRICEVIEWRENDER:
        setIntroChgPerSalesPriceViewRender((Boolean)value);
        return;
      case INTROCHGPERPIECERENDER:
        setIntroChgPerPieceRender((Boolean)value);
        return;
      case INTROCHGPERPIECEVIEWRENDER:
        setIntroChgPerPieceViewRender((Boolean)value);
        return;
      case INTROCHGCLOSINGDATERENDER:
        setIntroChgClosingDateRender((Boolean)value);
        return;
      case INTROCHGCLOSINGDATEVIEWRENDER:
        setIntroChgClosingDateViewRender((Boolean)value);
        return;
      case INTROCHGTRANSMONTHRENDER:
        setIntroChgTransMonthRender((Boolean)value);
        return;
      case INTROCHGTRANSMONTHVIEWRENDER:
        setIntroChgTransMonthViewRender((Boolean)value);
        return;
      case INTROCHGTRANSDATERENDER:
        setIntroChgTransDateRender((Boolean)value);
        return;
      case INTROCHGTRANSDATEVIEWRENDER:
        setIntroChgTransDateViewRender((Boolean)value);
        return;
      case INTROCHGTRANSNAMERENDER:
        setIntroChgTransNameRender((Boolean)value);
        return;
      case INTROCHGTRANSNAMEVIEWRENDER:
        setIntroChgTransNameViewRender((Boolean)value);
        return;
      case INTROCHGTRANSNAMEALTRENDER:
        setIntroChgTransNameAltRender((Boolean)value);
        return;
      case INTROCHGTRANSNAMEALTVIEWRENDER:
        setIntroChgTransNameAltViewRender((Boolean)value);
        return;
      case INSTALLSUPPPAYMENTTYPEHDRRNRENDER:
        setInstallSuppPaymentTypeHdrRNRender((Boolean)value);
        return;
      case INSTALLSUPPTHISTIMELABELRENDER:
        setInstallSuppThisTimeLabelRender((Boolean)value);
        return;
      case INSTALLSUPPTHISTIMEENDLABELRENDER:
        setInstallSuppThisTimeEndLabelRender((Boolean)value);
        return;
      case INSTALLSUPPPAYMENTYEARENDLABEL1RENDER:
        setInstallSuppPaymentYearEndLabel1Render((Boolean)value);
        return;
      case INSTALLSUPPPAYMENTYEARENDLABEL2RENDER:
        setInstallSuppPaymentYearEndLabel2Render((Boolean)value);
        return;
      case ELECTRICPAYMENTTYPEHDRRNRENDER:
        setElectricPaymentTypeHdrRNRender((Boolean)value);
        return;
      case ELECTRICINFORIRN02RENDER:
        setElectricInfoRIRN02Render((Boolean)value);
        return;
      case ELECTRICINFORIRN03RENDER:
        setElectricInfoRIRN03Render((Boolean)value);
        return;
      case ELECTRICINFORIRN04RENDER:
        setElectricInfoRIRN04Render((Boolean)value);
        return;
      case ELECTRICINFORIRN05RENDER:
        setElectricInfoRIRN05Render((Boolean)value);
        return;
      case ELECTRICINFORIRN06RENDER:
        setElectricInfoRIRN06Render((Boolean)value);
        return;
      case INTROCHGINFORIRN01RENDER:
        setIntroChgInfoRIRN01Render((Boolean)value);
        return;
      case INTROCHGINFORIRN02RENDER:
        setIntroChgInfoRIRN02Render((Boolean)value);
        return;
      case INTROCHGPERSALESPRICELABELRENDER:
        setIntroChgPerSalesPriceLabelRender((Boolean)value);
        return;
      case INTROCHGPERPIECELABELRENDER:
        setIntroChgPerPieceLabelRender((Boolean)value);
        return;
      case INTROCHGPERSALESPRICEENDLABELRENDER:
        setIntroChgPerSalesPriceEndLabelRender((Boolean)value);
        return;
      case INTROCHGPERPIECEENDLABELRENDER:
        setIntroChgPerPieceEndLabelRender((Boolean)value);
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





  /**
   * 
   * Gets the attribute value for the calculated attribute ContractStartYearRender
   */
  public Boolean getContractStartYearRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTSTARTYEARRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractStartYearRender
   */
  public void setContractStartYearRender(Boolean value)
  {
    setAttributeInternal(CONTRACTSTARTYEARRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractStartYearViewRender
   */
  public Boolean getContractStartYearViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTSTARTYEARVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractStartYearViewRender
   */
  public void setContractStartYearViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTSTARTYEARVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractStartMonthRender
   */
  public Boolean getContractStartMonthRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTSTARTMONTHRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractStartMonthRender
   */
  public void setContractStartMonthRender(Boolean value)
  {
    setAttributeInternal(CONTRACTSTARTMONTHRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractStartMonthViewRender
   */
  public Boolean getContractStartMonthViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTSTARTMONTHVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractStartMonthViewRender
   */
  public void setContractStartMonthViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTSTARTMONTHVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractEndYearRender
   */
  public Boolean getContractEndYearRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTENDYEARRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractEndYearRender
   */
  public void setContractEndYearRender(Boolean value)
  {
    setAttributeInternal(CONTRACTENDYEARRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractEndYearViewRender
   */
  public Boolean getContractEndYearViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTENDYEARVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractEndYearViewRender
   */
  public void setContractEndYearViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTENDYEARVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractEndMonthRender
   */
  public Boolean getContractEndMonthRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTENDMONTHRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractEndMonthRender
   */
  public void setContractEndMonthRender(Boolean value)
  {
    setAttributeInternal(CONTRACTENDMONTHRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractEndMonthViewRender
   */
  public Boolean getContractEndMonthViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTENDMONTHVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractEndMonthViewRender
   */
  public void setContractEndMonthViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTENDMONTHVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BiddingItemRender
   */
  public Boolean getBiddingItemRender()
  {
    return (Boolean)getAttributeInternal(BIDDINGITEMRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BiddingItemRender
   */
  public void setBiddingItemRender(Boolean value)
  {
    setAttributeInternal(BIDDINGITEMRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BiddingItemViewRender
   */
  public Boolean getBiddingItemViewRender()
  {
    return (Boolean)getAttributeInternal(BIDDINGITEMVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BiddingItemViewRender
   */
  public void setBiddingItemViewRender(Boolean value)
  {
    setAttributeInternal(BIDDINGITEMVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CancellBeforeMaturityRender
   */
  public Boolean getCancellBeforeMaturityRender()
  {
    return (Boolean)getAttributeInternal(CANCELLBEFOREMATURITYRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CancellBeforeMaturityRender
   */
  public void setCancellBeforeMaturityRender(Boolean value)
  {
    setAttributeInternal(CANCELLBEFOREMATURITYRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CancellBeforeMaturityViewRender
   */
  public Boolean getCancellBeforeMaturityViewRender()
  {
    return (Boolean)getAttributeInternal(CANCELLBEFOREMATURITYVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CancellBeforeMaturityViewRender
   */
  public void setCancellBeforeMaturityViewRender(Boolean value)
  {
    setAttributeInternal(CANCELLBEFOREMATURITYVIEWRENDER, value);
  }

















  /**
   * 
   * Gets the attribute value for the calculated attribute ContractYearMonthViewRender
   */
  public Boolean getContractYearMonthViewRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTYEARMONTHVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractYearMonthViewRender
   */
  public void setContractYearMonthViewRender(Boolean value)
  {
    setAttributeInternal(CONTRACTYEARMONTHVIEWRENDER, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute AdAssetsTypeViewRender
   */
  public Boolean getAdAssetsTypeViewRender()
  {
    return (Boolean)getAttributeInternal(ADASSETSTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AdAssetsTypeViewRender
   */
  public void setAdAssetsTypeViewRender(Boolean value)
  {
    setAttributeInternal(ADASSETSTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OtherConditionRlRN06Render
   */
  public Boolean getOtherConditionRlRN06Render()
  {
    return (Boolean)getAttributeInternal(OTHERCONDITIONRLRN06RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OtherConditionRlRN06Render
   */
  public void setOtherConditionRlRN06Render(Boolean value)
  {
    setAttributeInternal(OTHERCONDITIONRLRN06RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AdAssetsTypeRender
   */
  public Boolean getAdAssetsTypeRender()
  {
    return (Boolean)getAttributeInternal(ADASSETSTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AdAssetsTypeRender
   */
  public void setAdAssetsTypeRender(Boolean value)
  {
    setAttributeInternal(ADASSETSTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AdAssetsAmtRender
   */
  public Boolean getAdAssetsAmtRender()
  {
    return (Boolean)getAttributeInternal(ADASSETSAMTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AdAssetsAmtRender
   */
  public void setAdAssetsAmtRender(Boolean value)
  {
    setAttributeInternal(ADASSETSAMTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AdAssetsAmtViewRender
   */
  public Boolean getAdAssetsAmtViewRender()
  {
    return (Boolean)getAttributeInternal(ADASSETSAMTVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AdAssetsAmtViewRender
   */
  public void setAdAssetsAmtViewRender(Boolean value)
  {
    setAttributeInternal(ADASSETSAMTVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AdAssetsThisTimeRender
   */
  public Boolean getAdAssetsThisTimeRender()
  {
    return (Boolean)getAttributeInternal(ADASSETSTHISTIMERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AdAssetsThisTimeRender
   */
  public void setAdAssetsThisTimeRender(Boolean value)
  {
    setAttributeInternal(ADASSETSTHISTIMERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AdAssetsThisTimeViewRender
   */
  public Boolean getAdAssetsThisTimeViewRender()
  {
    return (Boolean)getAttributeInternal(ADASSETSTHISTIMEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AdAssetsThisTimeViewRender
   */
  public void setAdAssetsThisTimeViewRender(Boolean value)
  {
    setAttributeInternal(ADASSETSTHISTIMEVIEWRENDER, value);
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute AdAssetsPaymentDateRender
   */
  public Boolean getAdAssetsPaymentDateRender()
  {
    return (Boolean)getAttributeInternal(ADASSETSPAYMENTDATERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AdAssetsPaymentDateRender
   */
  public void setAdAssetsPaymentDateRender(Boolean value)
  {
    setAttributeInternal(ADASSETSPAYMENTDATERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AdAssetsPaymentDateViewRender
   */
  public Boolean getAdAssetsPaymentDateViewRender()
  {
    return (Boolean)getAttributeInternal(ADASSETSPAYMENTDATEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AdAssetsPaymentDateViewRender
   */
  public void setAdAssetsPaymentDateViewRender(Boolean value)
  {
    setAttributeInternal(ADASSETSPAYMENTDATEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractYearMonthRender
   */
  public Boolean getContractYearMonthRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTYEARMONTHRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractYearMonthRender
   */
  public void setContractYearMonthRender(Boolean value)
  {
    setAttributeInternal(CONTRACTYEARMONTHRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AdAssetsPaymentYearRender
   */
  public Boolean getAdAssetsPaymentYearRender()
  {
    return (Boolean)getAttributeInternal(ADASSETSPAYMENTYEARRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AdAssetsPaymentYearRender
   */
  public void setAdAssetsPaymentYearRender(Boolean value)
  {
    setAttributeInternal(ADASSETSPAYMENTYEARRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AdAssetsPaymentYearViewRender
   */
  public Boolean getAdAssetsPaymentYearViewRender()
  {
    return (Boolean)getAttributeInternal(ADASSETSPAYMENTYEARVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AdAssetsPaymentYearViewRender
   */
  public void setAdAssetsPaymentYearViewRender(Boolean value)
  {
    setAttributeInternal(ADASSETSPAYMENTYEARVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OtherConditionRlRN07Render
   */
  public Boolean getOtherConditionRlRN07Render()
  {
    return (Boolean)getAttributeInternal(OTHERCONDITIONRLRN07RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OtherConditionRlRN07Render
   */
  public void setOtherConditionRlRN07Render(Boolean value)
  {
    setAttributeInternal(OTHERCONDITIONRLRN07RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TaxTypeRender
   */
  public Boolean getTaxTypeRender()
  {
    return (Boolean)getAttributeInternal(TAXTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TaxTypeRender
   */
  public void setTaxTypeRender(Boolean value)
  {
    setAttributeInternal(TAXTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TaxTypeViewRender
   */
  public Boolean getTaxTypeViewRender()
  {
    return (Boolean)getAttributeInternal(TAXTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TaxTypeViewRender
   */
  public void setTaxTypeViewRender(Boolean value)
  {
    setAttributeInternal(TAXTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppTypeRender
   */
  public Boolean getInstallSuppTypeRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppTypeRender
   */
  public void setInstallSuppTypeRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppTypeViewRender
   */
  public Boolean getInstallSuppTypeViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppTypeViewRender
   */
  public void setInstallSuppTypeViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppPaymentTypeRender
   */
  public Boolean getInstallSuppPaymentTypeRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPPAYMENTTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppPaymentTypeRender
   */
  public void setInstallSuppPaymentTypeRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPPAYMENTTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppPaymentTypeViewRender
   */
  public Boolean getInstallSuppPaymentTypeViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPPAYMENTTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppPaymentTypeViewRender
   */
  public void setInstallSuppPaymentTypeViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPPAYMENTTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppAmtRender
   */
  public Boolean getInstallSuppAmtRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPAMTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppAmtRender
   */
  public void setInstallSuppAmtRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPAMTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppAmtViewRender
   */
  public Boolean getInstallSuppAmtViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPAMTVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppAmtViewRender
   */
  public void setInstallSuppAmtViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPAMTVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppThisTimeRender
   */
  public Boolean getInstallSuppThisTimeRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPTHISTIMERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppThisTimeRender
   */
  public void setInstallSuppThisTimeRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPTHISTIMERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppThisTimeViewRender
   */
  public Boolean getInstallSuppThisTimeViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPTHISTIMEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppThisTimeViewRender
   */
  public void setInstallSuppThisTimeViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPTHISTIMEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppPaymentYearRender
   */
  public Boolean getInstallSuppPaymentYearRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPPAYMENTYEARRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppPaymentYearRender
   */
  public void setInstallSuppPaymentYearRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPPAYMENTYEARRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppPaymentYearViewRender
   */
  public Boolean getInstallSuppPaymentYearViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPPAYMENTYEARVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppPaymentYearViewRender
   */
  public void setInstallSuppPaymentYearViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPPAYMENTYEARVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppPaymentDateRender
   */
  public Boolean getInstallSuppPaymentDateRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPPAYMENTDATERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppPaymentDateRender
   */
  public void setInstallSuppPaymentDateRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPPAYMENTDATERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppPaymentDateViewRender
   */
  public Boolean getInstallSuppPaymentDateViewRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPPAYMENTDATEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppPaymentDateViewRender
   */
  public void setInstallSuppPaymentDateViewRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPPAYMENTDATEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentTypeRender
   */
  public Boolean getElectricPaymentTypeRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICPAYMENTTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentTypeRender
   */
  public void setElectricPaymentTypeRender(Boolean value)
  {
    setAttributeInternal(ELECTRICPAYMENTTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentTypeViewRender
   */
  public Boolean getElectricPaymentTypeViewRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICPAYMENTTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentTypeViewRender
   */
  public void setElectricPaymentTypeViewRender(Boolean value)
  {
    setAttributeInternal(ELECTRICPAYMENTTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentCycleRender
   */
  public Boolean getElectricPaymentCycleRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICPAYMENTCYCLERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentCycleRender
   */
  public void setElectricPaymentCycleRender(Boolean value)
  {
    setAttributeInternal(ELECTRICPAYMENTCYCLERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentCycleViewRender
   */
  public Boolean getElectricPaymentCycleViewRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICPAYMENTCYCLEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentCycleViewRender
   */
  public void setElectricPaymentCycleViewRender(Boolean value)
  {
    setAttributeInternal(ELECTRICPAYMENTCYCLEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricClosingDateRender
   */
  public Boolean getElectricClosingDateRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICCLOSINGDATERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricClosingDateRender
   */
  public void setElectricClosingDateRender(Boolean value)
  {
    setAttributeInternal(ELECTRICCLOSINGDATERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricClosingDateViewRender
   */
  public Boolean getElectricClosingDateViewRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICCLOSINGDATEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricClosingDateViewRender
   */
  public void setElectricClosingDateViewRender(Boolean value)
  {
    setAttributeInternal(ELECTRICCLOSINGDATEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransMonthRender
   */
  public Boolean getElectricTransMonthRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICTRANSMONTHRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransMonthRender
   */
  public void setElectricTransMonthRender(Boolean value)
  {
    setAttributeInternal(ELECTRICTRANSMONTHRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransMonthViewRender
   */
  public Boolean getElectricTransMonthViewRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICTRANSMONTHVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransMonthViewRender
   */
  public void setElectricTransMonthViewRender(Boolean value)
  {
    setAttributeInternal(ELECTRICTRANSMONTHVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransDateRender
   */
  public Boolean getElectricTransDateRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICTRANSDATERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransDateRender
   */
  public void setElectricTransDateRender(Boolean value)
  {
    setAttributeInternal(ELECTRICTRANSDATERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransDateViewRender
   */
  public Boolean getElectricTransDateViewRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICTRANSDATEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransDateViewRender
   */
  public void setElectricTransDateViewRender(Boolean value)
  {
    setAttributeInternal(ELECTRICTRANSDATEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransNameRender
   */
  public Boolean getElectricTransNameRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICTRANSNAMERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransNameRender
   */
  public void setElectricTransNameRender(Boolean value)
  {
    setAttributeInternal(ELECTRICTRANSNAMERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransNameViewRender
   */
  public Boolean getElectricTransNameViewRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICTRANSNAMEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransNameViewRender
   */
  public void setElectricTransNameViewRender(Boolean value)
  {
    setAttributeInternal(ELECTRICTRANSNAMEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransNameAltRender
   */
  public Boolean getElectricTransNameAltRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICTRANSNAMEALTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransNameAltRender
   */
  public void setElectricTransNameAltRender(Boolean value)
  {
    setAttributeInternal(ELECTRICTRANSNAMEALTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransNameAltViewRender
   */
  public Boolean getElectricTransNameAltViewRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICTRANSNAMEALTVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransNameAltViewRender
   */
  public void setElectricTransNameAltViewRender(Boolean value)
  {
    setAttributeInternal(ELECTRICTRANSNAMEALTVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgTypeRender
   */
  public Boolean getIntroChgTypeRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgTypeRender
   */
  public void setIntroChgTypeRender(Boolean value)
  {
    setAttributeInternal(INTROCHGTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgTypeViewRender
   */
  public Boolean getIntroChgTypeViewRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgTypeViewRender
   */
  public void setIntroChgTypeViewRender(Boolean value)
  {
    setAttributeInternal(INTROCHGTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPaymentTypeRender
   */
  public Boolean getIntroChgPaymentTypeRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGPAYMENTTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPaymentTypeRender
   */
  public void setIntroChgPaymentTypeRender(Boolean value)
  {
    setAttributeInternal(INTROCHGPAYMENTTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPaymentTypeViewRender
   */
  public Boolean getIntroChgPaymentTypeViewRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGPAYMENTTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPaymentTypeViewRender
   */
  public void setIntroChgPaymentTypeViewRender(Boolean value)
  {
    setAttributeInternal(INTROCHGPAYMENTTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgAmtRender
   */
  public Boolean getIntroChgAmtRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGAMTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgAmtRender
   */
  public void setIntroChgAmtRender(Boolean value)
  {
    setAttributeInternal(INTROCHGAMTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgAmtViewRender
   */
  public Boolean getIntroChgAmtViewRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGAMTVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgAmtViewRender
   */
  public void setIntroChgAmtViewRender(Boolean value)
  {
    setAttributeInternal(INTROCHGAMTVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgThisTimeRender
   */
  public Boolean getIntroChgThisTimeRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGTHISTIMERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgThisTimeRender
   */
  public void setIntroChgThisTimeRender(Boolean value)
  {
    setAttributeInternal(INTROCHGTHISTIMERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgThisTimeViewRender
   */
  public Boolean getIntroChgThisTimeViewRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGTHISTIMEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgThisTimeViewRender
   */
  public void setIntroChgThisTimeViewRender(Boolean value)
  {
    setAttributeInternal(INTROCHGTHISTIMEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPaymentYearRender
   */
  public Boolean getIntroChgPaymentYearRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGPAYMENTYEARRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPaymentYearRender
   */
  public void setIntroChgPaymentYearRender(Boolean value)
  {
    setAttributeInternal(INTROCHGPAYMENTYEARRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPaymentYearViewRender
   */
  public Boolean getIntroChgPaymentYearViewRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGPAYMENTYEARVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPaymentYearViewRender
   */
  public void setIntroChgPaymentYearViewRender(Boolean value)
  {
    setAttributeInternal(INTROCHGPAYMENTYEARVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPaymentDateRender
   */
  public Boolean getIntroChgPaymentDateRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGPAYMENTDATERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPaymentDateRender
   */
  public void setIntroChgPaymentDateRender(Boolean value)
  {
    setAttributeInternal(INTROCHGPAYMENTDATERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPaymentDateViewRender
   */
  public Boolean getIntroChgPaymentDateViewRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGPAYMENTDATEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPaymentDateViewRender
   */
  public void setIntroChgPaymentDateViewRender(Boolean value)
  {
    setAttributeInternal(INTROCHGPAYMENTDATEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPerSalesPriceRender
   */
  public Boolean getIntroChgPerSalesPriceRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGPERSALESPRICERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPerSalesPriceRender
   */
  public void setIntroChgPerSalesPriceRender(Boolean value)
  {
    setAttributeInternal(INTROCHGPERSALESPRICERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPerSalesPriceViewRender
   */
  public Boolean getIntroChgPerSalesPriceViewRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGPERSALESPRICEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPerSalesPriceViewRender
   */
  public void setIntroChgPerSalesPriceViewRender(Boolean value)
  {
    setAttributeInternal(INTROCHGPERSALESPRICEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPerPieceRender
   */
  public Boolean getIntroChgPerPieceRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGPERPIECERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPerPieceRender
   */
  public void setIntroChgPerPieceRender(Boolean value)
  {
    setAttributeInternal(INTROCHGPERPIECERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPerPieceViewRender
   */
  public Boolean getIntroChgPerPieceViewRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGPERPIECEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPerPieceViewRender
   */
  public void setIntroChgPerPieceViewRender(Boolean value)
  {
    setAttributeInternal(INTROCHGPERPIECEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgClosingDateRender
   */
  public Boolean getIntroChgClosingDateRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGCLOSINGDATERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgClosingDateRender
   */
  public void setIntroChgClosingDateRender(Boolean value)
  {
    setAttributeInternal(INTROCHGCLOSINGDATERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgClosingDateViewRender
   */
  public Boolean getIntroChgClosingDateViewRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGCLOSINGDATEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgClosingDateViewRender
   */
  public void setIntroChgClosingDateViewRender(Boolean value)
  {
    setAttributeInternal(INTROCHGCLOSINGDATEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgTransMonthRender
   */
  public Boolean getIntroChgTransMonthRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGTRANSMONTHRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgTransMonthRender
   */
  public void setIntroChgTransMonthRender(Boolean value)
  {
    setAttributeInternal(INTROCHGTRANSMONTHRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgTransMonthViewRender
   */
  public Boolean getIntroChgTransMonthViewRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGTRANSMONTHVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgTransMonthViewRender
   */
  public void setIntroChgTransMonthViewRender(Boolean value)
  {
    setAttributeInternal(INTROCHGTRANSMONTHVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgTransDateRender
   */
  public Boolean getIntroChgTransDateRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGTRANSDATERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgTransDateRender
   */
  public void setIntroChgTransDateRender(Boolean value)
  {
    setAttributeInternal(INTROCHGTRANSDATERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgTransDateViewRender
   */
  public Boolean getIntroChgTransDateViewRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGTRANSDATEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgTransDateViewRender
   */
  public void setIntroChgTransDateViewRender(Boolean value)
  {
    setAttributeInternal(INTROCHGTRANSDATEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgTransNameRender
   */
  public Boolean getIntroChgTransNameRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGTRANSNAMERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgTransNameRender
   */
  public void setIntroChgTransNameRender(Boolean value)
  {
    setAttributeInternal(INTROCHGTRANSNAMERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgTransNameViewRender
   */
  public Boolean getIntroChgTransNameViewRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGTRANSNAMEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgTransNameViewRender
   */
  public void setIntroChgTransNameViewRender(Boolean value)
  {
    setAttributeInternal(INTROCHGTRANSNAMEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgTransNameAltRender
   */
  public Boolean getIntroChgTransNameAltRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGTRANSNAMEALTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgTransNameAltRender
   */
  public void setIntroChgTransNameAltRender(Boolean value)
  {
    setAttributeInternal(INTROCHGTRANSNAMEALTRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgTransNameAltViewRender
   */
  public Boolean getIntroChgTransNameAltViewRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGTRANSNAMEALTVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgTransNameAltViewRender
   */
  public void setIntroChgTransNameAltViewRender(Boolean value)
  {
    setAttributeInternal(INTROCHGTRANSNAMEALTVIEWRENDER, value);
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppPaymentTypeHdrRNRender
   */
  public Boolean getInstallSuppPaymentTypeHdrRNRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPPAYMENTTYPEHDRRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppPaymentTypeHdrRNRender
   */
  public void setInstallSuppPaymentTypeHdrRNRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPPAYMENTTYPEHDRRNRENDER, value);
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTypeRender
   */
  public Boolean getElectricTypeRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICTYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTypeRender
   */
  public void setElectricTypeRender(Boolean value)
  {
    setAttributeInternal(ELECTRICTYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTypeViewRender
   */
  public Boolean getElectricTypeViewRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICTYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTypeViewRender
   */
  public void setElectricTypeViewRender(Boolean value)
  {
    setAttributeInternal(ELECTRICTYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentChangeTypeRender
   */
  public Boolean getElectricPaymentChangeTypeRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICPAYMENTCHANGETYPERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentChangeTypeRender
   */
  public void setElectricPaymentChangeTypeRender(Boolean value)
  {
    setAttributeInternal(ELECTRICPAYMENTCHANGETYPERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentChangeTypeViewRender
   */
  public Boolean getElectricPaymentChangeTypeViewRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICPAYMENTCHANGETYPEVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentChangeTypeViewRender
   */
  public void setElectricPaymentChangeTypeViewRender(Boolean value)
  {
    setAttributeInternal(ELECTRICPAYMENTCHANGETYPEVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppThisTimeLabelRender
   */
  public Boolean getInstallSuppThisTimeLabelRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPTHISTIMELABELRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppThisTimeLabelRender
   */
  public void setInstallSuppThisTimeLabelRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPTHISTIMELABELRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricInfoRIRN02Render
   */
  public Boolean getElectricInfoRIRN02Render()
  {
    return (Boolean)getAttributeInternal(ELECTRICINFORIRN02RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricInfoRIRN02Render
   */
  public void setElectricInfoRIRN02Render(Boolean value)
  {
    setAttributeInternal(ELECTRICINFORIRN02RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricInfoRIRN03Render
   */
  public Boolean getElectricInfoRIRN03Render()
  {
    return (Boolean)getAttributeInternal(ELECTRICINFORIRN03RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricInfoRIRN03Render
   */
  public void setElectricInfoRIRN03Render(Boolean value)
  {
    setAttributeInternal(ELECTRICINFORIRN03RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricInfoRIRN04Render
   */
  public Boolean getElectricInfoRIRN04Render()
  {
    return (Boolean)getAttributeInternal(ELECTRICINFORIRN04RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricInfoRIRN04Render
   */
  public void setElectricInfoRIRN04Render(Boolean value)
  {
    setAttributeInternal(ELECTRICINFORIRN04RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricInfoRIRN05Render
   */
  public Boolean getElectricInfoRIRN05Render()
  {
    return (Boolean)getAttributeInternal(ELECTRICINFORIRN05RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricInfoRIRN05Render
   */
  public void setElectricInfoRIRN05Render(Boolean value)
  {
    setAttributeInternal(ELECTRICINFORIRN05RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricInfoRIRN06Render
   */
  public Boolean getElectricInfoRIRN06Render()
  {
    return (Boolean)getAttributeInternal(ELECTRICINFORIRN06RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricInfoRIRN06Render
   */
  public void setElectricInfoRIRN06Render(Boolean value)
  {
    setAttributeInternal(ELECTRICINFORIRN06RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgInfoRIRN01Render
   */
  public Boolean getIntroChgInfoRIRN01Render()
  {
    return (Boolean)getAttributeInternal(INTROCHGINFORIRN01RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgInfoRIRN01Render
   */
  public void setIntroChgInfoRIRN01Render(Boolean value)
  {
    setAttributeInternal(INTROCHGINFORIRN01RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgInfoRIRN02Render
   */
  public Boolean getIntroChgInfoRIRN02Render()
  {
    return (Boolean)getAttributeInternal(INTROCHGINFORIRN02RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgInfoRIRN02Render
   */
  public void setIntroChgInfoRIRN02Render(Boolean value)
  {
    setAttributeInternal(INTROCHGINFORIRN02RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPerSalesPriceLabelRender
   */
  public Boolean getIntroChgPerSalesPriceLabelRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGPERSALESPRICELABELRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPerSalesPriceLabelRender
   */
  public void setIntroChgPerSalesPriceLabelRender(Boolean value)
  {
    setAttributeInternal(INTROCHGPERSALESPRICELABELRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPerPieceLabelRender
   */
  public Boolean getIntroChgPerPieceLabelRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGPERPIECELABELRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPerPieceLabelRender
   */
  public void setIntroChgPerPieceLabelRender(Boolean value)
  {
    setAttributeInternal(INTROCHGPERPIECELABELRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPerSalesPriceEndLabelRender
   */
  public Boolean getIntroChgPerSalesPriceEndLabelRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGPERSALESPRICEENDLABELRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPerSalesPriceEndLabelRender
   */
  public void setIntroChgPerSalesPriceEndLabelRender(Boolean value)
  {
    setAttributeInternal(INTROCHGPERSALESPRICEENDLABELRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPerPieceEndLabelRender
   */
  public Boolean getIntroChgPerPieceEndLabelRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGPERPIECEENDLABELRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPerPieceEndLabelRender
   */
  public void setIntroChgPerPieceEndLabelRender(Boolean value)
  {
    setAttributeInternal(INTROCHGPERPIECEENDLABELRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgTypeHdrRNRender
   */
  public Boolean getIntroChgTypeHdrRNRender()
  {
    return (Boolean)getAttributeInternal(INTROCHGTYPEHDRRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgTypeHdrRNRender
   */
  public void setIntroChgTypeHdrRNRender(Boolean value)
  {
    setAttributeInternal(INTROCHGTYPEHDRRNRENDER, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentTypeHdrRNRender
   */
  public Boolean getElectricPaymentTypeHdrRNRender()
  {
    return (Boolean)getAttributeInternal(ELECTRICPAYMENTTYPEHDRRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentTypeHdrRNRender
   */
  public void setElectricPaymentTypeHdrRNRender(Boolean value)
  {
    setAttributeInternal(ELECTRICPAYMENTTYPEHDRRNRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppThisTimeEndLabelRender
   */
  public Boolean getInstallSuppThisTimeEndLabelRender()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPTHISTIMEENDLABELRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppThisTimeEndLabelRender
   */
  public void setInstallSuppThisTimeEndLabelRender(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPTHISTIMEENDLABELRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppPaymentYearEndLabel1Render
   */
  public Boolean getInstallSuppPaymentYearEndLabel1Render()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPPAYMENTYEARENDLABEL1RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppPaymentYearEndLabel1Render
   */
  public void setInstallSuppPaymentYearEndLabel1Render(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPPAYMENTYEARENDLABEL1RENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppPaymentYearEndLabel2Render
   */
  public Boolean getInstallSuppPaymentYearEndLabel2Render()
  {
    return (Boolean)getAttributeInternal(INSTALLSUPPPAYMENTYEARENDLABEL2RENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppPaymentYearEndLabel2Render
   */
  public void setInstallSuppPaymentYearEndLabel2Render(Boolean value)
  {
    setAttributeInternal(INSTALLSUPPPAYMENTYEARENDLABEL2RENDER, value);
  }





























































}