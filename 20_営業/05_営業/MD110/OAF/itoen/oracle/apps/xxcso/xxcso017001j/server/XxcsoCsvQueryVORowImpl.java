/*============================================================================
* ファイル名 : XxcsoCsvQueryVOImpl
* 概要説明   : 販売先用見積CSV出力Query格納用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-20 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * CSV出力Query格納用ビュー行クラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoCsvQueryVORowImpl extends OAViewRowImpl 
{






  protected static final int QUOTETYPE = 0;
  protected static final int QUOTENUMBER = 1;
  protected static final int QUOTEREVISIONNUMBER = 2;
  protected static final int PUBLISHDATE = 3;
  protected static final int ACCOUNTNUMBER = 4;
  protected static final int PARTYNAME = 5;
  protected static final int EMPLOYEENUMBER = 6;
  protected static final int FULLNAME = 7;
  protected static final int BASECODE = 8;
  protected static final int BASENAME = 9;
  protected static final int DELIVPLACE = 10;
  protected static final int PAYMENTCONDITION = 11;
  protected static final int QUOTEINFOSTARTDATE = 12;
  protected static final int QUOTEINFOENDDATE = 13;
  protected static final int QUOTESUBMITNAME = 14;
  protected static final int DELIVPRICETAXTYPE = 15;
  protected static final int STOREPRICETAXTYPE = 16;
  protected static final int UNITTYPE = 17;
  protected static final int STATUS = 18;
  protected static final int SPECIALNOTE = 19;
  protected static final int INVENTORYITEMCODE = 20;
  protected static final int ITEMSHORTNAME = 21;
  protected static final int QUOTEDIV = 22;
  protected static final int USUALLYDELIVPRICE = 23;
  protected static final int USUALLYSTORESALEPRICE = 24;
  protected static final int THISTIMEDELIVPRICE = 25;
  protected static final int THISTIMESTORESALEPRICE = 26;
  protected static final int QUOTESTARTDATE = 27;
  protected static final int QUOTEENDDATE = 28;
  protected static final int REMARKS = 29;
  protected static final int LINEORDER = 30;
  protected static final int QUOTETYPES = 31;
  protected static final int READQUOTENUMBERS = 32;
  protected static final int QUOTENAMES = 33;
  protected static final int QUOTENUMBERS = 34;
  protected static final int QUOTEREVISIONNUMBERS = 35;
  protected static final int PUBLISHDATES = 36;
  protected static final int ACCOUNTNUMBERS = 37;
  protected static final int PARTYNAMES = 38;
  protected static final int QUOTEMANAGECODES = 39;
  protected static final int QUOTEMANAGENAMES = 40;
  protected static final int EMPLOYEENUMBERS = 41;
  protected static final int FULLNAMES = 42;
  protected static final int BASECODES = 43;
  protected static final int BASENAMES = 44;
  protected static final int DELIVPLACES = 45;
  protected static final int PAYMENTCONDITIONS = 46;
  protected static final int QUOTEINFOSTARTDATES = 47;
  protected static final int QUOTEINFOENDDATES = 48;
  protected static final int QUOTESUBMITNAMES = 49;
  protected static final int STATUSS = 50;
  protected static final int DELIVPRICETAXTYPES = 51;
  protected static final int STOREPRICETAXTYPES = 52;
  protected static final int UNITTYPES = 53;
  protected static final int SPECIALNOTES = 54;
  protected static final int INVENTORYITEMCODES = 55;
  protected static final int ITEMSHORTNAMES = 56;
  protected static final int QUOTEDIVS = 57;
  protected static final int USUALLYDELIVPRICES = 58;
  protected static final int THISTIMEDELIVPRICES = 59;
  protected static final int QUOTATIONPRICES = 60;
  protected static final int SALESDISCOUNTPRICES = 61;
  protected static final int USUALLNETPRICES = 62;
  protected static final int THISTIMENETPRICES = 63;
  protected static final int AMOUNTOFMARGINS = 64;
  protected static final int MARGINRATES = 65;
  protected static final int QUOTESTARTDATES = 66;
  protected static final int QUOTEENDDATES = 67;
  protected static final int REMARKSS = 68;
  protected static final int LINEORDERS = 69;
  protected static final int ITEMFULLNAME = 70;
  protected static final int JANCODE = 71;
  protected static final int CASEJANCODE = 72;
  protected static final int ITFCODE = 73;
  protected static final int VESSELGROUP = 74;
  protected static final int FIXEDPRICENEW = 75;
  protected static final int QUOTELINEID = 76;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoCsvQueryVORowImpl()
  {
  }


  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTETYPE:
        return getQuoteType();
      case QUOTENUMBER:
        return getQuoteNumber();
      case QUOTEREVISIONNUMBER:
        return getQuoteRevisionNumber();
      case PUBLISHDATE:
        return getPublishDate();
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case PARTYNAME:
        return getPartyName();
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case FULLNAME:
        return getFullName();
      case BASECODE:
        return getBaseCode();
      case BASENAME:
        return getBaseName();
      case DELIVPLACE:
        return getDelivPlace();
      case PAYMENTCONDITION:
        return getPaymentCondition();
      case QUOTEINFOSTARTDATE:
        return getQuoteInfoStartDate();
      case QUOTEINFOENDDATE:
        return getQuoteInfoEndDate();
      case QUOTESUBMITNAME:
        return getQuoteSubmitName();
      case DELIVPRICETAXTYPE:
        return getDelivPriceTaxType();
      case STOREPRICETAXTYPE:
        return getStorePriceTaxType();
      case UNITTYPE:
        return getUnitType();
      case STATUS:
        return getStatus();
      case SPECIALNOTE:
        return getSpecialNote();
      case INVENTORYITEMCODE:
        return getInventoryItemCode();
      case ITEMSHORTNAME:
        return getItemShortName();
      case QUOTEDIV:
        return getQuoteDiv();
      case USUALLYDELIVPRICE:
        return getUsuallyDelivPrice();
      case USUALLYSTORESALEPRICE:
        return getUsuallyStoreSalePrice();
      case THISTIMEDELIVPRICE:
        return getThisTimeDelivPrice();
      case THISTIMESTORESALEPRICE:
        return getThisTimeStoreSalePrice();
      case QUOTESTARTDATE:
        return getQuoteStartDate();
      case QUOTEENDDATE:
        return getQuoteEndDate();
      case REMARKS:
        return getRemarks();
      case LINEORDER:
        return getLineOrder();
      case QUOTETYPES:
        return getQuoteTypeS();
      case READQUOTENUMBERS:
        return getReadQuoteNumberS();
      case QUOTENAMES:
        return getQuoteNameS();
      case QUOTENUMBERS:
        return getQuoteNumberS();
      case QUOTEREVISIONNUMBERS:
        return getQuoteRevisionNumberS();
      case PUBLISHDATES:
        return getPublishDateS();
      case ACCOUNTNUMBERS:
        return getAccountNumberS();
      case PARTYNAMES:
        return getPartyNameS();
      case QUOTEMANAGECODES:
        return getQuoteManageCodeS();
      case QUOTEMANAGENAMES:
        return getQuoteManageNameS();
      case EMPLOYEENUMBERS:
        return getEmployeeNumberS();
      case FULLNAMES:
        return getFullNameS();
      case BASECODES:
        return getBaseCodeS();
      case BASENAMES:
        return getBaseNameS();
      case DELIVPLACES:
        return getDelivPlaceS();
      case PAYMENTCONDITIONS:
        return getPaymentConditionS();
      case QUOTEINFOSTARTDATES:
        return getQuoteInfoStartDateS();
      case QUOTEINFOENDDATES:
        return getQuoteInfoEndDateS();
      case QUOTESUBMITNAMES:
        return getQuoteSubmitNameS();
      case STATUSS:
        return getStatusS();
      case DELIVPRICETAXTYPES:
        return getDelivPriceTaxTypeS();
      case STOREPRICETAXTYPES:
        return getStorePriceTaxTypeS();
      case UNITTYPES:
        return getUnitTypeS();
      case SPECIALNOTES:
        return getSpecialNoteS();
      case INVENTORYITEMCODES:
        return getInventoryItemCodeS();
      case ITEMSHORTNAMES:
        return getItemShortNameS();
      case QUOTEDIVS:
        return getQuoteDivS();
      case USUALLYDELIVPRICES:
        return getUsuallyDelivPriceS();
      case THISTIMEDELIVPRICES:
        return getThisTimeDelivPriceS();
      case QUOTATIONPRICES:
        return getQuotationPriceS();
      case SALESDISCOUNTPRICES:
        return getSalesDiscountPriceS();
      case USUALLNETPRICES:
        return getUsuallNetPriceS();
      case THISTIMENETPRICES:
        return getThisTimeNetPriceS();
      case AMOUNTOFMARGINS:
        return getAmountOfMarginS();
      case MARGINRATES:
        return getMarginRateS();
      case QUOTESTARTDATES:
        return getQuoteStartDateS();
      case QUOTEENDDATES:
        return getQuoteEndDateS();
      case REMARKSS:
        return getRemarksS();
      case LINEORDERS:
        return getLineOrderS();
      case ITEMFULLNAME:
        return getItemFullName();
      case JANCODE:
        return getJanCode();
      case CASEJANCODE:
        return getCaseJanCode();
      case ITFCODE:
        return getItfCode();
      case VESSELGROUP:
        return getVesselGroup();
      case FIXEDPRICENEW:
        return getFixedPriceNew();
      case QUOTELINEID:
        return getQuoteLineId();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTETYPE:
        setQuoteType((String)value);
        return;
      case QUOTENUMBER:
        setQuoteNumber((String)value);
        return;
      case QUOTEREVISIONNUMBER:
        setQuoteRevisionNumber((String)value);
        return;
      case PUBLISHDATE:
        setPublishDate((String)value);
        return;
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
        return;
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
      case DELIVPLACE:
        setDelivPlace((String)value);
        return;
      case PAYMENTCONDITION:
        setPaymentCondition((String)value);
        return;
      case QUOTEINFOSTARTDATE:
        setQuoteInfoStartDate((String)value);
        return;
      case QUOTEINFOENDDATE:
        setQuoteInfoEndDate((String)value);
        return;
      case QUOTESUBMITNAME:
        setQuoteSubmitName((String)value);
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
      case STATUS:
        setStatus((String)value);
        return;
      case SPECIALNOTE:
        setSpecialNote((String)value);
        return;
      case INVENTORYITEMCODE:
        setInventoryItemCode((String)value);
        return;
      case ITEMSHORTNAME:
        setItemShortName((String)value);
        return;
      case QUOTEDIV:
        setQuoteDiv((String)value);
        return;
      case USUALLYDELIVPRICE:
        setUsuallyDelivPrice((String)value);
        return;
      case USUALLYSTORESALEPRICE:
        setUsuallyStoreSalePrice((String)value);
        return;
      case THISTIMEDELIVPRICE:
        setThisTimeDelivPrice((String)value);
        return;
      case THISTIMESTORESALEPRICE:
        setThisTimeStoreSalePrice((String)value);
        return;
      case QUOTESTARTDATE:
        setQuoteStartDate((String)value);
        return;
      case QUOTEENDDATE:
        setQuoteEndDate((String)value);
        return;
      case REMARKS:
        setRemarks((String)value);
        return;
      case LINEORDER:
        setLineOrder((String)value);
        return;
      case QUOTETYPES:
        setQuoteTypeS((String)value);
        return;
      case READQUOTENUMBERS:
        setReadQuoteNumberS((String)value);
        return;
      case QUOTENAMES:
        setQuoteNameS((String)value);
        return;
      case QUOTENUMBERS:
        setQuoteNumberS((String)value);
        return;
      case QUOTEREVISIONNUMBERS:
        setQuoteRevisionNumberS((String)value);
        return;
      case PUBLISHDATES:
        setPublishDateS((String)value);
        return;
      case ACCOUNTNUMBERS:
        setAccountNumberS((String)value);
        return;
      case PARTYNAMES:
        setPartyNameS((String)value);
        return;
      case QUOTEMANAGECODES:
        setQuoteManageCodeS((String)value);
        return;
      case QUOTEMANAGENAMES:
        setQuoteManageNameS((String)value);
        return;
      case EMPLOYEENUMBERS:
        setEmployeeNumberS((String)value);
        return;
      case FULLNAMES:
        setFullNameS((String)value);
        return;
      case BASECODES:
        setBaseCodeS((String)value);
        return;
      case BASENAMES:
        setBaseNameS((String)value);
        return;
      case DELIVPLACES:
        setDelivPlaceS((String)value);
        return;
      case PAYMENTCONDITIONS:
        setPaymentConditionS((String)value);
        return;
      case QUOTEINFOSTARTDATES:
        setQuoteInfoStartDateS((String)value);
        return;
      case QUOTEINFOENDDATES:
        setQuoteInfoEndDateS((String)value);
        return;
      case QUOTESUBMITNAMES:
        setQuoteSubmitNameS((String)value);
        return;
      case STATUSS:
        setStatusS((String)value);
        return;
      case DELIVPRICETAXTYPES:
        setDelivPriceTaxTypeS((String)value);
        return;
      case STOREPRICETAXTYPES:
        setStorePriceTaxTypeS((String)value);
        return;
      case UNITTYPES:
        setUnitTypeS((String)value);
        return;
      case SPECIALNOTES:
        setSpecialNoteS((String)value);
        return;
      case INVENTORYITEMCODES:
        setInventoryItemCodeS((String)value);
        return;
      case ITEMSHORTNAMES:
        setItemShortNameS((String)value);
        return;
      case QUOTEDIVS:
        setQuoteDivS((String)value);
        return;
      case USUALLYDELIVPRICES:
        setUsuallyDelivPriceS((String)value);
        return;
      case THISTIMEDELIVPRICES:
        setThisTimeDelivPriceS((String)value);
        return;
      case QUOTATIONPRICES:
        setQuotationPriceS((String)value);
        return;
      case SALESDISCOUNTPRICES:
        setSalesDiscountPriceS((String)value);
        return;
      case USUALLNETPRICES:
        setUsuallNetPriceS((String)value);
        return;
      case THISTIMENETPRICES:
        setThisTimeNetPriceS((String)value);
        return;
      case AMOUNTOFMARGINS:
        setAmountOfMarginS((String)value);
        return;
      case MARGINRATES:
        setMarginRateS((String)value);
        return;
      case QUOTESTARTDATES:
        setQuoteStartDateS((String)value);
        return;
      case QUOTEENDDATES:
        setQuoteEndDateS((String)value);
        return;
      case REMARKSS:
        setRemarksS((String)value);
        return;
      case LINEORDERS:
        setLineOrderS((String)value);
        return;
      case ITEMFULLNAME:
        setItemFullName((String)value);
        return;
      case JANCODE:
        setJanCode((String)value);
        return;
      case CASEJANCODE:
        setCaseJanCode((String)value);
        return;
      case ITFCODE:
        setItfCode((String)value);
        return;
      case VESSELGROUP:
        setVesselGroup((String)value);
        return;
      case FIXEDPRICENEW:
        setFixedPriceNew((String)value);
        return;
      case QUOTELINEID:
        setQuoteLineId((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteType
   */
  public String getQuoteType()
  {
    return (String)getAttributeInternal(QUOTETYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteType
   */
  public void setQuoteType(String value)
  {
    setAttributeInternal(QUOTETYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteNumber
   */
  public String getQuoteNumber()
  {
    return (String)getAttributeInternal(QUOTENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteNumber
   */
  public void setQuoteNumber(String value)
  {
    setAttributeInternal(QUOTENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteRevisionNumber
   */
  public String getQuoteRevisionNumber()
  {
    return (String)getAttributeInternal(QUOTEREVISIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteRevisionNumber
   */
  public void setQuoteRevisionNumber(String value)
  {
    setAttributeInternal(QUOTEREVISIONNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PublishDate
   */
  public String getPublishDate()
  {
    return (String)getAttributeInternal(PUBLISHDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PublishDate
   */
  public void setPublishDate(String value)
  {
    setAttributeInternal(PUBLISHDATE, value);
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
   * Gets the attribute value for the calculated attribute DelivPlace
   */
  public String getDelivPlace()
  {
    return (String)getAttributeInternal(DELIVPLACE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DelivPlace
   */
  public void setDelivPlace(String value)
  {
    setAttributeInternal(DELIVPLACE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PaymentCondition
   */
  public String getPaymentCondition()
  {
    return (String)getAttributeInternal(PAYMENTCONDITION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PaymentCondition
   */
  public void setPaymentCondition(String value)
  {
    setAttributeInternal(PAYMENTCONDITION, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteInfoStartDate
   */
  public String getQuoteInfoStartDate()
  {
    return (String)getAttributeInternal(QUOTEINFOSTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteInfoStartDate
   */
  public void setQuoteInfoStartDate(String value)
  {
    setAttributeInternal(QUOTEINFOSTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteInfoEndDate
   */
  public String getQuoteInfoEndDate()
  {
    return (String)getAttributeInternal(QUOTEINFOENDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteInfoEndDate
   */
  public void setQuoteInfoEndDate(String value)
  {
    setAttributeInternal(QUOTEINFOENDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteSubmitName
   */
  public String getQuoteSubmitName()
  {
    return (String)getAttributeInternal(QUOTESUBMITNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteSubmitName
   */
  public void setQuoteSubmitName(String value)
  {
    setAttributeInternal(QUOTESUBMITNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DelivPriceTaxType
   */
  public String getDelivPriceTaxType()
  {
    return (String)getAttributeInternal(DELIVPRICETAXTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DelivPriceTaxType
   */
  public void setDelivPriceTaxType(String value)
  {
    setAttributeInternal(DELIVPRICETAXTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StorePriceTaxType
   */
  public String getStorePriceTaxType()
  {
    return (String)getAttributeInternal(STOREPRICETAXTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StorePriceTaxType
   */
  public void setStorePriceTaxType(String value)
  {
    setAttributeInternal(STOREPRICETAXTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UnitType
   */
  public String getUnitType()
  {
    return (String)getAttributeInternal(UNITTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UnitType
   */
  public void setUnitType(String value)
  {
    setAttributeInternal(UNITTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Status
   */
  public String getStatus()
  {
    return (String)getAttributeInternal(STATUS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Status
   */
  public void setStatus(String value)
  {
    setAttributeInternal(STATUS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpecialNote
   */
  public String getSpecialNote()
  {
    return (String)getAttributeInternal(SPECIALNOTE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpecialNote
   */
  public void setSpecialNote(String value)
  {
    setAttributeInternal(SPECIALNOTE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InventoryItemCode
   */
  public String getInventoryItemCode()
  {
    return (String)getAttributeInternal(INVENTORYITEMCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InventoryItemCode
   */
  public void setInventoryItemCode(String value)
  {
    setAttributeInternal(INVENTORYITEMCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ItemShortName
   */
  public String getItemShortName()
  {
    return (String)getAttributeInternal(ITEMSHORTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ItemShortName
   */
  public void setItemShortName(String value)
  {
    setAttributeInternal(ITEMSHORTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteDiv
   */
  public String getQuoteDiv()
  {
    return (String)getAttributeInternal(QUOTEDIV);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteDiv
   */
  public void setQuoteDiv(String value)
  {
    setAttributeInternal(QUOTEDIV, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UsuallyDelivPrice
   */
  public String getUsuallyDelivPrice()
  {
    return (String)getAttributeInternal(USUALLYDELIVPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UsuallyDelivPrice
   */
  public void setUsuallyDelivPrice(String value)
  {
    setAttributeInternal(USUALLYDELIVPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UsuallyStoreSalePrice
   */
  public String getUsuallyStoreSalePrice()
  {
    return (String)getAttributeInternal(USUALLYSTORESALEPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UsuallyStoreSalePrice
   */
  public void setUsuallyStoreSalePrice(String value)
  {
    setAttributeInternal(USUALLYSTORESALEPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ThisTimeDelivPrice
   */
  public String getThisTimeDelivPrice()
  {
    return (String)getAttributeInternal(THISTIMEDELIVPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ThisTimeDelivPrice
   */
  public void setThisTimeDelivPrice(String value)
  {
    setAttributeInternal(THISTIMEDELIVPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ThisTimeStoreSalePrice
   */
  public String getThisTimeStoreSalePrice()
  {
    return (String)getAttributeInternal(THISTIMESTORESALEPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ThisTimeStoreSalePrice
   */
  public void setThisTimeStoreSalePrice(String value)
  {
    setAttributeInternal(THISTIMESTORESALEPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteStartDate
   */
  public String getQuoteStartDate()
  {
    return (String)getAttributeInternal(QUOTESTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteStartDate
   */
  public void setQuoteStartDate(String value)
  {
    setAttributeInternal(QUOTESTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteEndDate
   */
  public String getQuoteEndDate()
  {
    return (String)getAttributeInternal(QUOTEENDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteEndDate
   */
  public void setQuoteEndDate(String value)
  {
    setAttributeInternal(QUOTEENDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Remarks
   */
  public String getRemarks()
  {
    return (String)getAttributeInternal(REMARKS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Remarks
   */
  public void setRemarks(String value)
  {
    setAttributeInternal(REMARKS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LineOrder
   */
  public String getLineOrder()
  {
    return (String)getAttributeInternal(LINEORDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LineOrder
   */
  public void setLineOrder(String value)
  {
    setAttributeInternal(LINEORDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteTypeS
   */
  public String getQuoteTypeS()
  {
    return (String)getAttributeInternal(QUOTETYPES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteTypeS
   */
  public void setQuoteTypeS(String value)
  {
    setAttributeInternal(QUOTETYPES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ReadQuoteNumberS
   */
  public String getReadQuoteNumberS()
  {
    return (String)getAttributeInternal(READQUOTENUMBERS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ReadQuoteNumberS
   */
  public void setReadQuoteNumberS(String value)
  {
    setAttributeInternal(READQUOTENUMBERS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteNameS
   */
  public String getQuoteNameS()
  {
    return (String)getAttributeInternal(QUOTENAMES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteNameS
   */
  public void setQuoteNameS(String value)
  {
    setAttributeInternal(QUOTENAMES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteNumberS
   */
  public String getQuoteNumberS()
  {
    return (String)getAttributeInternal(QUOTENUMBERS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteNumberS
   */
  public void setQuoteNumberS(String value)
  {
    setAttributeInternal(QUOTENUMBERS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteRevisionNumberS
   */
  public String getQuoteRevisionNumberS()
  {
    return (String)getAttributeInternal(QUOTEREVISIONNUMBERS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteRevisionNumberS
   */
  public void setQuoteRevisionNumberS(String value)
  {
    setAttributeInternal(QUOTEREVISIONNUMBERS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PublishDateS
   */
  public String getPublishDateS()
  {
    return (String)getAttributeInternal(PUBLISHDATES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PublishDateS
   */
  public void setPublishDateS(String value)
  {
    setAttributeInternal(PUBLISHDATES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AccountNumberS
   */
  public String getAccountNumberS()
  {
    return (String)getAttributeInternal(ACCOUNTNUMBERS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AccountNumberS
   */
  public void setAccountNumberS(String value)
  {
    setAttributeInternal(ACCOUNTNUMBERS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PartyNameS
   */
  public String getPartyNameS()
  {
    return (String)getAttributeInternal(PARTYNAMES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PartyNameS
   */
  public void setPartyNameS(String value)
  {
    setAttributeInternal(PARTYNAMES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteManageCodeS
   */
  public String getQuoteManageCodeS()
  {
    return (String)getAttributeInternal(QUOTEMANAGECODES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteManageCodeS
   */
  public void setQuoteManageCodeS(String value)
  {
    setAttributeInternal(QUOTEMANAGECODES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteManageNameS
   */
  public String getQuoteManageNameS()
  {
    return (String)getAttributeInternal(QUOTEMANAGENAMES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteManageNameS
   */
  public void setQuoteManageNameS(String value)
  {
    setAttributeInternal(QUOTEMANAGENAMES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmployeeNumberS
   */
  public String getEmployeeNumberS()
  {
    return (String)getAttributeInternal(EMPLOYEENUMBERS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmployeeNumberS
   */
  public void setEmployeeNumberS(String value)
  {
    setAttributeInternal(EMPLOYEENUMBERS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FullNameS
   */
  public String getFullNameS()
  {
    return (String)getAttributeInternal(FULLNAMES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FullNameS
   */
  public void setFullNameS(String value)
  {
    setAttributeInternal(FULLNAMES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseCodeS
   */
  public String getBaseCodeS()
  {
    return (String)getAttributeInternal(BASECODES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseCodeS
   */
  public void setBaseCodeS(String value)
  {
    setAttributeInternal(BASECODES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseNameS
   */
  public String getBaseNameS()
  {
    return (String)getAttributeInternal(BASENAMES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseNameS
   */
  public void setBaseNameS(String value)
  {
    setAttributeInternal(BASENAMES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DelivPlaceS
   */
  public String getDelivPlaceS()
  {
    return (String)getAttributeInternal(DELIVPLACES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DelivPlaceS
   */
  public void setDelivPlaceS(String value)
  {
    setAttributeInternal(DELIVPLACES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PaymentConditionS
   */
  public String getPaymentConditionS()
  {
    return (String)getAttributeInternal(PAYMENTCONDITIONS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PaymentConditionS
   */
  public void setPaymentConditionS(String value)
  {
    setAttributeInternal(PAYMENTCONDITIONS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteInfoStartDateS
   */
  public String getQuoteInfoStartDateS()
  {
    return (String)getAttributeInternal(QUOTEINFOSTARTDATES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteInfoStartDateS
   */
  public void setQuoteInfoStartDateS(String value)
  {
    setAttributeInternal(QUOTEINFOSTARTDATES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteInfoEndDateS
   */
  public String getQuoteInfoEndDateS()
  {
    return (String)getAttributeInternal(QUOTEINFOENDDATES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteInfoEndDateS
   */
  public void setQuoteInfoEndDateS(String value)
  {
    setAttributeInternal(QUOTEINFOENDDATES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteSubmitNameS
   */
  public String getQuoteSubmitNameS()
  {
    return (String)getAttributeInternal(QUOTESUBMITNAMES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteSubmitNameS
   */
  public void setQuoteSubmitNameS(String value)
  {
    setAttributeInternal(QUOTESUBMITNAMES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StatusS
   */
  public String getStatusS()
  {
    return (String)getAttributeInternal(STATUSS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StatusS
   */
  public void setStatusS(String value)
  {
    setAttributeInternal(STATUSS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DelivPriceTaxTypeS
   */
  public String getDelivPriceTaxTypeS()
  {
    return (String)getAttributeInternal(DELIVPRICETAXTYPES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DelivPriceTaxTypeS
   */
  public void setDelivPriceTaxTypeS(String value)
  {
    setAttributeInternal(DELIVPRICETAXTYPES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StorePriceTaxTypeS
   */
  public String getStorePriceTaxTypeS()
  {
    return (String)getAttributeInternal(STOREPRICETAXTYPES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StorePriceTaxTypeS
   */
  public void setStorePriceTaxTypeS(String value)
  {
    setAttributeInternal(STOREPRICETAXTYPES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UnitTypeS
   */
  public String getUnitTypeS()
  {
    return (String)getAttributeInternal(UNITTYPES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UnitTypeS
   */
  public void setUnitTypeS(String value)
  {
    setAttributeInternal(UNITTYPES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpecialNoteS
   */
  public String getSpecialNoteS()
  {
    return (String)getAttributeInternal(SPECIALNOTES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpecialNoteS
   */
  public void setSpecialNoteS(String value)
  {
    setAttributeInternal(SPECIALNOTES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InventoryItemCodeS
   */
  public String getInventoryItemCodeS()
  {
    return (String)getAttributeInternal(INVENTORYITEMCODES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InventoryItemCodeS
   */
  public void setInventoryItemCodeS(String value)
  {
    setAttributeInternal(INVENTORYITEMCODES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ItemShortNameS
   */
  public String getItemShortNameS()
  {
    return (String)getAttributeInternal(ITEMSHORTNAMES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ItemShortNameS
   */
  public void setItemShortNameS(String value)
  {
    setAttributeInternal(ITEMSHORTNAMES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteDivS
   */
  public String getQuoteDivS()
  {
    return (String)getAttributeInternal(QUOTEDIVS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteDivS
   */
  public void setQuoteDivS(String value)
  {
    setAttributeInternal(QUOTEDIVS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UsuallyDelivPriceS
   */
  public String getUsuallyDelivPriceS()
  {
    return (String)getAttributeInternal(USUALLYDELIVPRICES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UsuallyDelivPriceS
   */
  public void setUsuallyDelivPriceS(String value)
  {
    setAttributeInternal(USUALLYDELIVPRICES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ThisTimeDelivPriceS
   */
  public String getThisTimeDelivPriceS()
  {
    return (String)getAttributeInternal(THISTIMEDELIVPRICES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ThisTimeDelivPriceS
   */
  public void setThisTimeDelivPriceS(String value)
  {
    setAttributeInternal(THISTIMEDELIVPRICES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuotationPriceS
   */
  public String getQuotationPriceS()
  {
    return (String)getAttributeInternal(QUOTATIONPRICES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuotationPriceS
   */
  public void setQuotationPriceS(String value)
  {
    setAttributeInternal(QUOTATIONPRICES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SalesDiscountPriceS
   */
  public String getSalesDiscountPriceS()
  {
    return (String)getAttributeInternal(SALESDISCOUNTPRICES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SalesDiscountPriceS
   */
  public void setSalesDiscountPriceS(String value)
  {
    setAttributeInternal(SALESDISCOUNTPRICES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UsuallNetPriceS
   */
  public String getUsuallNetPriceS()
  {
    return (String)getAttributeInternal(USUALLNETPRICES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UsuallNetPriceS
   */
  public void setUsuallNetPriceS(String value)
  {
    setAttributeInternal(USUALLNETPRICES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ThisTimeNetPriceS
   */
  public String getThisTimeNetPriceS()
  {
    return (String)getAttributeInternal(THISTIMENETPRICES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ThisTimeNetPriceS
   */
  public void setThisTimeNetPriceS(String value)
  {
    setAttributeInternal(THISTIMENETPRICES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AmountOfMarginS
   */
  public String getAmountOfMarginS()
  {
    return (String)getAttributeInternal(AMOUNTOFMARGINS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AmountOfMarginS
   */
  public void setAmountOfMarginS(String value)
  {
    setAttributeInternal(AMOUNTOFMARGINS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MarginRateS
   */
  public String getMarginRateS()
  {
    return (String)getAttributeInternal(MARGINRATES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MarginRateS
   */
  public void setMarginRateS(String value)
  {
    setAttributeInternal(MARGINRATES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteStartDateS
   */
  public String getQuoteStartDateS()
  {
    return (String)getAttributeInternal(QUOTESTARTDATES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteStartDateS
   */
  public void setQuoteStartDateS(String value)
  {
    setAttributeInternal(QUOTESTARTDATES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteEndDateS
   */
  public String getQuoteEndDateS()
  {
    return (String)getAttributeInternal(QUOTEENDDATES);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteEndDateS
   */
  public void setQuoteEndDateS(String value)
  {
    setAttributeInternal(QUOTEENDDATES, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RemarksS
   */
  public String getRemarksS()
  {
    return (String)getAttributeInternal(REMARKSS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RemarksS
   */
  public void setRemarksS(String value)
  {
    setAttributeInternal(REMARKSS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LineOrderS
   */
  public String getLineOrderS()
  {
    return (String)getAttributeInternal(LINEORDERS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LineOrderS
   */
  public void setLineOrderS(String value)
  {
    setAttributeInternal(LINEORDERS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ItemFullName
   */
  public String getItemFullName()
  {
    return (String)getAttributeInternal(ITEMFULLNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ItemFullName
   */
  public void setItemFullName(String value)
  {
    setAttributeInternal(ITEMFULLNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute JanCode
   */
  public String getJanCode()
  {
    return (String)getAttributeInternal(JANCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute JanCode
   */
  public void setJanCode(String value)
  {
    setAttributeInternal(JANCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CaseJanCode
   */
  public String getCaseJanCode()
  {
    return (String)getAttributeInternal(CASEJANCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CaseJanCode
   */
  public void setCaseJanCode(String value)
  {
    setAttributeInternal(CASEJANCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ItfCode
   */
  public String getItfCode()
  {
    return (String)getAttributeInternal(ITFCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ItfCode
   */
  public void setItfCode(String value)
  {
    setAttributeInternal(ITFCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VesselGroup
   */
  public String getVesselGroup()
  {
    return (String)getAttributeInternal(VESSELGROUP);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VesselGroup
   */
  public void setVesselGroup(String value)
  {
    setAttributeInternal(VESSELGROUP, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FixedPriceNew
   */
  public String getFixedPriceNew()
  {
    return (String)getAttributeInternal(FIXEDPRICENEW);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FixedPriceNew
   */
  public void setFixedPriceNew(String value)
  {
    setAttributeInternal(FIXEDPRICENEW, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteLineId
   */
  public Number getQuoteLineId()
  {
    return (Number)getAttributeInternal(QUOTELINEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteLineId
   */
  public void setQuoteLineId(Number value)
  {
    setAttributeInternal(QUOTELINEID, value);
  }









































































































































}