/*============================================================================
* ÉtÉ@ÉCÉãñº : XxcsoSpDecisionHeaderFullVORowImpl
* äTóvê‡ñæ   : SPêÍåàÉwÉbÉ_ìoò^Å^çXêVópÉrÉÖÅ[çsÉNÉâÉX
* ÉoÅ[ÉWÉáÉì : 1.1
*============================================================================
* èCê≥óöó
* ì˙ït       Ver. íSìñé“       èCê≥ì‡óe
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCSè¨êÏç_     êVãKçÏê¨
* 2014-12-30 1.1  SCSKãÀê∂òaçK  [E_ñ{â“ìÆ_12565]SPÅEå_ñÒèëâÊñ â¸èCëŒâû
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * SPêÍåàÉwÉbÉ_Çìoò^Å^çXêVÇ∑ÇÈÇΩÇﬂÇÃÉrÉÖÅ[çsÉNÉâÉXÇ≈Ç∑ÅB
 * @author  SCSè¨êÏç_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionHeaderFullVORowImpl extends OAViewRowImpl 
{


  protected static final int SPDECISIONHEADERID = 0;
  protected static final int SPDECISIONNUMBER = 1;
  protected static final int SPDECISIONTYPE = 2;
  protected static final int STATUS = 3;
  protected static final int APPLICATIONNUMBER = 4;
  protected static final int APPLICATIONDATE = 5;
  protected static final int APPROVALCOMPLETEDATE = 6;
  protected static final int APPLICATIONCODE = 7;
  protected static final int APPBASECODE = 8;
  protected static final int APPLICATIONTYPE = 9;
  protected static final int NEWOLDTYPE = 10;
  protected static final int SELENUMBER = 11;
  protected static final int MAKERCODE = 12;
  protected static final int STANDARDTYPE = 13;
  protected static final int UNNUMBER = 14;
  protected static final int INSTALLDATE = 15;
  protected static final int LEASECOMPANY = 16;
  protected static final int CONDITIONBUSINESSTYPE = 17;
  protected static final int ALLCONTAINERTYPE = 18;
  protected static final int CONTRACTYEARDATE = 19;
  protected static final int INSTALLSUPPORTAMT = 20;
  protected static final int INSTALLSUPPORTAMT2 = 21;
  protected static final int PAYMENTCYCLE = 22;
  protected static final int ELECTRICITYTYPE = 23;
  protected static final int ELECTRICITYAMOUNT = 24;
  protected static final int CONDITIONREASON = 25;
  protected static final int BM1SENDTYPE = 26;
  protected static final int OTHERCONTENT = 27;
  protected static final int SALESMONTH = 28;
  protected static final int SALESYEAR = 29;
  protected static final int SALESGROSSMARGINRATE = 30;
  protected static final int YEARGROSSMARGINAMT = 31;
  protected static final int BMRATE = 32;
  protected static final int VDSALESCHARGE = 33;
  protected static final int INSTALLSUPPORTAMTYEAR = 34;
  protected static final int LEASECHARGEMONTH = 35;
  protected static final int CONSTRUCTIONCHARGE = 36;
  protected static final int VDLEASECHARGE = 37;
  protected static final int ELECTRICITYAMTMONTH = 38;
  protected static final int ELECTRICITYAMTYEAR = 39;
  protected static final int TRANSPORTATIONCHARGE = 40;
  protected static final int LABORCOSTOTHER = 41;
  protected static final int TOTALCOST = 42;
  protected static final int OPERATINGPROFIT = 43;
  protected static final int OPERATINGPROFITRATE = 44;
  protected static final int BREAKEVENPOINT = 45;
  protected static final int CREATEDBY = 46;
  protected static final int CREATIONDATE = 47;
  protected static final int LASTUPDATEDBY = 48;
  protected static final int LASTUPDATEDATE = 49;
  protected static final int LASTUPDATELOGIN = 50;
  protected static final int REQUESTID = 51;
  protected static final int PROGRAMAPPLICATIONID = 52;
  protected static final int PROGRAMID = 53;
  protected static final int PROGRAMUPDATEDATE = 54;
  protected static final int APPBASENAME = 55;
  protected static final int FULLNAME = 56;
  protected static final int UNNUMBERID = 57;
  protected static final int CONTRACTEXISTS = 58;
  protected static final int CONTRACTYEARMONTH = 59;
  protected static final int CONTRACTSTARTYEAR = 60;
  protected static final int CONTRACTSTARTMONTH = 61;
  protected static final int CONTRACTENDYEAR = 62;
  protected static final int CONTRACTENDMONTH = 63;
  protected static final int BIDDINGITEM = 64;
  protected static final int CANCELLBEFOREMATURITY = 65;
  protected static final int ADASSETSTYPE = 66;
  protected static final int ADASSETSAMT = 67;
  protected static final int ADASSETSTHISTIME = 68;
  protected static final int ADASSETSPAYMENTYEAR = 69;
  protected static final int ADASSETSPAYMENTDATE = 70;
  protected static final int TAXTYPE = 71;
  protected static final int INSTALLSUPPTYPE = 72;
  protected static final int INSTALLSUPPPAYMENTTYPE = 73;
  protected static final int INSTALLSUPPAMT = 74;
  protected static final int INSTALLSUPPTHISTIME = 75;
  protected static final int INSTALLSUPPPAYMENTYEAR = 76;
  protected static final int INSTALLSUPPPAYMENTDATE = 77;
  protected static final int ELECTRICTYPE = 78;
  protected static final int ELECTRICPAYMENTTYPE = 79;
  protected static final int ELECTRICPAYMENTCHANGETYPE = 80;
  protected static final int ELECTRICPAYMENTCYCLE = 81;
  protected static final int ELECTRICCLOSINGDATE = 82;
  protected static final int ELECTRICTRANSMONTH = 83;
  protected static final int ELECTRICTRANSDATE = 84;
  protected static final int ELECTRICTRANSNAME = 85;
  protected static final int ELECTRICTRANSNAMEALT = 86;
  protected static final int INTROCHGTYPE = 87;
  protected static final int INTROCHGPAYMENTTYPE = 88;
  protected static final int INTROCHGAMT = 89;
  protected static final int INTROCHGTHISTIME = 90;
  protected static final int INTROCHGPAYMENTYEAR = 91;
  protected static final int INTROCHGPAYMENTDATE = 92;
  protected static final int INTROCHGPERSALESPRICE = 93;
  protected static final int INTROCHGPERPIECE = 94;
  protected static final int INTROCHGCLOSINGDATE = 95;
  protected static final int INTROCHGTRANSMONTH = 96;
  protected static final int INTROCHGTRANSDATE = 97;
  protected static final int INTROCHGTRANSNAME = 98;
  protected static final int INTROCHGTRANSNAMEALT = 99;
  protected static final int XXCSOSPDECISIONALLCCLINEFULLVO = 100;
  protected static final int XXCSOSPDECISIONATTACHFULLVO = 101;
  protected static final int XXCSOSPDECISIONBM1CUSTFULLVO = 102;
  protected static final int XXCSOSPDECISIONBM2CUSTFULLVO = 103;
  protected static final int XXCSOSPDECISIONBM3CUSTFULLVO = 104;
  protected static final int XXCSOSPDECISIONCNTRCTCUSTFULLVO = 105;
  protected static final int XXCSOSPDECISIONINSTCUSTFULLVO = 106;
  protected static final int XXCSOSPDECISIONSCLINEFULLVO = 107;
  protected static final int XXCSOSPDECISIONSELCCLINEFULLVO = 108;
  protected static final int XXCSOSPDECISIONSENDFULLVO = 109;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionHeaderFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoSpDecisionHeadersVEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionHeadersVEOImpl getXxcsoSpDecisionHeadersVEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionHeadersVEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for SP_DECISION_HEADER_ID using the alias name SpDecisionHeaderId
   */
  public Number getSpDecisionHeaderId()
  {
    return (Number)getAttributeInternal(SPDECISIONHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SP_DECISION_HEADER_ID using the alias name SpDecisionHeaderId
   */
  public void setSpDecisionHeaderId(Number value)
  {
    setAttributeInternal(SPDECISIONHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for SP_DECISION_NUMBER using the alias name SpDecisionNumber
   */
  public String getSpDecisionNumber()
  {
    return (String)getAttributeInternal(SPDECISIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SP_DECISION_NUMBER using the alias name SpDecisionNumber
   */
  public void setSpDecisionNumber(String value)
  {
    setAttributeInternal(SPDECISIONNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for SP_DECISION_TYPE using the alias name SpDecisionType
   */
  public String getSpDecisionType()
  {
    return (String)getAttributeInternal(SPDECISIONTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SP_DECISION_TYPE using the alias name SpDecisionType
   */
  public void setSpDecisionType(String value)
  {
    setAttributeInternal(SPDECISIONTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for STATUS using the alias name Status
   */
  public String getStatus()
  {
    return (String)getAttributeInternal(STATUS);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for STATUS using the alias name Status
   */
  public void setStatus(String value)
  {
    setAttributeInternal(STATUS, value);
  }

  /**
   * 
   * Gets the attribute value for APPLICATION_NUMBER using the alias name ApplicationNumber
   */
  public Number getApplicationNumber()
  {
    return (Number)getAttributeInternal(APPLICATIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for APPLICATION_NUMBER using the alias name ApplicationNumber
   */
  public void setApplicationNumber(Number value)
  {
    setAttributeInternal(APPLICATIONNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for APPLICATION_DATE using the alias name ApplicationDate
   */
  public Date getApplicationDate()
  {
    return (Date)getAttributeInternal(APPLICATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for APPLICATION_DATE using the alias name ApplicationDate
   */
  public void setApplicationDate(Date value)
  {
    setAttributeInternal(APPLICATIONDATE, value);
  }





  /**
   * 
   * Gets the attribute value for APPROVAL_COMPLETE_DATE using the alias name ApprovalCompleteDate
   */
  public Date getApprovalCompleteDate()
  {
    return (Date)getAttributeInternal(APPROVALCOMPLETEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for APPROVAL_COMPLETE_DATE using the alias name ApprovalCompleteDate
   */
  public void setApprovalCompleteDate(Date value)
  {
    setAttributeInternal(APPROVALCOMPLETEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for APPLICATION_CODE using the alias name ApplicationCode
   */
  public String getApplicationCode()
  {
    return (String)getAttributeInternal(APPLICATIONCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for APPLICATION_CODE using the alias name ApplicationCode
   */
  public void setApplicationCode(String value)
  {
    setAttributeInternal(APPLICATIONCODE, value);
  }

  /**
   * 
   * Gets the attribute value for APP_BASE_CODE using the alias name AppBaseCode
   */
  public String getAppBaseCode()
  {
    return (String)getAttributeInternal(APPBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for APP_BASE_CODE using the alias name AppBaseCode
   */
  public void setAppBaseCode(String value)
  {
    setAttributeInternal(APPBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for APPLICATION_TYPE using the alias name ApplicationType
   */
  public String getApplicationType()
  {
    return (String)getAttributeInternal(APPLICATIONTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for APPLICATION_TYPE using the alias name ApplicationType
   */
  public void setApplicationType(String value)
  {
    setAttributeInternal(APPLICATIONTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for NEWOLD_TYPE using the alias name NewoldType
   */
  public String getNewoldType()
  {
    return (String)getAttributeInternal(NEWOLDTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NEWOLD_TYPE using the alias name NewoldType
   */
  public void setNewoldType(String value)
  {
    setAttributeInternal(NEWOLDTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for SELE_NUMBER using the alias name SeleNumber
   */
  public String getSeleNumber()
  {
    return (String)getAttributeInternal(SELENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SELE_NUMBER using the alias name SeleNumber
   */
  public void setSeleNumber(String value)
  {
    setAttributeInternal(SELENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for MAKER_CODE using the alias name MakerCode
   */
  public String getMakerCode()
  {
    return (String)getAttributeInternal(MAKERCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for MAKER_CODE using the alias name MakerCode
   */
  public void setMakerCode(String value)
  {
    setAttributeInternal(MAKERCODE, value);
  }

  /**
   * 
   * Gets the attribute value for STANDARD_TYPE using the alias name StandardType
   */
  public String getStandardType()
  {
    return (String)getAttributeInternal(STANDARDTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for STANDARD_TYPE using the alias name StandardType
   */
  public void setStandardType(String value)
  {
    setAttributeInternal(STANDARDTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for UN_NUMBER using the alias name UnNumber
   */
  public String getUnNumber()
  {
    return (String)getAttributeInternal(UNNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for UN_NUMBER using the alias name UnNumber
   */
  public void setUnNumber(String value)
  {
    setAttributeInternal(UNNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_DATE using the alias name InstallDate
   */
  public Date getInstallDate()
  {
    return (Date)getAttributeInternal(INSTALLDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_DATE using the alias name InstallDate
   */
  public void setInstallDate(Date value)
  {
    setAttributeInternal(INSTALLDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LEASE_COMPANY using the alias name LeaseCompany
   */
  public String getLeaseCompany()
  {
    return (String)getAttributeInternal(LEASECOMPANY);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LEASE_COMPANY using the alias name LeaseCompany
   */
  public void setLeaseCompany(String value)
  {
    setAttributeInternal(LEASECOMPANY, value);
  }

  /**
   * 
   * Gets the attribute value for CONDITION_BUSINESS_TYPE using the alias name ConditionBusinessType
   */
  public String getConditionBusinessType()
  {
    return (String)getAttributeInternal(CONDITIONBUSINESSTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONDITION_BUSINESS_TYPE using the alias name ConditionBusinessType
   */
  public void setConditionBusinessType(String value)
  {
    setAttributeInternal(CONDITIONBUSINESSTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for ALL_CONTAINER_TYPE using the alias name AllContainerType
   */
  public String getAllContainerType()
  {
    return (String)getAttributeInternal(ALLCONTAINERTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ALL_CONTAINER_TYPE using the alias name AllContainerType
   */
  public void setAllContainerType(String value)
  {
    setAttributeInternal(ALLCONTAINERTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for CONTRACT_YEAR_DATE using the alias name ContractYearDate
   */
  public String getContractYearDate()
  {
    return (String)getAttributeInternal(CONTRACTYEARDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTRACT_YEAR_DATE using the alias name ContractYearDate
   */
  public void setContractYearDate(String value)
  {
    setAttributeInternal(CONTRACTYEARDATE, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_SUPPORT_AMT using the alias name InstallSupportAmt
   */
  public String getInstallSupportAmt()
  {
    return (String)getAttributeInternal(INSTALLSUPPORTAMT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_SUPPORT_AMT using the alias name InstallSupportAmt
   */
  public void setInstallSupportAmt(String value)
  {
    setAttributeInternal(INSTALLSUPPORTAMT, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_SUPPORT_AMT2 using the alias name InstallSupportAmt2
   */
  public String getInstallSupportAmt2()
  {
    return (String)getAttributeInternal(INSTALLSUPPORTAMT2);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_SUPPORT_AMT2 using the alias name InstallSupportAmt2
   */
  public void setInstallSupportAmt2(String value)
  {
    setAttributeInternal(INSTALLSUPPORTAMT2, value);
  }

  /**
   * 
   * Gets the attribute value for PAYMENT_CYCLE using the alias name PaymentCycle
   */
  public String getPaymentCycle()
  {
    return (String)getAttributeInternal(PAYMENTCYCLE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PAYMENT_CYCLE using the alias name PaymentCycle
   */
  public void setPaymentCycle(String value)
  {
    setAttributeInternal(PAYMENTCYCLE, value);
  }

  /**
   * 
   * Gets the attribute value for ELECTRICITY_TYPE using the alias name ElectricityType
   */
  public String getElectricityType()
  {
    return (String)getAttributeInternal(ELECTRICITYTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ELECTRICITY_TYPE using the alias name ElectricityType
   */
  public void setElectricityType(String value)
  {
    setAttributeInternal(ELECTRICITYTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for ELECTRICITY_AMOUNT using the alias name ElectricityAmount
   */
  public String getElectricityAmount()
  {
    return (String)getAttributeInternal(ELECTRICITYAMOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ELECTRICITY_AMOUNT using the alias name ElectricityAmount
   */
  public void setElectricityAmount(String value)
  {
    setAttributeInternal(ELECTRICITYAMOUNT, value);
  }

  /**
   * 
   * Gets the attribute value for CONDITION_REASON using the alias name ConditionReason
   */
  public String getConditionReason()
  {
    return (String)getAttributeInternal(CONDITIONREASON);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONDITION_REASON using the alias name ConditionReason
   */
  public void setConditionReason(String value)
  {
    setAttributeInternal(CONDITIONREASON, value);
  }

  /**
   * 
   * Gets the attribute value for BM1_SEND_TYPE using the alias name Bm1SendType
   */
  public String getBm1SendType()
  {
    return (String)getAttributeInternal(BM1SENDTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BM1_SEND_TYPE using the alias name Bm1SendType
   */
  public void setBm1SendType(String value)
  {
    setAttributeInternal(BM1SENDTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for OTHER_CONTENT using the alias name OtherContent
   */
  public String getOtherContent()
  {
    return (String)getAttributeInternal(OTHERCONTENT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for OTHER_CONTENT using the alias name OtherContent
   */
  public void setOtherContent(String value)
  {
    setAttributeInternal(OTHERCONTENT, value);
  }

  /**
   * 
   * Gets the attribute value for SALES_MONTH using the alias name SalesMonth
   */
  public String getSalesMonth()
  {
    return (String)getAttributeInternal(SALESMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SALES_MONTH using the alias name SalesMonth
   */
  public void setSalesMonth(String value)
  {
    setAttributeInternal(SALESMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for SALES_YEAR using the alias name SalesYear
   */
  public String getSalesYear()
  {
    return (String)getAttributeInternal(SALESYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SALES_YEAR using the alias name SalesYear
   */
  public void setSalesYear(String value)
  {
    setAttributeInternal(SALESYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for SALES_GROSS_MARGIN_RATE using the alias name SalesGrossMarginRate
   */
  public String getSalesGrossMarginRate()
  {
    return (String)getAttributeInternal(SALESGROSSMARGINRATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SALES_GROSS_MARGIN_RATE using the alias name SalesGrossMarginRate
   */
  public void setSalesGrossMarginRate(String value)
  {
    setAttributeInternal(SALESGROSSMARGINRATE, value);
  }

  /**
   * 
   * Gets the attribute value for YEAR_GROSS_MARGIN_AMT using the alias name YearGrossMarginAmt
   */
  public String getYearGrossMarginAmt()
  {
    return (String)getAttributeInternal(YEARGROSSMARGINAMT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for YEAR_GROSS_MARGIN_AMT using the alias name YearGrossMarginAmt
   */
  public void setYearGrossMarginAmt(String value)
  {
    setAttributeInternal(YEARGROSSMARGINAMT, value);
  }

  /**
   * 
   * Gets the attribute value for BM_RATE using the alias name BmRate
   */
  public String getBmRate()
  {
    return (String)getAttributeInternal(BMRATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BM_RATE using the alias name BmRate
   */
  public void setBmRate(String value)
  {
    setAttributeInternal(BMRATE, value);
  }

  /**
   * 
   * Gets the attribute value for VD_SALES_CHARGE using the alias name VdSalesCharge
   */
  public String getVdSalesCharge()
  {
    return (String)getAttributeInternal(VDSALESCHARGE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for VD_SALES_CHARGE using the alias name VdSalesCharge
   */
  public void setVdSalesCharge(String value)
  {
    setAttributeInternal(VDSALESCHARGE, value);
  }

  /**
   * 
   * Gets the attribute value for INSTALL_SUPPORT_AMT_YEAR using the alias name InstallSupportAmtYear
   */
  public String getInstallSupportAmtYear()
  {
    return (String)getAttributeInternal(INSTALLSUPPORTAMTYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INSTALL_SUPPORT_AMT_YEAR using the alias name InstallSupportAmtYear
   */
  public void setInstallSupportAmtYear(String value)
  {
    setAttributeInternal(INSTALLSUPPORTAMTYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for LEASE_CHARGE_MONTH using the alias name LeaseChargeMonth
   */
  public String getLeaseChargeMonth()
  {
    return (String)getAttributeInternal(LEASECHARGEMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LEASE_CHARGE_MONTH using the alias name LeaseChargeMonth
   */
  public void setLeaseChargeMonth(String value)
  {
    setAttributeInternal(LEASECHARGEMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for CONSTRUCTION_CHARGE using the alias name ConstructionCharge
   */
  public String getConstructionCharge()
  {
    return (String)getAttributeInternal(CONSTRUCTIONCHARGE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONSTRUCTION_CHARGE using the alias name ConstructionCharge
   */
  public void setConstructionCharge(String value)
  {
    setAttributeInternal(CONSTRUCTIONCHARGE, value);
  }

  /**
   * 
   * Gets the attribute value for VD_LEASE_CHARGE using the alias name VdLeaseCharge
   */
  public String getVdLeaseCharge()
  {
    return (String)getAttributeInternal(VDLEASECHARGE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for VD_LEASE_CHARGE using the alias name VdLeaseCharge
   */
  public void setVdLeaseCharge(String value)
  {
    setAttributeInternal(VDLEASECHARGE, value);
  }

  /**
   * 
   * Gets the attribute value for ELECTRICITY_AMT_MONTH using the alias name ElectricityAmtMonth
   */
  public String getElectricityAmtMonth()
  {
    return (String)getAttributeInternal(ELECTRICITYAMTMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ELECTRICITY_AMT_MONTH using the alias name ElectricityAmtMonth
   */
  public void setElectricityAmtMonth(String value)
  {
    setAttributeInternal(ELECTRICITYAMTMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for ELECTRICITY_AMT_YEAR using the alias name ElectricityAmtYear
   */
  public String getElectricityAmtYear()
  {
    return (String)getAttributeInternal(ELECTRICITYAMTYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ELECTRICITY_AMT_YEAR using the alias name ElectricityAmtYear
   */
  public void setElectricityAmtYear(String value)
  {
    setAttributeInternal(ELECTRICITYAMTYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for TRANSPORTATION_CHARGE using the alias name TransportationCharge
   */
  public String getTransportationCharge()
  {
    return (String)getAttributeInternal(TRANSPORTATIONCHARGE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TRANSPORTATION_CHARGE using the alias name TransportationCharge
   */
  public void setTransportationCharge(String value)
  {
    setAttributeInternal(TRANSPORTATIONCHARGE, value);
  }

  /**
   * 
   * Gets the attribute value for LABOR_COST_OTHER using the alias name LaborCostOther
   */
  public String getLaborCostOther()
  {
    return (String)getAttributeInternal(LABORCOSTOTHER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LABOR_COST_OTHER using the alias name LaborCostOther
   */
  public void setLaborCostOther(String value)
  {
    setAttributeInternal(LABORCOSTOTHER, value);
  }

  /**
   * 
   * Gets the attribute value for TOTAL_COST using the alias name TotalCost
   */
  public String getTotalCost()
  {
    return (String)getAttributeInternal(TOTALCOST);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TOTAL_COST using the alias name TotalCost
   */
  public void setTotalCost(String value)
  {
    setAttributeInternal(TOTALCOST, value);
  }

  /**
   * 
   * Gets the attribute value for OPERATING_PROFIT using the alias name OperatingProfit
   */
  public String getOperatingProfit()
  {
    return (String)getAttributeInternal(OPERATINGPROFIT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for OPERATING_PROFIT using the alias name OperatingProfit
   */
  public void setOperatingProfit(String value)
  {
    setAttributeInternal(OPERATINGPROFIT, value);
  }

  /**
   * 
   * Gets the attribute value for OPERATING_PROFIT_RATE using the alias name OperatingProfitRate
   */
  public String getOperatingProfitRate()
  {
    return (String)getAttributeInternal(OPERATINGPROFITRATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for OPERATING_PROFIT_RATE using the alias name OperatingProfitRate
   */
  public void setOperatingProfitRate(String value)
  {
    setAttributeInternal(OPERATINGPROFITRATE, value);
  }

  /**
   * 
   * Gets the attribute value for BREAK_EVEN_POINT using the alias name BreakEvenPoint
   */
  public String getBreakEvenPoint()
  {
    return (String)getAttributeInternal(BREAKEVENPOINT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BREAK_EVEN_POINT using the alias name BreakEvenPoint
   */
  public void setBreakEvenPoint(String value)
  {
    setAttributeInternal(BREAKEVENPOINT, value);
  }

  /**
   * 
   * Gets the attribute value for CREATED_BY using the alias name CreatedBy
   */
  public Number getCreatedBy()
  {
    return (Number)getAttributeInternal(CREATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CREATED_BY using the alias name CreatedBy
   */
  public void setCreatedBy(Number value)
  {
    setAttributeInternal(CREATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for CREATION_DATE using the alias name CreationDate
   */
  public Date getCreationDate()
  {
    return (Date)getAttributeInternal(CREATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CREATION_DATE using the alias name CreationDate
   */
  public void setCreationDate(Date value)
  {
    setAttributeInternal(CREATIONDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LAST_UPDATED_BY using the alias name LastUpdatedBy
   */
  public Number getLastUpdatedBy()
  {
    return (Number)getAttributeInternal(LASTUPDATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATED_BY using the alias name LastUpdatedBy
   */
  public void setLastUpdatedBy(Number value)
  {
    setAttributeInternal(LASTUPDATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for LAST_UPDATE_DATE using the alias name LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATE_DATE using the alias name LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    setAttributeInternal(LASTUPDATEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LAST_UPDATE_LOGIN using the alias name LastUpdateLogin
   */
  public Number getLastUpdateLogin()
  {
    return (Number)getAttributeInternal(LASTUPDATELOGIN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATE_LOGIN using the alias name LastUpdateLogin
   */
  public void setLastUpdateLogin(Number value)
  {
    setAttributeInternal(LASTUPDATELOGIN, value);
  }

  /**
   * 
   * Gets the attribute value for REQUEST_ID using the alias name RequestId
   */
  public Number getRequestId()
  {
    return (Number)getAttributeInternal(REQUESTID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for REQUEST_ID using the alias name RequestId
   */
  public void setRequestId(Number value)
  {
    setAttributeInternal(REQUESTID, value);
  }

  /**
   * 
   * Gets the attribute value for PROGRAM_APPLICATION_ID using the alias name ProgramApplicationId
   */
  public Number getProgramApplicationId()
  {
    return (Number)getAttributeInternal(PROGRAMAPPLICATIONID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PROGRAM_APPLICATION_ID using the alias name ProgramApplicationId
   */
  public void setProgramApplicationId(Number value)
  {
    setAttributeInternal(PROGRAMAPPLICATIONID, value);
  }

  /**
   * 
   * Gets the attribute value for PROGRAM_ID using the alias name ProgramId
   */
  public Number getProgramId()
  {
    return (Number)getAttributeInternal(PROGRAMID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PROGRAM_ID using the alias name ProgramId
   */
  public void setProgramId(Number value)
  {
    setAttributeInternal(PROGRAMID, value);
  }

  /**
   * 
   * Gets the attribute value for PROGRAM_UPDATE_DATE using the alias name ProgramUpdateDate
   */
  public Date getProgramUpdateDate()
  {
    return (Date)getAttributeInternal(PROGRAMUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PROGRAM_UPDATE_DATE using the alias name ProgramUpdateDate
   */
  public void setProgramUpdateDate(Date value)
  {
    setAttributeInternal(PROGRAMUPDATEDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONHEADERID:
        return getSpDecisionHeaderId();
      case SPDECISIONNUMBER:
        return getSpDecisionNumber();
      case SPDECISIONTYPE:
        return getSpDecisionType();
      case STATUS:
        return getStatus();
      case APPLICATIONNUMBER:
        return getApplicationNumber();
      case APPLICATIONDATE:
        return getApplicationDate();
      case APPROVALCOMPLETEDATE:
        return getApprovalCompleteDate();
      case APPLICATIONCODE:
        return getApplicationCode();
      case APPBASECODE:
        return getAppBaseCode();
      case APPLICATIONTYPE:
        return getApplicationType();
      case NEWOLDTYPE:
        return getNewoldType();
      case SELENUMBER:
        return getSeleNumber();
      case MAKERCODE:
        return getMakerCode();
      case STANDARDTYPE:
        return getStandardType();
      case UNNUMBER:
        return getUnNumber();
      case INSTALLDATE:
        return getInstallDate();
      case LEASECOMPANY:
        return getLeaseCompany();
      case CONDITIONBUSINESSTYPE:
        return getConditionBusinessType();
      case ALLCONTAINERTYPE:
        return getAllContainerType();
      case CONTRACTYEARDATE:
        return getContractYearDate();
      case INSTALLSUPPORTAMT:
        return getInstallSupportAmt();
      case INSTALLSUPPORTAMT2:
        return getInstallSupportAmt2();
      case PAYMENTCYCLE:
        return getPaymentCycle();
      case ELECTRICITYTYPE:
        return getElectricityType();
      case ELECTRICITYAMOUNT:
        return getElectricityAmount();
      case CONDITIONREASON:
        return getConditionReason();
      case BM1SENDTYPE:
        return getBm1SendType();
      case OTHERCONTENT:
        return getOtherContent();
      case SALESMONTH:
        return getSalesMonth();
      case SALESYEAR:
        return getSalesYear();
      case SALESGROSSMARGINRATE:
        return getSalesGrossMarginRate();
      case YEARGROSSMARGINAMT:
        return getYearGrossMarginAmt();
      case BMRATE:
        return getBmRate();
      case VDSALESCHARGE:
        return getVdSalesCharge();
      case INSTALLSUPPORTAMTYEAR:
        return getInstallSupportAmtYear();
      case LEASECHARGEMONTH:
        return getLeaseChargeMonth();
      case CONSTRUCTIONCHARGE:
        return getConstructionCharge();
      case VDLEASECHARGE:
        return getVdLeaseCharge();
      case ELECTRICITYAMTMONTH:
        return getElectricityAmtMonth();
      case ELECTRICITYAMTYEAR:
        return getElectricityAmtYear();
      case TRANSPORTATIONCHARGE:
        return getTransportationCharge();
      case LABORCOSTOTHER:
        return getLaborCostOther();
      case TOTALCOST:
        return getTotalCost();
      case OPERATINGPROFIT:
        return getOperatingProfit();
      case OPERATINGPROFITRATE:
        return getOperatingProfitRate();
      case BREAKEVENPOINT:
        return getBreakEvenPoint();
      case CREATEDBY:
        return getCreatedBy();
      case CREATIONDATE:
        return getCreationDate();
      case LASTUPDATEDBY:
        return getLastUpdatedBy();
      case LASTUPDATEDATE:
        return getLastUpdateDate();
      case LASTUPDATELOGIN:
        return getLastUpdateLogin();
      case REQUESTID:
        return getRequestId();
      case PROGRAMAPPLICATIONID:
        return getProgramApplicationId();
      case PROGRAMID:
        return getProgramId();
      case PROGRAMUPDATEDATE:
        return getProgramUpdateDate();
      case APPBASENAME:
        return getAppBaseName();
      case FULLNAME:
        return getFullName();
      case UNNUMBERID:
        return getUnNumberId();
      case CONTRACTEXISTS:
        return getContractExists();
      case CONTRACTYEARMONTH:
        return getContractYearMonth();
      case CONTRACTSTARTYEAR:
        return getContractStartYear();
      case CONTRACTSTARTMONTH:
        return getContractStartMonth();
      case CONTRACTENDYEAR:
        return getContractEndYear();
      case CONTRACTENDMONTH:
        return getContractEndMonth();
      case BIDDINGITEM:
        return getBiddingItem();
      case CANCELLBEFOREMATURITY:
        return getCancellBeforeMaturity();
      case ADASSETSTYPE:
        return getAdAssetsType();
      case ADASSETSAMT:
        return getAdAssetsAmt();
      case ADASSETSTHISTIME:
        return getAdAssetsThisTime();
      case ADASSETSPAYMENTYEAR:
        return getAdAssetsPaymentYear();
      case ADASSETSPAYMENTDATE:
        return getAdAssetsPaymentDate();
      case TAXTYPE:
        return getTaxType();
      case INSTALLSUPPTYPE:
        return getInstallSuppType();
      case INSTALLSUPPPAYMENTTYPE:
        return getInstallSuppPaymentType();
      case INSTALLSUPPAMT:
        return getInstallSuppAmt();
      case INSTALLSUPPTHISTIME:
        return getInstallSuppThisTime();
      case INSTALLSUPPPAYMENTYEAR:
        return getInstallSuppPaymentYear();
      case INSTALLSUPPPAYMENTDATE:
        return getInstallSuppPaymentDate();
      case ELECTRICTYPE:
        return getElectricType();
      case ELECTRICPAYMENTTYPE:
        return getElectricPaymentType();
      case ELECTRICPAYMENTCHANGETYPE:
        return getElectricPaymentChangeType();
      case ELECTRICPAYMENTCYCLE:
        return getElectricPaymentCycle();
      case ELECTRICCLOSINGDATE:
        return getElectricClosingDate();
      case ELECTRICTRANSMONTH:
        return getElectricTransMonth();
      case ELECTRICTRANSDATE:
        return getElectricTransDate();
      case ELECTRICTRANSNAME:
        return getElectricTransName();
      case ELECTRICTRANSNAMEALT:
        return getElectricTransNameAlt();
      case INTROCHGTYPE:
        return getIntroChgType();
      case INTROCHGPAYMENTTYPE:
        return getIntroChgPaymentType();
      case INTROCHGAMT:
        return getIntroChgAmt();
      case INTROCHGTHISTIME:
        return getIntroChgThisTime();
      case INTROCHGPAYMENTYEAR:
        return getIntroChgPaymentYear();
      case INTROCHGPAYMENTDATE:
        return getIntroChgPaymentDate();
      case INTROCHGPERSALESPRICE:
        return getIntroChgPerSalesPrice();
      case INTROCHGPERPIECE:
        return getIntroChgPerPiece();
      case INTROCHGCLOSINGDATE:
        return getIntroChgClosingDate();
      case INTROCHGTRANSMONTH:
        return getIntroChgTransMonth();
      case INTROCHGTRANSDATE:
        return getIntroChgTransDate();
      case INTROCHGTRANSNAME:
        return getIntroChgTransName();
      case INTROCHGTRANSNAMEALT:
        return getIntroChgTransNameAlt();
      case XXCSOSPDECISIONALLCCLINEFULLVO:
        return getXxcsoSpDecisionAllCcLineFullVO();
      case XXCSOSPDECISIONATTACHFULLVO:
        return getXxcsoSpDecisionAttachFullVO();
      case XXCSOSPDECISIONBM1CUSTFULLVO:
        return getXxcsoSpDecisionBm1CustFullVO();
      case XXCSOSPDECISIONBM2CUSTFULLVO:
        return getXxcsoSpDecisionBm2CustFullVO();
      case XXCSOSPDECISIONBM3CUSTFULLVO:
        return getXxcsoSpDecisionBm3CustFullVO();
      case XXCSOSPDECISIONCNTRCTCUSTFULLVO:
        return getXxcsoSpDecisionCntrctCustFullVO();
      case XXCSOSPDECISIONINSTCUSTFULLVO:
        return getXxcsoSpDecisionInstCustFullVO();
      case XXCSOSPDECISIONSCLINEFULLVO:
        return getXxcsoSpDecisionScLineFullVO();
      case XXCSOSPDECISIONSELCCLINEFULLVO:
        return getXxcsoSpDecisionSelCcLineFullVO();
      case XXCSOSPDECISIONSENDFULLVO:
        return getXxcsoSpDecisionSendFullVO();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONHEADERID:
        setSpDecisionHeaderId((Number)value);
        return;
      case SPDECISIONNUMBER:
        setSpDecisionNumber((String)value);
        return;
      case SPDECISIONTYPE:
        setSpDecisionType((String)value);
        return;
      case STATUS:
        setStatus((String)value);
        return;
      case APPLICATIONNUMBER:
        setApplicationNumber((Number)value);
        return;
      case APPLICATIONDATE:
        setApplicationDate((Date)value);
        return;
      case APPROVALCOMPLETEDATE:
        setApprovalCompleteDate((Date)value);
        return;
      case APPLICATIONCODE:
        setApplicationCode((String)value);
        return;
      case APPBASECODE:
        setAppBaseCode((String)value);
        return;
      case APPLICATIONTYPE:
        setApplicationType((String)value);
        return;
      case NEWOLDTYPE:
        setNewoldType((String)value);
        return;
      case SELENUMBER:
        setSeleNumber((String)value);
        return;
      case MAKERCODE:
        setMakerCode((String)value);
        return;
      case STANDARDTYPE:
        setStandardType((String)value);
        return;
      case UNNUMBER:
        setUnNumber((String)value);
        return;
      case INSTALLDATE:
        setInstallDate((Date)value);
        return;
      case LEASECOMPANY:
        setLeaseCompany((String)value);
        return;
      case CONDITIONBUSINESSTYPE:
        setConditionBusinessType((String)value);
        return;
      case ALLCONTAINERTYPE:
        setAllContainerType((String)value);
        return;
      case CONTRACTYEARDATE:
        setContractYearDate((String)value);
        return;
      case INSTALLSUPPORTAMT:
        setInstallSupportAmt((String)value);
        return;
      case INSTALLSUPPORTAMT2:
        setInstallSupportAmt2((String)value);
        return;
      case PAYMENTCYCLE:
        setPaymentCycle((String)value);
        return;
      case ELECTRICITYTYPE:
        setElectricityType((String)value);
        return;
      case ELECTRICITYAMOUNT:
        setElectricityAmount((String)value);
        return;
      case CONDITIONREASON:
        setConditionReason((String)value);
        return;
      case BM1SENDTYPE:
        setBm1SendType((String)value);
        return;
      case OTHERCONTENT:
        setOtherContent((String)value);
        return;
      case SALESMONTH:
        setSalesMonth((String)value);
        return;
      case SALESYEAR:
        setSalesYear((String)value);
        return;
      case SALESGROSSMARGINRATE:
        setSalesGrossMarginRate((String)value);
        return;
      case YEARGROSSMARGINAMT:
        setYearGrossMarginAmt((String)value);
        return;
      case BMRATE:
        setBmRate((String)value);
        return;
      case VDSALESCHARGE:
        setVdSalesCharge((String)value);
        return;
      case INSTALLSUPPORTAMTYEAR:
        setInstallSupportAmtYear((String)value);
        return;
      case LEASECHARGEMONTH:
        setLeaseChargeMonth((String)value);
        return;
      case CONSTRUCTIONCHARGE:
        setConstructionCharge((String)value);
        return;
      case VDLEASECHARGE:
        setVdLeaseCharge((String)value);
        return;
      case ELECTRICITYAMTMONTH:
        setElectricityAmtMonth((String)value);
        return;
      case ELECTRICITYAMTYEAR:
        setElectricityAmtYear((String)value);
        return;
      case TRANSPORTATIONCHARGE:
        setTransportationCharge((String)value);
        return;
      case LABORCOSTOTHER:
        setLaborCostOther((String)value);
        return;
      case TOTALCOST:
        setTotalCost((String)value);
        return;
      case OPERATINGPROFIT:
        setOperatingProfit((String)value);
        return;
      case OPERATINGPROFITRATE:
        setOperatingProfitRate((String)value);
        return;
      case BREAKEVENPOINT:
        setBreakEvenPoint((String)value);
        return;
      case CREATEDBY:
        setCreatedBy((Number)value);
        return;
      case CREATIONDATE:
        setCreationDate((Date)value);
        return;
      case LASTUPDATEDBY:
        setLastUpdatedBy((Number)value);
        return;
      case LASTUPDATEDATE:
        setLastUpdateDate((Date)value);
        return;
      case LASTUPDATELOGIN:
        setLastUpdateLogin((Number)value);
        return;
      case REQUESTID:
        setRequestId((Number)value);
        return;
      case PROGRAMAPPLICATIONID:
        setProgramApplicationId((Number)value);
        return;
      case PROGRAMID:
        setProgramId((Number)value);
        return;
      case PROGRAMUPDATEDATE:
        setProgramUpdateDate((Date)value);
        return;
      case APPBASENAME:
        setAppBaseName((String)value);
        return;
      case FULLNAME:
        setFullName((String)value);
        return;
      case UNNUMBERID:
        setUnNumberId((Number)value);
        return;
      case CONTRACTEXISTS:
        setContractExists((String)value);
        return;
      case CONTRACTYEARMONTH:
        setContractYearMonth((String)value);
        return;
      case CONTRACTSTARTYEAR:
        setContractStartYear((String)value);
        return;
      case CONTRACTSTARTMONTH:
        setContractStartMonth((String)value);
        return;
      case CONTRACTENDYEAR:
        setContractEndYear((String)value);
        return;
      case CONTRACTENDMONTH:
        setContractEndMonth((String)value);
        return;
      case BIDDINGITEM:
        setBiddingItem((String)value);
        return;
      case CANCELLBEFOREMATURITY:
        setCancellBeforeMaturity((String)value);
        return;
      case ADASSETSTYPE:
        setAdAssetsType((String)value);
        return;
      case ADASSETSAMT:
        setAdAssetsAmt((String)value);
        return;
      case ADASSETSTHISTIME:
        setAdAssetsThisTime((String)value);
        return;
      case ADASSETSPAYMENTYEAR:
        setAdAssetsPaymentYear((String)value);
        return;
      case ADASSETSPAYMENTDATE:
        setAdAssetsPaymentDate((Date)value);
        return;
      case TAXTYPE:
        setTaxType((String)value);
        return;
      case INSTALLSUPPTYPE:
        setInstallSuppType((String)value);
        return;
      case INSTALLSUPPPAYMENTTYPE:
        setInstallSuppPaymentType((String)value);
        return;
      case INSTALLSUPPAMT:
        setInstallSuppAmt((String)value);
        return;
      case INSTALLSUPPTHISTIME:
        setInstallSuppThisTime((String)value);
        return;
      case INSTALLSUPPPAYMENTYEAR:
        setInstallSuppPaymentYear((String)value);
        return;
      case INSTALLSUPPPAYMENTDATE:
        setInstallSuppPaymentDate((Date)value);
        return;
      case ELECTRICTYPE:
        setElectricType((String)value);
        return;
      case ELECTRICPAYMENTTYPE:
        setElectricPaymentType((String)value);
        return;
      case ELECTRICPAYMENTCHANGETYPE:
        setElectricPaymentChangeType((String)value);
        return;
      case ELECTRICPAYMENTCYCLE:
        setElectricPaymentCycle((String)value);
        return;
      case ELECTRICCLOSINGDATE:
        setElectricClosingDate((String)value);
        return;
      case ELECTRICTRANSMONTH:
        setElectricTransMonth((String)value);
        return;
      case ELECTRICTRANSDATE:
        setElectricTransDate((String)value);
        return;
      case ELECTRICTRANSNAME:
        setElectricTransName((String)value);
        return;
      case ELECTRICTRANSNAMEALT:
        setElectricTransNameAlt((String)value);
        return;
      case INTROCHGTYPE:
        setIntroChgType((String)value);
        return;
      case INTROCHGPAYMENTTYPE:
        setIntroChgPaymentType((String)value);
        return;
      case INTROCHGAMT:
        setIntroChgAmt((String)value);
        return;
      case INTROCHGTHISTIME:
        setIntroChgThisTime((String)value);
        return;
      case INTROCHGPAYMENTYEAR:
        setIntroChgPaymentYear((String)value);
        return;
      case INTROCHGPAYMENTDATE:
        setIntroChgPaymentDate((Date)value);
        return;
      case INTROCHGPERSALESPRICE:
        setIntroChgPerSalesPrice((String)value);
        return;
      case INTROCHGPERPIECE:
        setIntroChgPerPiece((String)value);
        return;
      case INTROCHGCLOSINGDATE:
        setIntroChgClosingDate((String)value);
        return;
      case INTROCHGTRANSMONTH:
        setIntroChgTransMonth((String)value);
        return;
      case INTROCHGTRANSDATE:
        setIntroChgTransDate((String)value);
        return;
      case INTROCHGTRANSNAME:
        setIntroChgTransName((String)value);
        return;
      case INTROCHGTRANSNAMEALT:
        setIntroChgTransNameAlt((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoSpDecisionInstCustFullVO
   */
  public oracle.jbo.RowIterator getXxcsoSpDecisionInstCustFullVO()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOSPDECISIONINSTCUSTFULLVO);
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoSpDecisionCntrctCustFullVO
   */
  public oracle.jbo.RowIterator getXxcsoSpDecisionCntrctCustFullVO()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOSPDECISIONCNTRCTCUSTFULLVO);
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoSpDecisionBm1CustFullVO
   */
  public oracle.jbo.RowIterator getXxcsoSpDecisionBm1CustFullVO()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOSPDECISIONBM1CUSTFULLVO);
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoSpDecisionBm2CustFullVO
   */
  public oracle.jbo.RowIterator getXxcsoSpDecisionBm2CustFullVO()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOSPDECISIONBM2CUSTFULLVO);
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoSpDecisionBm3CustFullVO
   */
  public oracle.jbo.RowIterator getXxcsoSpDecisionBm3CustFullVO()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOSPDECISIONBM3CUSTFULLVO);
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoSpDecisionScLineFullVO
   */
  public oracle.jbo.RowIterator getXxcsoSpDecisionScLineFullVO()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOSPDECISIONSCLINEFULLVO);
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoSpDecisionAllCcLineFullVO
   */
  public oracle.jbo.RowIterator getXxcsoSpDecisionAllCcLineFullVO()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOSPDECISIONALLCCLINEFULLVO);
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoSpDecisionSelCcLineFullVO
   */
  public oracle.jbo.RowIterator getXxcsoSpDecisionSelCcLineFullVO()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOSPDECISIONSELCCLINEFULLVO);
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoSpDecisionAttachFullVO
   */
  public oracle.jbo.RowIterator getXxcsoSpDecisionAttachFullVO()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOSPDECISIONATTACHFULLVO);
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoSpDecisionSendFullVO
   */
  public oracle.jbo.RowIterator getXxcsoSpDecisionSendFullVO()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOSPDECISIONSENDFULLVO);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AppBaseName
   */
  public String getAppBaseName()
  {
    return (String)getAttributeInternal(APPBASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AppBaseName
   */
  public void setAppBaseName(String value)
  {
    setAttributeInternal(APPBASENAME, value);
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
   * Gets the attribute value for the calculated attribute UnNumberId
   */
  public Number getUnNumberId()
  {
    return (Number)getAttributeInternal(UNNUMBERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UnNumberId
   */
  public void setUnNumberId(Number value)
  {
    setAttributeInternal(UNNUMBERID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractExists
   */
  public String getContractExists()
  {
    return (String)getAttributeInternal(CONTRACTEXISTS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractExists
   */
  public void setContractExists(String value)
  {
    setAttributeInternal(CONTRACTEXISTS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractYearMonth
   */
  public String getContractYearMonth()
  {
    return (String)getAttributeInternal(CONTRACTYEARMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractYearMonth
   */
  public void setContractYearMonth(String value)
  {
    setAttributeInternal(CONTRACTYEARMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractStartYear
   */
  public String getContractStartYear()
  {
    return (String)getAttributeInternal(CONTRACTSTARTYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractStartYear
   */
  public void setContractStartYear(String value)
  {
    setAttributeInternal(CONTRACTSTARTYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractStartMonth
   */
  public String getContractStartMonth()
  {
    return (String)getAttributeInternal(CONTRACTSTARTMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractStartMonth
   */
  public void setContractStartMonth(String value)
  {
    setAttributeInternal(CONTRACTSTARTMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractEndYear
   */
  public String getContractEndYear()
  {
    return (String)getAttributeInternal(CONTRACTENDYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractEndYear
   */
  public void setContractEndYear(String value)
  {
    setAttributeInternal(CONTRACTENDYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractEndMonth
   */
  public String getContractEndMonth()
  {
    return (String)getAttributeInternal(CONTRACTENDMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractEndMonth
   */
  public void setContractEndMonth(String value)
  {
    setAttributeInternal(CONTRACTENDMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BiddingItem
   */
  public String getBiddingItem()
  {
    return (String)getAttributeInternal(BIDDINGITEM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BiddingItem
   */
  public void setBiddingItem(String value)
  {
    setAttributeInternal(BIDDINGITEM, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CancellBeforeMaturity
   */
  public String getCancellBeforeMaturity()
  {
    return (String)getAttributeInternal(CANCELLBEFOREMATURITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CancellBeforeMaturity
   */
  public void setCancellBeforeMaturity(String value)
  {
    setAttributeInternal(CANCELLBEFOREMATURITY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AdAssetsType
   */
  public String getAdAssetsType()
  {
    return (String)getAttributeInternal(ADASSETSTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AdAssetsType
   */
  public void setAdAssetsType(String value)
  {
    setAttributeInternal(ADASSETSTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AdAssetsAmt
   */
  public String getAdAssetsAmt()
  {
    return (String)getAttributeInternal(ADASSETSAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AdAssetsAmt
   */
  public void setAdAssetsAmt(String value)
  {
    setAttributeInternal(ADASSETSAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AdAssetsThisTime
   */
  public String getAdAssetsThisTime()
  {
    return (String)getAttributeInternal(ADASSETSTHISTIME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AdAssetsThisTime
   */
  public void setAdAssetsThisTime(String value)
  {
    setAttributeInternal(ADASSETSTHISTIME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AdAssetsPaymentYear
   */
  public String getAdAssetsPaymentYear()
  {
    return (String)getAttributeInternal(ADASSETSPAYMENTYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AdAssetsPaymentYear
   */
  public void setAdAssetsPaymentYear(String value)
  {
    setAttributeInternal(ADASSETSPAYMENTYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AdAssetsPaymentDate
   */
  public Date getAdAssetsPaymentDate()
  {
    return (Date)getAttributeInternal(ADASSETSPAYMENTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AdAssetsPaymentDate
   */
  public void setAdAssetsPaymentDate(Date value)
  {
    setAttributeInternal(ADASSETSPAYMENTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TaxType
   */
  public String getTaxType()
  {
    return (String)getAttributeInternal(TAXTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TaxType
   */
  public void setTaxType(String value)
  {
    setAttributeInternal(TAXTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppType
   */
  public String getInstallSuppType()
  {
    return (String)getAttributeInternal(INSTALLSUPPTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppType
   */
  public void setInstallSuppType(String value)
  {
    setAttributeInternal(INSTALLSUPPTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppPaymentType
   */
  public String getInstallSuppPaymentType()
  {
    return (String)getAttributeInternal(INSTALLSUPPPAYMENTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppPaymentType
   */
  public void setInstallSuppPaymentType(String value)
  {
    setAttributeInternal(INSTALLSUPPPAYMENTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppAmt
   */
  public String getInstallSuppAmt()
  {
    return (String)getAttributeInternal(INSTALLSUPPAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppAmt
   */
  public void setInstallSuppAmt(String value)
  {
    setAttributeInternal(INSTALLSUPPAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppThisTime
   */
  public String getInstallSuppThisTime()
  {
    return (String)getAttributeInternal(INSTALLSUPPTHISTIME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppThisTime
   */
  public void setInstallSuppThisTime(String value)
  {
    setAttributeInternal(INSTALLSUPPTHISTIME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppPaymentYear
   */
  public String getInstallSuppPaymentYear()
  {
    return (String)getAttributeInternal(INSTALLSUPPPAYMENTYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppPaymentYear
   */
  public void setInstallSuppPaymentYear(String value)
  {
    setAttributeInternal(INSTALLSUPPPAYMENTYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallSuppPaymentDate
   */
  public Date getInstallSuppPaymentDate()
  {
    return (Date)getAttributeInternal(INSTALLSUPPPAYMENTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallSuppPaymentDate
   */
  public void setInstallSuppPaymentDate(Date value)
  {
    setAttributeInternal(INSTALLSUPPPAYMENTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricType
   */
  public String getElectricType()
  {
    return (String)getAttributeInternal(ELECTRICTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricType
   */
  public void setElectricType(String value)
  {
    setAttributeInternal(ELECTRICTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentType
   */
  public String getElectricPaymentType()
  {
    return (String)getAttributeInternal(ELECTRICPAYMENTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentType
   */
  public void setElectricPaymentType(String value)
  {
    setAttributeInternal(ELECTRICPAYMENTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentChangeType
   */
  public String getElectricPaymentChangeType()
  {
    return (String)getAttributeInternal(ELECTRICPAYMENTCHANGETYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentChangeType
   */
  public void setElectricPaymentChangeType(String value)
  {
    setAttributeInternal(ELECTRICPAYMENTCHANGETYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricPaymentCycle
   */
  public String getElectricPaymentCycle()
  {
    return (String)getAttributeInternal(ELECTRICPAYMENTCYCLE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricPaymentCycle
   */
  public void setElectricPaymentCycle(String value)
  {
    setAttributeInternal(ELECTRICPAYMENTCYCLE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricClosingDate
   */
  public String getElectricClosingDate()
  {
    return (String)getAttributeInternal(ELECTRICCLOSINGDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricClosingDate
   */
  public void setElectricClosingDate(String value)
  {
    setAttributeInternal(ELECTRICCLOSINGDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransMonth
   */
  public String getElectricTransMonth()
  {
    return (String)getAttributeInternal(ELECTRICTRANSMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransMonth
   */
  public void setElectricTransMonth(String value)
  {
    setAttributeInternal(ELECTRICTRANSMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransDate
   */
  public String getElectricTransDate()
  {
    return (String)getAttributeInternal(ELECTRICTRANSDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransDate
   */
  public void setElectricTransDate(String value)
  {
    setAttributeInternal(ELECTRICTRANSDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransName
   */
  public String getElectricTransName()
  {
    return (String)getAttributeInternal(ELECTRICTRANSNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransName
   */
  public void setElectricTransName(String value)
  {
    setAttributeInternal(ELECTRICTRANSNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricTransNameAlt
   */
  public String getElectricTransNameAlt()
  {
    return (String)getAttributeInternal(ELECTRICTRANSNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricTransNameAlt
   */
  public void setElectricTransNameAlt(String value)
  {
    setAttributeInternal(ELECTRICTRANSNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgType
   */
  public String getIntroChgType()
  {
    return (String)getAttributeInternal(INTROCHGTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgType
   */
  public void setIntroChgType(String value)
  {
    setAttributeInternal(INTROCHGTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPaymentType
   */
  public String getIntroChgPaymentType()
  {
    return (String)getAttributeInternal(INTROCHGPAYMENTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPaymentType
   */
  public void setIntroChgPaymentType(String value)
  {
    setAttributeInternal(INTROCHGPAYMENTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgAmt
   */
  public String getIntroChgAmt()
  {
    return (String)getAttributeInternal(INTROCHGAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgAmt
   */
  public void setIntroChgAmt(String value)
  {
    setAttributeInternal(INTROCHGAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgThisTime
   */
  public String getIntroChgThisTime()
  {
    return (String)getAttributeInternal(INTROCHGTHISTIME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgThisTime
   */
  public void setIntroChgThisTime(String value)
  {
    setAttributeInternal(INTROCHGTHISTIME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPaymentYear
   */
  public String getIntroChgPaymentYear()
  {
    return (String)getAttributeInternal(INTROCHGPAYMENTYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPaymentYear
   */
  public void setIntroChgPaymentYear(String value)
  {
    setAttributeInternal(INTROCHGPAYMENTYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPaymentDate
   */
  public Date getIntroChgPaymentDate()
  {
    return (Date)getAttributeInternal(INTROCHGPAYMENTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPaymentDate
   */
  public void setIntroChgPaymentDate(Date value)
  {
    setAttributeInternal(INTROCHGPAYMENTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgPerSalesPrice
   */
  public String getIntroChgPerSalesPrice()
  {
    return (String)getAttributeInternal(INTROCHGPERSALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgPerSalesPrice
   */
  public void setIntroChgPerSalesPrice(String value)
  {
    setAttributeInternal(INTROCHGPERSALESPRICE, value);
  }









  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgTransName
   */
  public String getIntroChgTransName()
  {
    return (String)getAttributeInternal(INTROCHGTRANSNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgTransName
   */
  public void setIntroChgTransName(String value)
  {
    setAttributeInternal(INTROCHGTRANSNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgTransNameAlt
   */
  public String getIntroChgTransNameAlt()
  {
    return (String)getAttributeInternal(INTROCHGTRANSNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgTransNameAlt
   */
  public void setIntroChgTransNameAlt(String value)
  {
    setAttributeInternal(INTROCHGTRANSNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for INTRO_CHG_PER_PIECE using the alias name IntroChgPerPiece
   */
  public String getIntroChgPerPiece()
  {
    return (String)getAttributeInternal(INTROCHGPERPIECE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INTRO_CHG_PER_PIECE using the alias name IntroChgPerPiece
   */
  public void setIntroChgPerPiece(String value)
  {
    setAttributeInternal(INTROCHGPERPIECE, value);
  }

  /**
   * 
   * Gets the attribute value for INTRO_CHG_CLOSING_DATE using the alias name IntroChgClosingDate
   */
  public String getIntroChgClosingDate()
  {
    return (String)getAttributeInternal(INTROCHGCLOSINGDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INTRO_CHG_CLOSING_DATE using the alias name IntroChgClosingDate
   */
  public void setIntroChgClosingDate(String value)
  {
    setAttributeInternal(INTROCHGCLOSINGDATE, value);
  }

  /**
   * 
   * Gets the attribute value for INTRO_CHG_TRANS_MONTH using the alias name IntroChgTransMonth
   */
  public String getIntroChgTransMonth()
  {
    return (String)getAttributeInternal(INTROCHGTRANSMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INTRO_CHG_TRANS_MONTH using the alias name IntroChgTransMonth
   */
  public void setIntroChgTransMonth(String value)
  {
    setAttributeInternal(INTROCHGTRANSMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for INTRO_CHG_TRANS_DATE using the alias name IntroChgTransDate
   */
  public String getIntroChgTransDate()
  {
    return (String)getAttributeInternal(INTROCHGTRANSDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INTRO_CHG_TRANS_DATE using the alias name IntroChgTransDate
   */
  public void setIntroChgTransDate(String value)
  {
    setAttributeInternal(INTROCHGTRANSDATE, value);
  }



























}