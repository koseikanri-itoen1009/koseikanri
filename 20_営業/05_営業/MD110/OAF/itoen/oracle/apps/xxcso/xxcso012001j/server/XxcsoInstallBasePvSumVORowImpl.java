/*============================================================================
* ファイル名 : XxcsoInstallBasePvSumVORowImpl
* 概要説明   : 物件情報汎用検索画面／物件情報検索ビュー行オブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-24 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 物件情報を検索するためのビュー行クラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBasePvSumVORowImpl extends OAViewRowImpl 
{




  protected static final int DEPTCODE = 0;
  protected static final int VENDORTYPE = 1;
  protected static final int VENDORCODE = 2;
  protected static final int VENDORMODEL = 3;
  protected static final int SELENUM = 4;
  protected static final int JOTAIKBN1 = 5;
  protected static final int JOTAIKBN2 = 6;
  protected static final int JOTAIKBN3 = 7;
  protected static final int ACCOUNTNUMBER = 8;
  protected static final int PARTYNAME = 9;
  protected static final int HIKISAKIGAISYACD = 10;
  protected static final int HIKISAKIJIGYOSYOCD = 11;
  protected static final int VENDORNUMBER = 12;
  protected static final int ANNUALTYPE = 13;
  protected static final int MAKERCODE = 14;
  protected static final int LEASESTARTDATE = 15;
  protected static final int FIRSTCHARGE = 16;
  protected static final int SECONDCHARGE = 17;
  protected static final int INSTALLDATE = 18;
  protected static final int INSTALLADDRESS1 = 19;
  protected static final int INSTALLADDRESS2 = 20;
  protected static final int INSTALLINDUSTRYTYPE = 21;
  protected static final int WIDTH = 22;
  protected static final int DEPTH = 23;
  protected static final int HEIGHT = 24;
  protected static final int CONTRACTNUMBER = 25;
  protected static final int RESOURCENAME = 26;
  protected static final int COUNTNO = 27;
  protected static final int NYUKODT = 28;
  protected static final int SPECIAL1 = 29;
  protected static final int SPECIAL2 = 30;
  protected static final int SPECIAL3 = 31;
  protected static final int CHIKUCD = 32;
  protected static final int SYOYUCD = 33;
  protected static final int ORIGLEASECONTRACTNUMBER = 34;
  protected static final int ORIGLEASEBRANCHNUMBER = 35;
  protected static final int LEASECONTRACTDATE = 36;
  protected static final int LEASECONTRACTNUMBER = 37;
  protected static final int LEASEBRANCHNUMBER = 38;
  protected static final int PARTYNAMEPHONETIC = 39;
  protected static final int VENTASYACD01 = 40;
  protected static final int VENTASYADAISU01 = 41;
  protected static final int VENTASYACD02 = 42;
  protected static final int VENTASYADAISU02 = 43;
  protected static final int VENTASYACD03 = 44;
  protected static final int VENTASYADAISU03 = 45;
  protected static final int VENTASYACD04 = 46;
  protected static final int VENTASYADAISU04 = 47;
  protected static final int VENTASYACD05 = 48;
  protected static final int VENTASYADAISU05 = 49;
  protected static final int LEASESTATUS = 50;
  protected static final int PAYMENTFREQUENCY = 51;
  protected static final int LEASEENDDATE = 52;
  protected static final int SPDECISIONNUMBER = 53;
  protected static final int INSTALLLOCATION = 54;
  protected static final int VENDORFORM = 55;
  protected static final int LASTPARTYNAME = 56;
  protected static final int LASTACCOUNTCODE = 57;
  protected static final int LASTINSTALLPLACENAME = 58;
  protected static final int JOBKBN2 = 59;
  protected static final int SINTYOKUKBN2 = 60;
  protected static final int SAGYOLEVEL = 61;
  protected static final int SAGYOUGAISYACD = 62;
  protected static final int JIGYOSYOCD = 63;
  protected static final int DENNO = 64;
  protected static final int JOBKBN = 65;
  protected static final int SINTYOKUKBN = 66;
  protected static final int YOTEIDT = 67;
  protected static final int DENNO2 = 68;
  protected static final int HAIKIKESSAIDT = 69;
  protected static final int TENHAITANTO = 70;
  protected static final int TENHAIDENNO = 71;
  protected static final int TENHAIFLG = 72;
  protected static final int KANRYOKBN = 73;
  protected static final int PURCHASEAMOUNT = 74;
  protected static final int CANCELLATIONDATE = 75;
  protected static final int MAKERNAME = 76;
  protected static final int SAFETYLEVEL = 77;
  protected static final int OPREQUESTFLAG = 78;
  protected static final int OPREQNUMBERACCOUNTNUMBER = 79;
  protected static final int INSTANCEID = 80;
  protected static final int INSTALLCODE = 81;
  protected static final int INSTANCETYPECODE = 82;
  protected static final int INSTALLACCOUNTID = 83;
  protected static final int INSTALLPARTYID = 84;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallBasePvSumVORowImpl()
  {
  }


  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case DEPTCODE:
        return getDeptCode();
      case VENDORTYPE:
        return getVendorType();
      case VENDORCODE:
        return getVendorCode();
      case VENDORMODEL:
        return getVendorModel();
      case SELENUM:
        return getSeleNum();
      case JOTAIKBN1:
        return getJotaiKbn1();
      case JOTAIKBN2:
        return getJotaiKbn2();
      case JOTAIKBN3:
        return getJotaiKbn3();
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case PARTYNAME:
        return getPartyName();
      case HIKISAKIGAISYACD:
        return getHikisakigaisyaCd();
      case HIKISAKIJIGYOSYOCD:
        return getHikisakijigyosyoCd();
      case VENDORNUMBER:
        return getVendorNumber();
      case ANNUALTYPE:
        return getAnnualType();
      case MAKERCODE:
        return getMakerCode();
      case LEASESTARTDATE:
        return getLeaseStartDate();
      case FIRSTCHARGE:
        return getFirstCharge();
      case SECONDCHARGE:
        return getSecondCharge();
      case INSTALLDATE:
        return getInstallDate();
      case INSTALLADDRESS1:
        return getInstallAddress1();
      case INSTALLADDRESS2:
        return getInstallAddress2();
      case INSTALLINDUSTRYTYPE:
        return getInstallIndustryType();
      case WIDTH:
        return getWidth();
      case DEPTH:
        return getDepth();
      case HEIGHT:
        return getHeight();
      case CONTRACTNUMBER:
        return getContractNumber();
      case RESOURCENAME:
        return getResourceName();
      case COUNTNO:
        return getCountNo();
      case NYUKODT:
        return getNyukoDt();
      case SPECIAL1:
        return getSpecial1();
      case SPECIAL2:
        return getSpecial2();
      case SPECIAL3:
        return getSpecial3();
      case CHIKUCD:
        return getChikuCd();
      case SYOYUCD:
        return getSyoyuCd();
      case ORIGLEASECONTRACTNUMBER:
        return getOrigLeaseContractNumber();
      case ORIGLEASEBRANCHNUMBER:
        return getOrigLeaseBranchNumber();
      case LEASECONTRACTDATE:
        return getLeaseContractDate();
      case LEASECONTRACTNUMBER:
        return getLeaseContractNumber();
      case LEASEBRANCHNUMBER:
        return getLeaseBranchNumber();
      case PARTYNAMEPHONETIC:
        return getPartyNamePhonetic();
      case VENTASYACD01:
        return getVenTasyaCd01();
      case VENTASYADAISU01:
        return getVenTasyaDaisu01();
      case VENTASYACD02:
        return getVenTasyaCd02();
      case VENTASYADAISU02:
        return getVenTasyaDaisu02();
      case VENTASYACD03:
        return getVenTasyaCd03();
      case VENTASYADAISU03:
        return getVenTasyaDaisu03();
      case VENTASYACD04:
        return getVenTasyaCd04();
      case VENTASYADAISU04:
        return getVenTasyaDaisu04();
      case VENTASYACD05:
        return getVenTasyaCd05();
      case VENTASYADAISU05:
        return getVenTasyaDaisu05();
      case LEASESTATUS:
        return getLeaseStatus();
      case PAYMENTFREQUENCY:
        return getPaymentFrequency();
      case LEASEENDDATE:
        return getLeaseEndDate();
      case SPDECISIONNUMBER:
        return getSpDecisionNumber();
      case INSTALLLOCATION:
        return getInstallLocation();
      case VENDORFORM:
        return getVendorForm();
      case LASTPARTYNAME:
        return getLastPartyName();
      case LASTACCOUNTCODE:
        return getLastAccountCode();
      case LASTINSTALLPLACENAME:
        return getLastInstallPlaceName();
      case JOBKBN2:
        return getJobKbn2();
      case SINTYOKUKBN2:
        return getSintyokuKbn2();
      case SAGYOLEVEL:
        return getSagyoLevel();
      case SAGYOUGAISYACD:
        return getSagyougaisyaCd();
      case JIGYOSYOCD:
        return getJigyosyoCd();
      case DENNO:
        return getDenNo();
      case JOBKBN:
        return getJobKbn();
      case SINTYOKUKBN:
        return getSintyokuKbn();
      case YOTEIDT:
        return getYoteiDt();
      case DENNO2:
        return getDenNo2();
      case HAIKIKESSAIDT:
        return getHaikikessaiDt();
      case TENHAITANTO:
        return getTenhaiTanto();
      case TENHAIDENNO:
        return getTenhaiDenNo();
      case TENHAIFLG:
        return getTenhaiFlg();
      case KANRYOKBN:
        return getKanryoKbn();
      case PURCHASEAMOUNT:
        return getPurchaseAmount();
      case CANCELLATIONDATE:
        return getCancellationDate();
      case MAKERNAME:
        return getMakerName();
      case SAFETYLEVEL:
        return getSafetyLevel();
      case OPREQUESTFLAG:
        return getOpRequestFlag();
      case OPREQNUMBERACCOUNTNUMBER:
        return getOpReqNumberAccountNumber();
      case INSTANCEID:
        return getInstanceId();
      case INSTALLCODE:
        return getInstallCode();
      case INSTANCETYPECODE:
        return getInstanceTypeCode();
      case INSTALLACCOUNTID:
        return getInstallAccountId();
      case INSTALLPARTYID:
        return getInstallPartyId();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case DEPTCODE:
        setDeptCode((String)value);
        return;
      case VENDORTYPE:
        setVendorType((String)value);
        return;
      case VENDORCODE:
        setVendorCode((String)value);
        return;
      case VENDORMODEL:
        setVendorModel((String)value);
        return;
      case SELENUM:
        setSeleNum((String)value);
        return;
      case JOTAIKBN1:
        setJotaiKbn1((String)value);
        return;
      case JOTAIKBN2:
        setJotaiKbn2((String)value);
        return;
      case JOTAIKBN3:
        setJotaiKbn3((String)value);
        return;
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
        return;
      case HIKISAKIGAISYACD:
        setHikisakigaisyaCd((String)value);
        return;
      case HIKISAKIJIGYOSYOCD:
        setHikisakijigyosyoCd((String)value);
        return;
      case VENDORNUMBER:
        setVendorNumber((String)value);
        return;
      case ANNUALTYPE:
        setAnnualType((String)value);
        return;
      case MAKERCODE:
        setMakerCode((String)value);
        return;
      case LEASESTARTDATE:
        setLeaseStartDate((String)value);
        return;
      case FIRSTCHARGE:
        setFirstCharge((String)value);
        return;
      case SECONDCHARGE:
        setSecondCharge((String)value);
        return;
      case INSTALLDATE:
        setInstallDate((String)value);
        return;
      case INSTALLADDRESS1:
        setInstallAddress1((String)value);
        return;
      case INSTALLADDRESS2:
        setInstallAddress2((String)value);
        return;
      case INSTALLINDUSTRYTYPE:
        setInstallIndustryType((String)value);
        return;
      case WIDTH:
        setWidth((String)value);
        return;
      case DEPTH:
        setDepth((String)value);
        return;
      case HEIGHT:
        setHeight((String)value);
        return;
      case CONTRACTNUMBER:
        setContractNumber((String)value);
        return;
      case RESOURCENAME:
        setResourceName((String)value);
        return;
      case COUNTNO:
        setCountNo((String)value);
        return;
      case NYUKODT:
        setNyukoDt((String)value);
        return;
      case SPECIAL1:
        setSpecial1((String)value);
        return;
      case SPECIAL2:
        setSpecial2((String)value);
        return;
      case SPECIAL3:
        setSpecial3((String)value);
        return;
      case CHIKUCD:
        setChikuCd((String)value);
        return;
      case SYOYUCD:
        setSyoyuCd((String)value);
        return;
      case ORIGLEASECONTRACTNUMBER:
        setOrigLeaseContractNumber((String)value);
        return;
      case ORIGLEASEBRANCHNUMBER:
        setOrigLeaseBranchNumber((String)value);
        return;
      case LEASECONTRACTDATE:
        setLeaseContractDate((String)value);
        return;
      case LEASECONTRACTNUMBER:
        setLeaseContractNumber((String)value);
        return;
      case LEASEBRANCHNUMBER:
        setLeaseBranchNumber((String)value);
        return;
      case PARTYNAMEPHONETIC:
        setPartyNamePhonetic((String)value);
        return;
      case VENTASYACD01:
        setVenTasyaCd01((String)value);
        return;
      case VENTASYADAISU01:
        setVenTasyaDaisu01((String)value);
        return;
      case VENTASYACD02:
        setVenTasyaCd02((String)value);
        return;
      case VENTASYADAISU02:
        setVenTasyaDaisu02((String)value);
        return;
      case VENTASYACD03:
        setVenTasyaCd03((String)value);
        return;
      case VENTASYADAISU03:
        setVenTasyaDaisu03((String)value);
        return;
      case VENTASYACD04:
        setVenTasyaCd04((String)value);
        return;
      case VENTASYADAISU04:
        setVenTasyaDaisu04((String)value);
        return;
      case VENTASYACD05:
        setVenTasyaCd05((String)value);
        return;
      case VENTASYADAISU05:
        setVenTasyaDaisu05((String)value);
        return;
      case LEASESTATUS:
        setLeaseStatus((String)value);
        return;
      case PAYMENTFREQUENCY:
        setPaymentFrequency((String)value);
        return;
      case LEASEENDDATE:
        setLeaseEndDate((String)value);
        return;
      case SPDECISIONNUMBER:
        setSpDecisionNumber((String)value);
        return;
      case INSTALLLOCATION:
        setInstallLocation((String)value);
        return;
      case VENDORFORM:
        setVendorForm((String)value);
        return;
      case LASTPARTYNAME:
        setLastPartyName((String)value);
        return;
      case LASTACCOUNTCODE:
        setLastAccountCode((String)value);
        return;
      case LASTINSTALLPLACENAME:
        setLastInstallPlaceName((String)value);
        return;
      case JOBKBN2:
        setJobKbn2((String)value);
        return;
      case SINTYOKUKBN2:
        setSintyokuKbn2((String)value);
        return;
      case SAGYOLEVEL:
        setSagyoLevel((String)value);
        return;
      case SAGYOUGAISYACD:
        setSagyougaisyaCd((String)value);
        return;
      case JIGYOSYOCD:
        setJigyosyoCd((String)value);
        return;
      case DENNO:
        setDenNo((String)value);
        return;
      case JOBKBN:
        setJobKbn((String)value);
        return;
      case SINTYOKUKBN:
        setSintyokuKbn((String)value);
        return;
      case YOTEIDT:
        setYoteiDt((String)value);
        return;
      case DENNO2:
        setDenNo2((String)value);
        return;
      case HAIKIKESSAIDT:
        setHaikikessaiDt((String)value);
        return;
      case TENHAITANTO:
        setTenhaiTanto((String)value);
        return;
      case TENHAIDENNO:
        setTenhaiDenNo((String)value);
        return;
      case TENHAIFLG:
        setTenhaiFlg((String)value);
        return;
      case KANRYOKBN:
        setKanryoKbn((String)value);
        return;
      case PURCHASEAMOUNT:
        setPurchaseAmount((String)value);
        return;
      case CANCELLATIONDATE:
        setCancellationDate((String)value);
        return;
      case MAKERNAME:
        setMakerName((String)value);
        return;
      case SAFETYLEVEL:
        setSafetyLevel((String)value);
        return;
      case INSTANCEID:
        setInstanceId((Number)value);
        return;
      case INSTALLCODE:
        setInstallCode((String)value);
        return;
      case INSTANCETYPECODE:
        setInstanceTypeCode((String)value);
        return;
      case INSTALLACCOUNTID:
        setInstallAccountId((String)value);
        return;
      case INSTALLPARTYID:
        setInstallPartyId((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorType
   */
  public String getVendorType()
  {
    return (String)getAttributeInternal(VENDORTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorType
   */
  public void setVendorType(String value)
  {
    setAttributeInternal(VENDORTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorCode
   */
  public String getVendorCode()
  {
    return (String)getAttributeInternal(VENDORCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorCode
   */
  public void setVendorCode(String value)
  {
    setAttributeInternal(VENDORCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorModel
   */
  public String getVendorModel()
  {
    return (String)getAttributeInternal(VENDORMODEL);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorModel
   */
  public void setVendorModel(String value)
  {
    setAttributeInternal(VENDORMODEL, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SeleNum
   */
  public String getSeleNum()
  {
    return (String)getAttributeInternal(SELENUM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SeleNum
   */
  public void setSeleNum(String value)
  {
    setAttributeInternal(SELENUM, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute JotaiKbn1
   */
  public String getJotaiKbn1()
  {
    return (String)getAttributeInternal(JOTAIKBN1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute JotaiKbn1
   */
  public void setJotaiKbn1(String value)
  {
    setAttributeInternal(JOTAIKBN1, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute JotaiKbn2
   */
  public String getJotaiKbn2()
  {
    return (String)getAttributeInternal(JOTAIKBN2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute JotaiKbn2
   */
  public void setJotaiKbn2(String value)
  {
    setAttributeInternal(JOTAIKBN2, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute JotaiKbn3
   */
  public String getJotaiKbn3()
  {
    return (String)getAttributeInternal(JOTAIKBN3);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute JotaiKbn3
   */
  public void setJotaiKbn3(String value)
  {
    setAttributeInternal(JOTAIKBN3, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AccountNumber
   */
  public String getAccountNumber()
  {
    return (String)getAttributeInternal(ACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AccountNumber
   */
  public void setAccountNumber(String value)
  {
    setAttributeInternal(ACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PartyName
   */
  public String getPartyName()
  {
    return (String)getAttributeInternal(PARTYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PartyName
   */
  public void setPartyName(String value)
  {
    setAttributeInternal(PARTYNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute HikisakigaisyaCd
   */
  public String getHikisakigaisyaCd()
  {
    return (String)getAttributeInternal(HIKISAKIGAISYACD);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute HikisakigaisyaCd
   */
  public void setHikisakigaisyaCd(String value)
  {
    setAttributeInternal(HIKISAKIGAISYACD, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute HikisakijigyosyoCd
   */
  public String getHikisakijigyosyoCd()
  {
    return (String)getAttributeInternal(HIKISAKIJIGYOSYOCD);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute HikisakijigyosyoCd
   */
  public void setHikisakijigyosyoCd(String value)
  {
    setAttributeInternal(HIKISAKIJIGYOSYOCD, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorNumber
   */
  public String getVendorNumber()
  {
    return (String)getAttributeInternal(VENDORNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorNumber
   */
  public void setVendorNumber(String value)
  {
    setAttributeInternal(VENDORNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AnnualType
   */
  public String getAnnualType()
  {
    return (String)getAttributeInternal(ANNUALTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AnnualType
   */
  public void setAnnualType(String value)
  {
    setAttributeInternal(ANNUALTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MakerCode
   */
  public String getMakerCode()
  {
    return (String)getAttributeInternal(MAKERCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MakerCode
   */
  public void setMakerCode(String value)
  {
    setAttributeInternal(MAKERCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LeaseStartDate
   */
  public String getLeaseStartDate()
  {
    return (String)getAttributeInternal(LEASESTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeaseStartDate
   */
  public void setLeaseStartDate(String value)
  {
    setAttributeInternal(LEASESTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FirstCharge
   */
  public String getFirstCharge()
  {
    return (String)getAttributeInternal(FIRSTCHARGE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FirstCharge
   */
  public void setFirstCharge(String value)
  {
    setAttributeInternal(FIRSTCHARGE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SecondCharge
   */
  public String getSecondCharge()
  {
    return (String)getAttributeInternal(SECONDCHARGE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SecondCharge
   */
  public void setSecondCharge(String value)
  {
    setAttributeInternal(SECONDCHARGE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallDate
   */
  public String getInstallDate()
  {
    return (String)getAttributeInternal(INSTALLDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallDate
   */
  public void setInstallDate(String value)
  {
    setAttributeInternal(INSTALLDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAddress1
   */
  public String getInstallAddress1()
  {
    return (String)getAttributeInternal(INSTALLADDRESS1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAddress1
   */
  public void setInstallAddress1(String value)
  {
    setAttributeInternal(INSTALLADDRESS1, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAddress2
   */
  public String getInstallAddress2()
  {
    return (String)getAttributeInternal(INSTALLADDRESS2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAddress2
   */
  public void setInstallAddress2(String value)
  {
    setAttributeInternal(INSTALLADDRESS2, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallIndustryType
   */
  public String getInstallIndustryType()
  {
    return (String)getAttributeInternal(INSTALLINDUSTRYTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallIndustryType
   */
  public void setInstallIndustryType(String value)
  {
    setAttributeInternal(INSTALLINDUSTRYTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Width
   */
  public String getWidth()
  {
    return (String)getAttributeInternal(WIDTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Width
   */
  public void setWidth(String value)
  {
    setAttributeInternal(WIDTH, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Depth
   */
  public String getDepth()
  {
    return (String)getAttributeInternal(DEPTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Depth
   */
  public void setDepth(String value)
  {
    setAttributeInternal(DEPTH, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Height
   */
  public String getHeight()
  {
    return (String)getAttributeInternal(HEIGHT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Height
   */
  public void setHeight(String value)
  {
    setAttributeInternal(HEIGHT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractNumber
   */
  public String getContractNumber()
  {
    return (String)getAttributeInternal(CONTRACTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractNumber
   */
  public void setContractNumber(String value)
  {
    setAttributeInternal(CONTRACTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ResourceName
   */
  public String getResourceName()
  {
    return (String)getAttributeInternal(RESOURCENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ResourceName
   */
  public void setResourceName(String value)
  {
    setAttributeInternal(RESOURCENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CountNo
   */
  public String getCountNo()
  {
    return (String)getAttributeInternal(COUNTNO);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CountNo
   */
  public void setCountNo(String value)
  {
    setAttributeInternal(COUNTNO, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NyukoDt
   */
  public String getNyukoDt()
  {
    return (String)getAttributeInternal(NYUKODT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NyukoDt
   */
  public void setNyukoDt(String value)
  {
    setAttributeInternal(NYUKODT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Special1
   */
  public String getSpecial1()
  {
    return (String)getAttributeInternal(SPECIAL1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Special1
   */
  public void setSpecial1(String value)
  {
    setAttributeInternal(SPECIAL1, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Special2
   */
  public String getSpecial2()
  {
    return (String)getAttributeInternal(SPECIAL2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Special2
   */
  public void setSpecial2(String value)
  {
    setAttributeInternal(SPECIAL2, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Special3
   */
  public String getSpecial3()
  {
    return (String)getAttributeInternal(SPECIAL3);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Special3
   */
  public void setSpecial3(String value)
  {
    setAttributeInternal(SPECIAL3, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ChikuCd
   */
  public String getChikuCd()
  {
    return (String)getAttributeInternal(CHIKUCD);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ChikuCd
   */
  public void setChikuCd(String value)
  {
    setAttributeInternal(CHIKUCD, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SyoyuCd
   */
  public String getSyoyuCd()
  {
    return (String)getAttributeInternal(SYOYUCD);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SyoyuCd
   */
  public void setSyoyuCd(String value)
  {
    setAttributeInternal(SYOYUCD, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OrigLeaseContractNumber
   */
  public String getOrigLeaseContractNumber()
  {
    return (String)getAttributeInternal(ORIGLEASECONTRACTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OrigLeaseContractNumber
   */
  public void setOrigLeaseContractNumber(String value)
  {
    setAttributeInternal(ORIGLEASECONTRACTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OrigLeaseBranchNumber
   */
  public String getOrigLeaseBranchNumber()
  {
    return (String)getAttributeInternal(ORIGLEASEBRANCHNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OrigLeaseBranchNumber
   */
  public void setOrigLeaseBranchNumber(String value)
  {
    setAttributeInternal(ORIGLEASEBRANCHNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LeaseContractDate
   */
  public String getLeaseContractDate()
  {
    return (String)getAttributeInternal(LEASECONTRACTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeaseContractDate
   */
  public void setLeaseContractDate(String value)
  {
    setAttributeInternal(LEASECONTRACTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LeaseContractNumber
   */
  public String getLeaseContractNumber()
  {
    return (String)getAttributeInternal(LEASECONTRACTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeaseContractNumber
   */
  public void setLeaseContractNumber(String value)
  {
    setAttributeInternal(LEASECONTRACTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LeaseBranchNumber
   */
  public String getLeaseBranchNumber()
  {
    return (String)getAttributeInternal(LEASEBRANCHNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeaseBranchNumber
   */
  public void setLeaseBranchNumber(String value)
  {
    setAttributeInternal(LEASEBRANCHNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PartyNamePhonetic
   */
  public String getPartyNamePhonetic()
  {
    return (String)getAttributeInternal(PARTYNAMEPHONETIC);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PartyNamePhonetic
   */
  public void setPartyNamePhonetic(String value)
  {
    setAttributeInternal(PARTYNAMEPHONETIC, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VenTasyaCd01
   */
  public String getVenTasyaCd01()
  {
    return (String)getAttributeInternal(VENTASYACD01);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VenTasyaCd01
   */
  public void setVenTasyaCd01(String value)
  {
    setAttributeInternal(VENTASYACD01, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VenTasyaDaisu01
   */
  public String getVenTasyaDaisu01()
  {
    return (String)getAttributeInternal(VENTASYADAISU01);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VenTasyaDaisu01
   */
  public void setVenTasyaDaisu01(String value)
  {
    setAttributeInternal(VENTASYADAISU01, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VenTasyaCd02
   */
  public String getVenTasyaCd02()
  {
    return (String)getAttributeInternal(VENTASYACD02);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VenTasyaCd02
   */
  public void setVenTasyaCd02(String value)
  {
    setAttributeInternal(VENTASYACD02, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VenTasyaDaisu02
   */
  public String getVenTasyaDaisu02()
  {
    return (String)getAttributeInternal(VENTASYADAISU02);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VenTasyaDaisu02
   */
  public void setVenTasyaDaisu02(String value)
  {
    setAttributeInternal(VENTASYADAISU02, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VenTasyaCd03
   */
  public String getVenTasyaCd03()
  {
    return (String)getAttributeInternal(VENTASYACD03);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VenTasyaCd03
   */
  public void setVenTasyaCd03(String value)
  {
    setAttributeInternal(VENTASYACD03, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VenTasyaDaisu03
   */
  public String getVenTasyaDaisu03()
  {
    return (String)getAttributeInternal(VENTASYADAISU03);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VenTasyaDaisu03
   */
  public void setVenTasyaDaisu03(String value)
  {
    setAttributeInternal(VENTASYADAISU03, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VenTasyaCd04
   */
  public String getVenTasyaCd04()
  {
    return (String)getAttributeInternal(VENTASYACD04);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VenTasyaCd04
   */
  public void setVenTasyaCd04(String value)
  {
    setAttributeInternal(VENTASYACD04, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VenTasyaDaisu04
   */
  public String getVenTasyaDaisu04()
  {
    return (String)getAttributeInternal(VENTASYADAISU04);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VenTasyaDaisu04
   */
  public void setVenTasyaDaisu04(String value)
  {
    setAttributeInternal(VENTASYADAISU04, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VenTasyaCd05
   */
  public String getVenTasyaCd05()
  {
    return (String)getAttributeInternal(VENTASYACD05);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VenTasyaCd05
   */
  public void setVenTasyaCd05(String value)
  {
    setAttributeInternal(VENTASYACD05, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VenTasyaDaisu05
   */
  public String getVenTasyaDaisu05()
  {
    return (String)getAttributeInternal(VENTASYADAISU05);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VenTasyaDaisu05
   */
  public void setVenTasyaDaisu05(String value)
  {
    setAttributeInternal(VENTASYADAISU05, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LeaseStatus
   */
  public String getLeaseStatus()
  {
    return (String)getAttributeInternal(LEASESTATUS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeaseStatus
   */
  public void setLeaseStatus(String value)
  {
    setAttributeInternal(LEASESTATUS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PaymentFrequency
   */
  public String getPaymentFrequency()
  {
    return (String)getAttributeInternal(PAYMENTFREQUENCY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PaymentFrequency
   */
  public void setPaymentFrequency(String value)
  {
    setAttributeInternal(PAYMENTFREQUENCY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LeaseEndDate
   */
  public String getLeaseEndDate()
  {
    return (String)getAttributeInternal(LEASEENDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeaseEndDate
   */
  public void setLeaseEndDate(String value)
  {
    setAttributeInternal(LEASEENDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpDecisionNumber
   */
  public String getSpDecisionNumber()
  {
    return (String)getAttributeInternal(SPDECISIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpDecisionNumber
   */
  public void setSpDecisionNumber(String value)
  {
    setAttributeInternal(SPDECISIONNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallLocation
   */
  public String getInstallLocation()
  {
    return (String)getAttributeInternal(INSTALLLOCATION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallLocation
   */
  public void setInstallLocation(String value)
  {
    setAttributeInternal(INSTALLLOCATION, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorForm
   */
  public String getVendorForm()
  {
    return (String)getAttributeInternal(VENDORFORM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorForm
   */
  public void setVendorForm(String value)
  {
    setAttributeInternal(VENDORFORM, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LastPartyName
   */
  public String getLastPartyName()
  {
    return (String)getAttributeInternal(LASTPARTYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LastPartyName
   */
  public void setLastPartyName(String value)
  {
    setAttributeInternal(LASTPARTYNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LastAccountCode
   */
  public String getLastAccountCode()
  {
    return (String)getAttributeInternal(LASTACCOUNTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LastAccountCode
   */
  public void setLastAccountCode(String value)
  {
    setAttributeInternal(LASTACCOUNTCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LastInstallPlaceName
   */
  public String getLastInstallPlaceName()
  {
    return (String)getAttributeInternal(LASTINSTALLPLACENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LastInstallPlaceName
   */
  public void setLastInstallPlaceName(String value)
  {
    setAttributeInternal(LASTINSTALLPLACENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute JobKbn2
   */
  public String getJobKbn2()
  {
    return (String)getAttributeInternal(JOBKBN2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute JobKbn2
   */
  public void setJobKbn2(String value)
  {
    setAttributeInternal(JOBKBN2, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SintyokuKbn2
   */
  public String getSintyokuKbn2()
  {
    return (String)getAttributeInternal(SINTYOKUKBN2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SintyokuKbn2
   */
  public void setSintyokuKbn2(String value)
  {
    setAttributeInternal(SINTYOKUKBN2, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SagyoLevel
   */
  public String getSagyoLevel()
  {
    return (String)getAttributeInternal(SAGYOLEVEL);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SagyoLevel
   */
  public void setSagyoLevel(String value)
  {
    setAttributeInternal(SAGYOLEVEL, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SagyougaisyaCd
   */
  public String getSagyougaisyaCd()
  {
    return (String)getAttributeInternal(SAGYOUGAISYACD);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SagyougaisyaCd
   */
  public void setSagyougaisyaCd(String value)
  {
    setAttributeInternal(SAGYOUGAISYACD, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute JigyosyoCd
   */
  public String getJigyosyoCd()
  {
    return (String)getAttributeInternal(JIGYOSYOCD);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute JigyosyoCd
   */
  public void setJigyosyoCd(String value)
  {
    setAttributeInternal(JIGYOSYOCD, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DenNo
   */
  public String getDenNo()
  {
    return (String)getAttributeInternal(DENNO);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DenNo
   */
  public void setDenNo(String value)
  {
    setAttributeInternal(DENNO, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute JobKbn
   */
  public String getJobKbn()
  {
    return (String)getAttributeInternal(JOBKBN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute JobKbn
   */
  public void setJobKbn(String value)
  {
    setAttributeInternal(JOBKBN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SintyokuKbn
   */
  public String getSintyokuKbn()
  {
    return (String)getAttributeInternal(SINTYOKUKBN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SintyokuKbn
   */
  public void setSintyokuKbn(String value)
  {
    setAttributeInternal(SINTYOKUKBN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute YoteiDt
   */
  public String getYoteiDt()
  {
    return (String)getAttributeInternal(YOTEIDT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute YoteiDt
   */
  public void setYoteiDt(String value)
  {
    setAttributeInternal(YOTEIDT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DenNo2
   */
  public String getDenNo2()
  {
    return (String)getAttributeInternal(DENNO2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DenNo2
   */
  public void setDenNo2(String value)
  {
    setAttributeInternal(DENNO2, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute HaikikessaiDt
   */
  public String getHaikikessaiDt()
  {
    return (String)getAttributeInternal(HAIKIKESSAIDT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute HaikikessaiDt
   */
  public void setHaikikessaiDt(String value)
  {
    setAttributeInternal(HAIKIKESSAIDT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TenhaiTanto
   */
  public String getTenhaiTanto()
  {
    return (String)getAttributeInternal(TENHAITANTO);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TenhaiTanto
   */
  public void setTenhaiTanto(String value)
  {
    setAttributeInternal(TENHAITANTO, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TenhaiDenNo
   */
  public String getTenhaiDenNo()
  {
    return (String)getAttributeInternal(TENHAIDENNO);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TenhaiDenNo
   */
  public void setTenhaiDenNo(String value)
  {
    setAttributeInternal(TENHAIDENNO, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TenhaiFlg
   */
  public String getTenhaiFlg()
  {
    return (String)getAttributeInternal(TENHAIFLG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TenhaiFlg
   */
  public void setTenhaiFlg(String value)
  {
    setAttributeInternal(TENHAIFLG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute KanryoKbn
   */
  public String getKanryoKbn()
  {
    return (String)getAttributeInternal(KANRYOKBN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute KanryoKbn
   */
  public void setKanryoKbn(String value)
  {
    setAttributeInternal(KANRYOKBN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PurchaseAmount
   */
  public String getPurchaseAmount()
  {
    return (String)getAttributeInternal(PURCHASEAMOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PurchaseAmount
   */
  public void setPurchaseAmount(String value)
  {
    setAttributeInternal(PURCHASEAMOUNT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CancellationDate
   */
  public String getCancellationDate()
  {
    return (String)getAttributeInternal(CANCELLATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CancellationDate
   */
  public void setCancellationDate(String value)
  {
    setAttributeInternal(CANCELLATIONDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MakerName
   */
  public String getMakerName()
  {
    return (String)getAttributeInternal(MAKERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MakerName
   */
  public void setMakerName(String value)
  {
    setAttributeInternal(MAKERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SafetyLevel
   */
  public String getSafetyLevel()
  {
    return (String)getAttributeInternal(SAFETYLEVEL);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SafetyLevel
   */
  public void setSafetyLevel(String value)
  {
    setAttributeInternal(SAFETYLEVEL, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DeptCode
   */
  public String getDeptCode()
  {
    return (String)getAttributeInternal(DEPTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DeptCode
   */
  public void setDeptCode(String value)
  {
    setAttributeInternal(DEPTCODE, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute InstanceTypeCode
   */
  public String getInstanceTypeCode()
  {
    return (String)getAttributeInternal(INSTANCETYPECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstanceTypeCode
   */
  public void setInstanceTypeCode(String value)
  {
    setAttributeInternal(INSTANCETYPECODE, value);
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute InstallCode
   */
  public String getInstallCode()
  {
    return (String)getAttributeInternal(INSTALLCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallCode
   */
  public void setInstallCode(String value)
  {
    setAttributeInternal(INSTALLCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAccountId
   */
  public String getInstallAccountId()
  {
    return (String)getAttributeInternal(INSTALLACCOUNTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAccountId
   */
  public void setInstallAccountId(String value)
  {
    setAttributeInternal(INSTALLACCOUNTID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OpRequestFlag
   */
  public String getOpRequestFlag()
  {
    return (String)getAttributeInternal(OPREQUESTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OpRequestFlag
   */
  public void setOpRequestFlag(String value)
  {
    setAttributeInternal(OPREQUESTFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstanceId
   */
  public Number getInstanceId()
  {
    return (Number)getAttributeInternal(INSTANCEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstanceId
   */
  public void setInstanceId(Number value)
  {
    setAttributeInternal(INSTANCEID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallPartyId
   */
  public Number getInstallPartyId()
  {
    return (Number)getAttributeInternal(INSTALLPARTYID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallPartyId
   */
  public void setInstallPartyId(Number value)
  {
    setAttributeInternal(INSTALLPARTYID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OpReqNumberAccountNumber
   */
  public String getOpReqNumberAccountNumber()
  {
    return (String)getAttributeInternal(OPREQNUMBERACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OpReqNumberAccountNumber
   */
  public void setOpReqNumberAccountNumber(String value)
  {
    setAttributeInternal(OPREQNUMBERACCOUNTNUMBER, value);
  }
}