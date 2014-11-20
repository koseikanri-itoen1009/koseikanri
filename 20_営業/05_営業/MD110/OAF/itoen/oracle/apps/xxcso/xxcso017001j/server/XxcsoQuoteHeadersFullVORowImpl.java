/*============================================================================
* ファイル名 : XxcsoQuoteHeadersFullVORowImpl
* 概要説明   : 見積ヘッダー登録／更新用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-15 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
/*******************************************************************************
 * 見積ヘッダー情報を登録／更新するためのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteHeadersFullVORowImpl extends OAViewRowImpl 
{


  protected static final int QUOTEHEADERID = 0;
  protected static final int QUOTETYPE = 1;
  protected static final int QUOTENUMBER = 2;
  protected static final int QUOTEREVISIONNUMBER = 3;
  protected static final int REFERENCEQUOTENUMBER = 4;
  protected static final int REFERENCEQUOTEHEADERID = 5;
  protected static final int PUBLISHDATE = 6;
  protected static final int ACCOUNTNUMBER = 7;
  protected static final int EMPLOYEENUMBER = 8;
  protected static final int BASECODE = 9;
  protected static final int DELIVPLACE = 10;
  protected static final int PAYMENTCONDITION = 11;
  protected static final int QUOTESUBMITNAME = 12;
  protected static final int STATUS = 13;
  protected static final int DELIVPRICETAXTYPE = 14;
  protected static final int STOREPRICETAXTYPE = 15;
  protected static final int UNITTYPE = 16;
  protected static final int SPECIALNOTE = 17;
  protected static final int QUOTEINFOSTARTDATE = 18;
  protected static final int QUOTEINFOENDDATE = 19;
  protected static final int CREATEDBY = 20;
  protected static final int CREATIONDATE = 21;
  protected static final int LASTUPDATEDBY = 22;
  protected static final int LASTUPDATEDATE = 23;
  protected static final int LASTUPDATELOGIN = 24;
  protected static final int REQUESTID = 25;
  protected static final int PROGRAMAPPLICATIONID = 26;
  protected static final int PROGRAMID = 27;
  protected static final int PROGRAMUPDATEDATE = 28;
  protected static final int PARTYNAME = 29;
  protected static final int FULLNAME = 30;
  protected static final int BASENAME = 31;
  protected static final int XXCSOQUOTELINESSALESFULLVO = 32;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteHeadersFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoQuoteHeadersEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoQuoteHeadersEOImpl getXxcsoQuoteHeadersEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoQuoteHeadersEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for QUOTE_HEADER_ID using the alias name QuoteHeaderId
   */
  public Number getQuoteHeaderId()
  {
    return (Number)getAttributeInternal(QUOTEHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for QUOTE_HEADER_ID using the alias name QuoteHeaderId
   */
  public void setQuoteHeaderId(Number value)
  {
    setAttributeInternal(QUOTEHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for QUOTE_TYPE using the alias name QuoteType
   */
  public String getQuoteType()
  {
    return (String)getAttributeInternal(QUOTETYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for QUOTE_TYPE using the alias name QuoteType
   */
  public void setQuoteType(String value)
  {
    setAttributeInternal(QUOTETYPE, value);
  }

  /**
   * 
   * Gets the attribute value for QUOTE_NUMBER using the alias name QuoteNumber
   */
  public String getQuoteNumber()
  {
    return (String)getAttributeInternal(QUOTENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for QUOTE_NUMBER using the alias name QuoteNumber
   */
  public void setQuoteNumber(String value)
  {
    setAttributeInternal(QUOTENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for QUOTE_REVISION_NUMBER using the alias name QuoteRevisionNumber
   */
  public Number getQuoteRevisionNumber()
  {
    return (Number)getAttributeInternal(QUOTEREVISIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for QUOTE_REVISION_NUMBER using the alias name QuoteRevisionNumber
   */
  public void setQuoteRevisionNumber(Number value)
  {
    setAttributeInternal(QUOTEREVISIONNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for REFERENCE_QUOTE_NUMBER using the alias name ReferenceQuoteNumber
   */
  public String getReferenceQuoteNumber()
  {
    return (String)getAttributeInternal(REFERENCEQUOTENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for REFERENCE_QUOTE_NUMBER using the alias name ReferenceQuoteNumber
   */
  public void setReferenceQuoteNumber(String value)
  {
    setAttributeInternal(REFERENCEQUOTENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for REFERENCE_QUOTE_HEADER_ID using the alias name ReferenceQuoteHeaderId
   */
  public Number getReferenceQuoteHeaderId()
  {
    return (Number)getAttributeInternal(REFERENCEQUOTEHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for REFERENCE_QUOTE_HEADER_ID using the alias name ReferenceQuoteHeaderId
   */
  public void setReferenceQuoteHeaderId(Number value)
  {
    setAttributeInternal(REFERENCEQUOTEHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for PUBLISH_DATE using the alias name PublishDate
   */
  public Date getPublishDate()
  {
    return (Date)getAttributeInternal(PUBLISHDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PUBLISH_DATE using the alias name PublishDate
   */
  public void setPublishDate(Date value)
  {
    setAttributeInternal(PUBLISHDATE, value);
  }

  /**
   * 
   * Gets the attribute value for ACCOUNT_NUMBER using the alias name AccountNumber
   */
  public String getAccountNumber()
  {
    return (String)getAttributeInternal(ACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ACCOUNT_NUMBER using the alias name AccountNumber
   */
  public void setAccountNumber(String value)
  {
    setAttributeInternal(ACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for EMPLOYEE_NUMBER using the alias name EmployeeNumber
   */
  public String getEmployeeNumber()
  {
    return (String)getAttributeInternal(EMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for EMPLOYEE_NUMBER using the alias name EmployeeNumber
   */
  public void setEmployeeNumber(String value)
  {
    setAttributeInternal(EMPLOYEENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for BASE_CODE using the alias name BaseCode
   */
  public String getBaseCode()
  {
    return (String)getAttributeInternal(BASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BASE_CODE using the alias name BaseCode
   */
  public void setBaseCode(String value)
  {
    setAttributeInternal(BASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for DELIV_PLACE using the alias name DelivPlace
   */
  public String getDelivPlace()
  {
    return (String)getAttributeInternal(DELIVPLACE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for DELIV_PLACE using the alias name DelivPlace
   */
  public void setDelivPlace(String value)
  {
    setAttributeInternal(DELIVPLACE, value);
  }

  /**
   * 
   * Gets the attribute value for PAYMENT_CONDITION using the alias name PaymentCondition
   */
  public String getPaymentCondition()
  {
    return (String)getAttributeInternal(PAYMENTCONDITION);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PAYMENT_CONDITION using the alias name PaymentCondition
   */
  public void setPaymentCondition(String value)
  {
    setAttributeInternal(PAYMENTCONDITION, value);
  }

  /**
   * 
   * Gets the attribute value for QUOTE_SUBMIT_NAME using the alias name QuoteSubmitName
   */
  public String getQuoteSubmitName()
  {
    return (String)getAttributeInternal(QUOTESUBMITNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for QUOTE_SUBMIT_NAME using the alias name QuoteSubmitName
   */
  public void setQuoteSubmitName(String value)
  {
    setAttributeInternal(QUOTESUBMITNAME, value);
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
   * Gets the attribute value for DELIV_PRICE_TAX_TYPE using the alias name DelivPriceTaxType
   */
  public String getDelivPriceTaxType()
  {
    return (String)getAttributeInternal(DELIVPRICETAXTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for DELIV_PRICE_TAX_TYPE using the alias name DelivPriceTaxType
   */
  public void setDelivPriceTaxType(String value)
  {
    setAttributeInternal(DELIVPRICETAXTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for STORE_PRICE_TAX_TYPE using the alias name StorePriceTaxType
   */
  public String getStorePriceTaxType()
  {
    return (String)getAttributeInternal(STOREPRICETAXTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for STORE_PRICE_TAX_TYPE using the alias name StorePriceTaxType
   */
  public void setStorePriceTaxType(String value)
  {
    setAttributeInternal(STOREPRICETAXTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for UNIT_TYPE using the alias name UnitType
   */
  public String getUnitType()
  {
    return (String)getAttributeInternal(UNITTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for UNIT_TYPE using the alias name UnitType
   */
  public void setUnitType(String value)
  {
    setAttributeInternal(UNITTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for SPECIAL_NOTE using the alias name SpecialNote
   */
  public String getSpecialNote()
  {
    return (String)getAttributeInternal(SPECIALNOTE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SPECIAL_NOTE using the alias name SpecialNote
   */
  public void setSpecialNote(String value)
  {
    setAttributeInternal(SPECIALNOTE, value);
  }

  /**
   * 
   * Gets the attribute value for QUOTE_INFO_START_DATE using the alias name QuoteInfoStartDate
   */
  public Date getQuoteInfoStartDate()
  {
    return (Date)getAttributeInternal(QUOTEINFOSTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for QUOTE_INFO_START_DATE using the alias name QuoteInfoStartDate
   */
  public void setQuoteInfoStartDate(Date value)
  {
    setAttributeInternal(QUOTEINFOSTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for QUOTE_INFO_END_DATE using the alias name QuoteInfoEndDate
   */
  public Date getQuoteInfoEndDate()
  {
    return (Date)getAttributeInternal(QUOTEINFOENDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for QUOTE_INFO_END_DATE using the alias name QuoteInfoEndDate
   */
  public void setQuoteInfoEndDate(Date value)
  {
    setAttributeInternal(QUOTEINFOENDDATE, value);
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


  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTEHEADERID:
        return getQuoteHeaderId();
      case QUOTETYPE:
        return getQuoteType();
      case QUOTENUMBER:
        return getQuoteNumber();
      case QUOTEREVISIONNUMBER:
        return getQuoteRevisionNumber();
      case REFERENCEQUOTENUMBER:
        return getReferenceQuoteNumber();
      case REFERENCEQUOTEHEADERID:
        return getReferenceQuoteHeaderId();
      case PUBLISHDATE:
        return getPublishDate();
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case BASECODE:
        return getBaseCode();
      case DELIVPLACE:
        return getDelivPlace();
      case PAYMENTCONDITION:
        return getPaymentCondition();
      case QUOTESUBMITNAME:
        return getQuoteSubmitName();
      case STATUS:
        return getStatus();
      case DELIVPRICETAXTYPE:
        return getDelivPriceTaxType();
      case STOREPRICETAXTYPE:
        return getStorePriceTaxType();
      case UNITTYPE:
        return getUnitType();
      case SPECIALNOTE:
        return getSpecialNote();
      case QUOTEINFOSTARTDATE:
        return getQuoteInfoStartDate();
      case QUOTEINFOENDDATE:
        return getQuoteInfoEndDate();
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
      case PARTYNAME:
        return getPartyName();
      case FULLNAME:
        return getFullName();
      case BASENAME:
        return getBaseName();
      case XXCSOQUOTELINESSALESFULLVO:
        return getXxcsoQuoteLinesSalesFullVO();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTEHEADERID:
        setQuoteHeaderId((Number)value);
        return;
      case QUOTETYPE:
        setQuoteType((String)value);
        return;
      case QUOTENUMBER:
        setQuoteNumber((String)value);
        return;
      case QUOTEREVISIONNUMBER:
        setQuoteRevisionNumber((Number)value);
        return;
      case REFERENCEQUOTENUMBER:
        setReferenceQuoteNumber((String)value);
        return;
      case REFERENCEQUOTEHEADERID:
        setReferenceQuoteHeaderId((Number)value);
        return;
      case PUBLISHDATE:
        setPublishDate((Date)value);
        return;
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case BASECODE:
        setBaseCode((String)value);
        return;
      case DELIVPLACE:
        setDelivPlace((String)value);
        return;
      case PAYMENTCONDITION:
        setPaymentCondition((String)value);
        return;
      case QUOTESUBMITNAME:
        setQuoteSubmitName((String)value);
        return;
      case STATUS:
        setStatus((String)value);
        return;
      case DELIVPRICETAXTYPE:
        setDelivPriceTaxType((String)value);
        return;
      case STOREPRICETAXTYPE:
        setStorePriceTaxType((String)value);
        return;
      case UNITTYPE:
        setUnitType((String)value);
        return;
      case SPECIALNOTE:
        setSpecialNote((String)value);
        return;
      case QUOTEINFOSTARTDATE:
        setQuoteInfoStartDate((Date)value);
        return;
      case QUOTEINFOENDDATE:
        setQuoteInfoEndDate((Date)value);
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
      case PARTYNAME:
        setPartyName((String)value);
        return;
      case FULLNAME:
        setFullName((String)value);
        return;
      case BASENAME:
        setBaseName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoQuoteLinesSalesFullVO
   */
  public oracle.jbo.RowIterator getXxcsoQuoteLinesSalesFullVO()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOQUOTELINESSALESFULLVO);
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







}