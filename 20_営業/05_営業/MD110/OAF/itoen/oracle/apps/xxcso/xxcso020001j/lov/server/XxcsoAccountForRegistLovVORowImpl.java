/*============================================================================
* ファイル名 : XxcsoAccountForRegistLovVORowImpl
* 概要説明   : 顧客コード（登録用）LOV用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-18 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 顧客コード（登録用）のLOVのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAccountForRegistLovVORowImpl extends OAViewRowImpl 
{


  protected static final int APPLICATIONTYPE = 0;
  protected static final int CUSTACCOUNTID = 1;
  protected static final int ACCOUNTNUMBER = 2;
  protected static final int PARTYNAME = 3;
  protected static final int ORGANIZATIONNAMEPHONETIC = 4;
  protected static final int ESTABLISHEDSITENAME = 5;
  protected static final int POSTALCODEFIRST = 6;
  protected static final int POSTALCODESECOND = 7;
  protected static final int POSTALCODE = 8;
  protected static final int STATE = 9;
  protected static final int CITY = 10;
  protected static final int ADDRESS1 = 11;
  protected static final int ADDRESS2 = 12;
  protected static final int PHONENUMBER = 13;
  protected static final int BUSINESSLOWTYPE = 14;
  protected static final int INDUSTRYDIV = 15;
  protected static final int ESTABLISHMENTLOCATION = 16;
  protected static final int OPENCLOSEDIV = 17;
  protected static final int EMPLOYEES = 18;
  protected static final int SALEBASECODE = 19;
  protected static final int SALEBASENAME = 20;
  protected static final int CUSTOMERSTATUS = 21;
  protected static final int UPDATECUSTENABLE = 22;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAccountForRegistLovVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApplicationType
   */
  public String getApplicationType()
  {
    return (String)getAttributeInternal(APPLICATIONTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApplicationType
   */
  public void setApplicationType(String value)
  {
    setAttributeInternal(APPLICATIONTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CustAccountId
   */
  public Number getCustAccountId()
  {
    return (Number)getAttributeInternal(CUSTACCOUNTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustAccountId
   */
  public void setCustAccountId(Number value)
  {
    setAttributeInternal(CUSTACCOUNTID, value);
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
   * Gets the attribute value for the calculated attribute OrganizationNamePhonetic
   */
  public String getOrganizationNamePhonetic()
  {
    return (String)getAttributeInternal(ORGANIZATIONNAMEPHONETIC);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OrganizationNamePhonetic
   */
  public void setOrganizationNamePhonetic(String value)
  {
    setAttributeInternal(ORGANIZATIONNAMEPHONETIC, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EstablishedSiteName
   */
  public String getEstablishedSiteName()
  {
    return (String)getAttributeInternal(ESTABLISHEDSITENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EstablishedSiteName
   */
  public void setEstablishedSiteName(String value)
  {
    setAttributeInternal(ESTABLISHEDSITENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PostalCodeFirst
   */
  public String getPostalCodeFirst()
  {
    return (String)getAttributeInternal(POSTALCODEFIRST);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PostalCodeFirst
   */
  public void setPostalCodeFirst(String value)
  {
    setAttributeInternal(POSTALCODEFIRST, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PostalCodeSecond
   */
  public String getPostalCodeSecond()
  {
    return (String)getAttributeInternal(POSTALCODESECOND);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PostalCodeSecond
   */
  public void setPostalCodeSecond(String value)
  {
    setAttributeInternal(POSTALCODESECOND, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PostalCode
   */
  public String getPostalCode()
  {
    return (String)getAttributeInternal(POSTALCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PostalCode
   */
  public void setPostalCode(String value)
  {
    setAttributeInternal(POSTALCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute State
   */
  public String getState()
  {
    return (String)getAttributeInternal(STATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute State
   */
  public void setState(String value)
  {
    setAttributeInternal(STATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute City
   */
  public String getCity()
  {
    return (String)getAttributeInternal(CITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute City
   */
  public void setCity(String value)
  {
    setAttributeInternal(CITY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Address1
   */
  public String getAddress1()
  {
    return (String)getAttributeInternal(ADDRESS1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Address1
   */
  public void setAddress1(String value)
  {
    setAttributeInternal(ADDRESS1, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Address2
   */
  public String getAddress2()
  {
    return (String)getAttributeInternal(ADDRESS2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Address2
   */
  public void setAddress2(String value)
  {
    setAttributeInternal(ADDRESS2, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PhoneNumber
   */
  public String getPhoneNumber()
  {
    return (String)getAttributeInternal(PHONENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PhoneNumber
   */
  public void setPhoneNumber(String value)
  {
    setAttributeInternal(PHONENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BusinessLowType
   */
  public String getBusinessLowType()
  {
    return (String)getAttributeInternal(BUSINESSLOWTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BusinessLowType
   */
  public void setBusinessLowType(String value)
  {
    setAttributeInternal(BUSINESSLOWTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IndustryDiv
   */
  public String getIndustryDiv()
  {
    return (String)getAttributeInternal(INDUSTRYDIV);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IndustryDiv
   */
  public void setIndustryDiv(String value)
  {
    setAttributeInternal(INDUSTRYDIV, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EstablishmentLocation
   */
  public String getEstablishmentLocation()
  {
    return (String)getAttributeInternal(ESTABLISHMENTLOCATION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EstablishmentLocation
   */
  public void setEstablishmentLocation(String value)
  {
    setAttributeInternal(ESTABLISHMENTLOCATION, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OpenCloseDiv
   */
  public String getOpenCloseDiv()
  {
    return (String)getAttributeInternal(OPENCLOSEDIV);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OpenCloseDiv
   */
  public void setOpenCloseDiv(String value)
  {
    setAttributeInternal(OPENCLOSEDIV, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Employees
   */
  public String getEmployees()
  {
    return (String)getAttributeInternal(EMPLOYEES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Employees
   */
  public void setEmployees(String value)
  {
    setAttributeInternal(EMPLOYEES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SaleBaseCode
   */
  public String getSaleBaseCode()
  {
    return (String)getAttributeInternal(SALEBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SaleBaseCode
   */
  public void setSaleBaseCode(String value)
  {
    setAttributeInternal(SALEBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SaleBaseName
   */
  public String getSaleBaseName()
  {
    return (String)getAttributeInternal(SALEBASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SaleBaseName
   */
  public void setSaleBaseName(String value)
  {
    setAttributeInternal(SALEBASENAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case APPLICATIONTYPE:
        return getApplicationType();
      case CUSTACCOUNTID:
        return getCustAccountId();
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case PARTYNAME:
        return getPartyName();
      case ORGANIZATIONNAMEPHONETIC:
        return getOrganizationNamePhonetic();
      case ESTABLISHEDSITENAME:
        return getEstablishedSiteName();
      case POSTALCODEFIRST:
        return getPostalCodeFirst();
      case POSTALCODESECOND:
        return getPostalCodeSecond();
      case POSTALCODE:
        return getPostalCode();
      case STATE:
        return getState();
      case CITY:
        return getCity();
      case ADDRESS1:
        return getAddress1();
      case ADDRESS2:
        return getAddress2();
      case PHONENUMBER:
        return getPhoneNumber();
      case BUSINESSLOWTYPE:
        return getBusinessLowType();
      case INDUSTRYDIV:
        return getIndustryDiv();
      case ESTABLISHMENTLOCATION:
        return getEstablishmentLocation();
      case OPENCLOSEDIV:
        return getOpenCloseDiv();
      case EMPLOYEES:
        return getEmployees();
      case SALEBASECODE:
        return getSaleBaseCode();
      case SALEBASENAME:
        return getSaleBaseName();
      case CUSTOMERSTATUS:
        return getCustomerStatus();
      case UPDATECUSTENABLE:
        return getUpdateCustEnable();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case APPLICATIONTYPE:
        setApplicationType((String)value);
        return;
      case CUSTACCOUNTID:
        setCustAccountId((Number)value);
        return;
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
        return;
      case ORGANIZATIONNAMEPHONETIC:
        setOrganizationNamePhonetic((String)value);
        return;
      case ESTABLISHEDSITENAME:
        setEstablishedSiteName((String)value);
        return;
      case POSTALCODEFIRST:
        setPostalCodeFirst((String)value);
        return;
      case POSTALCODESECOND:
        setPostalCodeSecond((String)value);
        return;
      case POSTALCODE:
        setPostalCode((String)value);
        return;
      case STATE:
        setState((String)value);
        return;
      case CITY:
        setCity((String)value);
        return;
      case ADDRESS1:
        setAddress1((String)value);
        return;
      case ADDRESS2:
        setAddress2((String)value);
        return;
      case PHONENUMBER:
        setPhoneNumber((String)value);
        return;
      case BUSINESSLOWTYPE:
        setBusinessLowType((String)value);
        return;
      case INDUSTRYDIV:
        setIndustryDiv((String)value);
        return;
      case ESTABLISHMENTLOCATION:
        setEstablishmentLocation((String)value);
        return;
      case OPENCLOSEDIV:
        setOpenCloseDiv((String)value);
        return;
      case EMPLOYEES:
        setEmployees((String)value);
        return;
      case SALEBASECODE:
        setSaleBaseCode((String)value);
        return;
      case SALEBASENAME:
        setSaleBaseName((String)value);
        return;
      case CUSTOMERSTATUS:
        setCustomerStatus((String)value);
        return;
      case UPDATECUSTENABLE:
        setUpdateCustEnable((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CustomerStatus
   */
  public String getCustomerStatus()
  {
    return (String)getAttributeInternal(CUSTOMERSTATUS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustomerStatus
   */
  public void setCustomerStatus(String value)
  {
    setAttributeInternal(CUSTOMERSTATUS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UpdateCustEnable
   */
  public String getUpdateCustEnable()
  {
    return (String)getAttributeInternal(UPDATECUSTENABLE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UpdateCustEnable
   */
  public void setUpdateCustEnable(String value)
  {
    setAttributeInternal(UPDATECUSTENABLE, value);
  }
}