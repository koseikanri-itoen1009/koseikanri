/*============================================================================
* ÉtÉ@ÉCÉãñº : XxcsoQuoteLinesSalesFullVORowImpl
* äTóvê‡ñæ   : å©êœñæç◊ìoò^Å^çXêVópÉrÉÖÅ[çsÉNÉâÉX
* ÉoÅ[ÉWÉáÉì : 1.0
*============================================================================
* èCê≥óöó
* ì˙ït       Ver. íSìñé“       èCê≥ì‡óe
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-15 1.0  SCSãyêÏóÃ    êVãKçÏê¨
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * å©êœñæç◊èÓïÒÇìoò^Å^çXêVÇ∑ÇÈÇΩÇﬂÇÃÉrÉÖÅ[çsÉNÉâÉXÇ≈Ç∑ÅB
 * @author  SCSãyêÏóÃ
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteLinesSalesFullVORowImpl extends OAViewRowImpl 
{


  protected static final int QUOTELINEID = 0;
  protected static final int QUOTEHEADERID = 1;
  protected static final int REFERENCEQUOTELINEID = 2;
  protected static final int INVENTORYITEMID = 3;
  protected static final int QUOTEDIV = 4;
  protected static final int USUALLYDELIVPRICE = 5;
  protected static final int USUALLYSTORESALEPRICE = 6;
  protected static final int THISTIMEDELIVPRICE = 7;
  protected static final int THISTIMESTORESALEPRICE = 8;
  protected static final int QUOTATIONPRICE = 9;
  protected static final int SALESDISCOUNTPRICE = 10;
  protected static final int USUALLNETPRICE = 11;
  protected static final int THISTIMENETPRICE = 12;
  protected static final int AMOUNTOFMARGIN = 13;
  protected static final int MARGINRATE = 14;
  protected static final int QUOTESTARTDATE = 15;
  protected static final int QUOTEENDDATE = 16;
  protected static final int REMARKS = 17;
  protected static final int LINEORDER = 18;
  protected static final int BUSINESSPRICE = 19;
  protected static final int CREATEDBY = 20;
  protected static final int CREATIONDATE = 21;
  protected static final int LASTUPDATEDBY = 22;
  protected static final int LASTUPDATEDATE = 23;
  protected static final int LASTUPDATELOGIN = 24;
  protected static final int REQUESTID = 25;
  protected static final int PROGRAMAPPLICATIONID = 26;
  protected static final int PROGRAMID = 27;
  protected static final int PROGRAMUPDATEDATE = 28;
  protected static final int SELECTFLAG = 29;
  protected static final int INVENTORYITEMCODE = 30;
  protected static final int ITEMSHORTNAME = 31;
  protected static final int CASEINCNUM = 32;
  protected static final int BOWLINCNUM = 33;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteLinesSalesFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoQuoteLinesSalesVEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoQuoteLinesSalesVEOImpl getXxcsoQuoteLinesSalesVEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoQuoteLinesSalesVEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for QUOTE_LINE_ID using the alias name QuoteLineId
   */
  public Number getQuoteLineId()
  {
    return (Number)getAttributeInternal(QUOTELINEID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for QUOTE_LINE_ID using the alias name QuoteLineId
   */
  public void setQuoteLineId(Number value)
  {
    setAttributeInternal(QUOTELINEID, value);
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
   * Gets the attribute value for REFERENCE_QUOTE_LINE_ID using the alias name ReferenceQuoteLineId
   */
  public Number getReferenceQuoteLineId()
  {
    return (Number)getAttributeInternal(REFERENCEQUOTELINEID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for REFERENCE_QUOTE_LINE_ID using the alias name ReferenceQuoteLineId
   */
  public void setReferenceQuoteLineId(Number value)
  {
    setAttributeInternal(REFERENCEQUOTELINEID, value);
  }

  /**
   * 
   * Gets the attribute value for INVENTORY_ITEM_ID using the alias name InventoryItemId
   */
  public Number getInventoryItemId()
  {
    return (Number)getAttributeInternal(INVENTORYITEMID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INVENTORY_ITEM_ID using the alias name InventoryItemId
   */
  public void setInventoryItemId(Number value)
  {
    setAttributeInternal(INVENTORYITEMID, value);
  }

  /**
   * 
   * Gets the attribute value for QUOTE_DIV using the alias name QuoteDiv
   */
  public String getQuoteDiv()
  {
    return (String)getAttributeInternal(QUOTEDIV);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for QUOTE_DIV using the alias name QuoteDiv
   */
  public void setQuoteDiv(String value)
  {
    setAttributeInternal(QUOTEDIV, value);
  }

  /**
   * 
   * Gets the attribute value for USUALLY_DELIV_PRICE using the alias name UsuallyDelivPrice
   */
  public String getUsuallyDelivPrice()
  {
    return (String)getAttributeInternal(USUALLYDELIVPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for USUALLY_DELIV_PRICE using the alias name UsuallyDelivPrice
   */
  public void setUsuallyDelivPrice(String value)
  {
    setAttributeInternal(USUALLYDELIVPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for USUALLY_STORE_SALE_PRICE using the alias name UsuallyStoreSalePrice
   */
  public String getUsuallyStoreSalePrice()
  {
    return (String)getAttributeInternal(USUALLYSTORESALEPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for USUALLY_STORE_SALE_PRICE using the alias name UsuallyStoreSalePrice
   */
  public void setUsuallyStoreSalePrice(String value)
  {
    setAttributeInternal(USUALLYSTORESALEPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for THIS_TIME_DELIV_PRICE using the alias name ThisTimeDelivPrice
   */
  public String getThisTimeDelivPrice()
  {
    return (String)getAttributeInternal(THISTIMEDELIVPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for THIS_TIME_DELIV_PRICE using the alias name ThisTimeDelivPrice
   */
  public void setThisTimeDelivPrice(String value)
  {
    setAttributeInternal(THISTIMEDELIVPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for THIS_TIME_STORE_SALE_PRICE using the alias name ThisTimeStoreSalePrice
   */
  public String getThisTimeStoreSalePrice()
  {
    return (String)getAttributeInternal(THISTIMESTORESALEPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for THIS_TIME_STORE_SALE_PRICE using the alias name ThisTimeStoreSalePrice
   */
  public void setThisTimeStoreSalePrice(String value)
  {
    setAttributeInternal(THISTIMESTORESALEPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for QUOTATION_PRICE using the alias name QuotationPrice
   */
  public Number getQuotationPrice()
  {
    return (Number)getAttributeInternal(QUOTATIONPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for QUOTATION_PRICE using the alias name QuotationPrice
   */
  public void setQuotationPrice(Number value)
  {
    setAttributeInternal(QUOTATIONPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for SALES_DISCOUNT_PRICE using the alias name SalesDiscountPrice
   */
  public Number getSalesDiscountPrice()
  {
    return (Number)getAttributeInternal(SALESDISCOUNTPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SALES_DISCOUNT_PRICE using the alias name SalesDiscountPrice
   */
  public void setSalesDiscountPrice(Number value)
  {
    setAttributeInternal(SALESDISCOUNTPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for USUALL_NET_PRICE using the alias name UsuallNetPrice
   */
  public Number getUsuallNetPrice()
  {
    return (Number)getAttributeInternal(USUALLNETPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for USUALL_NET_PRICE using the alias name UsuallNetPrice
   */
  public void setUsuallNetPrice(Number value)
  {
    setAttributeInternal(USUALLNETPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for THIS_TIME_NET_PRICE using the alias name ThisTimeNetPrice
   */
  public Number getThisTimeNetPrice()
  {
    return (Number)getAttributeInternal(THISTIMENETPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for THIS_TIME_NET_PRICE using the alias name ThisTimeNetPrice
   */
  public void setThisTimeNetPrice(Number value)
  {
    setAttributeInternal(THISTIMENETPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for AMOUNT_OF_MARGIN using the alias name AmountOfMargin
   */
  public Number getAmountOfMargin()
  {
    return (Number)getAttributeInternal(AMOUNTOFMARGIN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for AMOUNT_OF_MARGIN using the alias name AmountOfMargin
   */
  public void setAmountOfMargin(Number value)
  {
    setAttributeInternal(AMOUNTOFMARGIN, value);
  }

  /**
   * 
   * Gets the attribute value for MARGIN_RATE using the alias name MarginRate
   */
  public Number getMarginRate()
  {
    return (Number)getAttributeInternal(MARGINRATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for MARGIN_RATE using the alias name MarginRate
   */
  public void setMarginRate(Number value)
  {
    setAttributeInternal(MARGINRATE, value);
  }

  /**
   * 
   * Gets the attribute value for QUOTE_START_DATE using the alias name QuoteStartDate
   */
  public Date getQuoteStartDate()
  {
    return (Date)getAttributeInternal(QUOTESTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for QUOTE_START_DATE using the alias name QuoteStartDate
   */
  public void setQuoteStartDate(Date value)
  {
    setAttributeInternal(QUOTESTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for QUOTE_END_DATE using the alias name QuoteEndDate
   */
  public Date getQuoteEndDate()
  {
    return (Date)getAttributeInternal(QUOTEENDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for QUOTE_END_DATE using the alias name QuoteEndDate
   */
  public void setQuoteEndDate(Date value)
  {
    setAttributeInternal(QUOTEENDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for REMARKS using the alias name Remarks
   */
  public String getRemarks()
  {
    return (String)getAttributeInternal(REMARKS);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for REMARKS using the alias name Remarks
   */
  public void setRemarks(String value)
  {
    setAttributeInternal(REMARKS, value);
  }

  /**
   * 
   * Gets the attribute value for LINE_ORDER using the alias name LineOrder
   */
  public String getLineOrder()
  {
    return (String)getAttributeInternal(LINEORDER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LINE_ORDER using the alias name LineOrder
   */
  public void setLineOrder(String value)
  {
    setAttributeInternal(LINEORDER, value);
  }

  /**
   * 
   * Gets the attribute value for BUSINESS_PRICE using the alias name BusinessPrice
   */
  public Number getBusinessPrice()
  {
    return (Number)getAttributeInternal(BUSINESSPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BUSINESS_PRICE using the alias name BusinessPrice
   */
  public void setBusinessPrice(Number value)
  {
    setAttributeInternal(BUSINESSPRICE, value);
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
      case QUOTELINEID:
        return getQuoteLineId();
      case QUOTEHEADERID:
        return getQuoteHeaderId();
      case REFERENCEQUOTELINEID:
        return getReferenceQuoteLineId();
      case INVENTORYITEMID:
        return getInventoryItemId();
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
      case QUOTATIONPRICE:
        return getQuotationPrice();
      case SALESDISCOUNTPRICE:
        return getSalesDiscountPrice();
      case USUALLNETPRICE:
        return getUsuallNetPrice();
      case THISTIMENETPRICE:
        return getThisTimeNetPrice();
      case AMOUNTOFMARGIN:
        return getAmountOfMargin();
      case MARGINRATE:
        return getMarginRate();
      case QUOTESTARTDATE:
        return getQuoteStartDate();
      case QUOTEENDDATE:
        return getQuoteEndDate();
      case REMARKS:
        return getRemarks();
      case LINEORDER:
        return getLineOrder();
      case BUSINESSPRICE:
        return getBusinessPrice();
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
      case SELECTFLAG:
        return getSelectFlag();
      case INVENTORYITEMCODE:
        return getInventoryItemCode();
      case ITEMSHORTNAME:
        return getItemShortName();
      case CASEINCNUM:
        return getCaseIncNum();
      case BOWLINCNUM:
        return getBowlIncNum();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTELINEID:
        setQuoteLineId((Number)value);
        return;
      case QUOTEHEADERID:
        setQuoteHeaderId((Number)value);
        return;
      case REFERENCEQUOTELINEID:
        setReferenceQuoteLineId((Number)value);
        return;
      case INVENTORYITEMID:
        setInventoryItemId((Number)value);
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
      case QUOTATIONPRICE:
        setQuotationPrice((Number)value);
        return;
      case SALESDISCOUNTPRICE:
        setSalesDiscountPrice((Number)value);
        return;
      case USUALLNETPRICE:
        setUsuallNetPrice((Number)value);
        return;
      case THISTIMENETPRICE:
        setThisTimeNetPrice((Number)value);
        return;
      case AMOUNTOFMARGIN:
        setAmountOfMargin((Number)value);
        return;
      case MARGINRATE:
        setMarginRate((Number)value);
        return;
      case QUOTESTARTDATE:
        setQuoteStartDate((Date)value);
        return;
      case QUOTEENDDATE:
        setQuoteEndDate((Date)value);
        return;
      case REMARKS:
        setRemarks((String)value);
        return;
      case LINEORDER:
        setLineOrder((String)value);
        return;
      case BUSINESSPRICE:
        setBusinessPrice((Number)value);
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
      case SELECTFLAG:
        setSelectFlag((String)value);
        return;
      case INVENTORYITEMCODE:
        setInventoryItemCode((String)value);
        return;
      case ITEMSHORTNAME:
        setItemShortName((String)value);
        return;
      case CASEINCNUM:
        setCaseIncNum((Number)value);
        return;
      case BOWLINCNUM:
        setBowlIncNum((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
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
   * Gets the attribute value for the calculated attribute SelectFlag
   */
  public String getSelectFlag()
  {
    return (String)getAttributeInternal(SELECTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SelectFlag
   */
  public void setSelectFlag(String value)
  {
    setAttributeInternal(SELECTFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CaseIncNum
   */
  public Number getCaseIncNum()
  {
    return (Number)getAttributeInternal(CASEINCNUM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CaseIncNum
   */
  public void setCaseIncNum(Number value)
  {
    setAttributeInternal(CASEINCNUM, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BowlIncNum
   */
  public Number getBowlIncNum()
  {
    return (Number)getAttributeInternal(BOWLINCNUM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BowlIncNum
   */
  public void setBowlIncNum(Number value)
  {
    setAttributeInternal(BOWLINCNUM, value);
  }
}