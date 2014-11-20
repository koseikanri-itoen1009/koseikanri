/*============================================================================
* ÉtÉ@ÉCÉãñº : XxcsoSalesLineFullVORowImpl
* äTóvê‡ñæ   : è§íkåàíËèÓïÒñæç◊ìoò^Å^çXêVópÉrÉÖÅ[çsÉNÉâÉX
* ÉoÅ[ÉWÉáÉì : 1.0
*============================================================================
* èCê≥óöó
* ì˙ït       Ver. íSìñé“       èCê≥ì‡óe
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-10 1.0  SCSè¨êÏç_    êVãKçÏê¨
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.AttributeList;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso007003j.util.XxcsoSalesRegistConstants;

/*******************************************************************************
 * è§íkåàíËèÓïÒñæç◊èÓïÒÇìoò^Å^çXêVÇ∑ÇÈÇΩÇﬂÇÃÉrÉÖÅ[çsÉNÉâÉXÇ≈Ç∑ÅB
 * @author  SCSè¨êÏç_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesLineFullVORowImpl extends OAViewRowImpl 
{


  protected static final int SALESLINEID = 0;
  protected static final int SALESHEADERID = 1;
  protected static final int QUOTENUMBER = 2;
  protected static final int QUOTEREVISIONNUMBER = 3;
  protected static final int INVENTORYITEMID = 4;
  protected static final int SALESCLASSCODE = 5;
  protected static final int SALESADOPTCLASSCODE = 6;
  protected static final int SALESAREACODE = 7;
  protected static final int SALESSCHEDULEDATE = 8;
  protected static final int DELIVPRICE = 9;
  protected static final int STORESALESPRICE = 10;
  protected static final int STORESALESPRICEINCTAX = 11;
  protected static final int QUOTATIONPRICE = 12;
  protected static final int INTRODUCETERMS = 13;
  protected static final int NOTIFYFLAG = 14;
  protected static final int CREATEDBY = 15;
  protected static final int CREATIONDATE = 16;
  protected static final int LASTUPDATEDBY = 17;
  protected static final int LASTUPDATEDATE = 18;
  protected static final int LASTUPDATELOGIN = 19;
  protected static final int REQUESTID = 20;
  protected static final int PROGRAMAPPLICATIONID = 21;
  protected static final int PROGRAMID = 22;
  protected static final int PROGRAMUPDATEDATE = 23;
  protected static final int NOTIFIEDCOUNT = 24;
  protected static final int INVENTORYITEMCODE = 25;
  protected static final int ITEMSHORTNAME = 26;
  protected static final int CASEINCNUM = 27;
  protected static final int JANCODE = 28;
  protected static final int ITFCODE = 29;
  protected static final int DELETEENABLESWITCHER = 30;
  protected static final int ROWREADONLY = 31;
  protected static final int SALESADOPTCLASSRENDER = 32;
  protected static final int SALESAREARENDER = 33;
  protected static final int DELIVPRICERENDER = 34;
  protected static final int STORESALESPRICERENDER = 35;
  protected static final int STORESALESPRICEINCTAXRENDER = 36;
  protected static final int QUOTATIONPRICERENDER = 37;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesLineFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoSalesLinesVEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoSalesLinesVEOImpl getXxcsoSalesLinesVEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoSalesLinesVEOImpl)getEntity(0);
  }



  /*****************************************************************************
   * ÉåÉRÅ[ÉhçÏê¨èàóùÇ≈Ç∑ÅB
   * @see oracle.apps.fnd.framework.server.OAViewRowImpl.create
   *****************************************************************************
   */
  public void create(AttributeList list)
  {
    OAApplicationModule am = (OAApplicationModule)getApplicationModule();
    OADBTransaction txn = am.getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoUtils.checkRowSize(
      this
     ,XxcsoSalesRegistConstants.TOKEN_VALUE_SALES_INFO
    );

    getViewObject().last();
    getViewObject().next();
    
    super.create(list);

    setRowReadOnly(Boolean.FALSE);
    setSalesAdoptClassRender(Boolean.FALSE);
    setSalesAreaRender(Boolean.TRUE);
    setDelivPriceRender(Boolean.TRUE);
    setStoreSalesPriceRender(Boolean.TRUE);
    setStoreSalesPriceIncTaxRender(Boolean.TRUE);
    setQuotationPriceRender(Boolean.TRUE);

    XxcsoUtils.debug(txn, "[END]");
  }

  /**
   * 
   * Gets the attribute value for SALES_LINE_ID using the alias name SalesLineId
   */
  public Number getSalesLineId()
  {
    return (Number)getAttributeInternal(SALESLINEID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SALES_LINE_ID using the alias name SalesLineId
   */
  public void setSalesLineId(Number value)
  {
    setAttributeInternal(SALESLINEID, value);
  }

  /**
   * 
   * Gets the attribute value for SALES_HEADER_ID using the alias name SalesHeaderId
   */
  public Number getSalesHeaderId()
  {
    return (Number)getAttributeInternal(SALESHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SALES_HEADER_ID using the alias name SalesHeaderId
   */
  public void setSalesHeaderId(Number value)
  {
    setAttributeInternal(SALESHEADERID, value);
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
   * Gets the attribute value for SALES_CLASS_CODE using the alias name SalesClassCode
   */
  public String getSalesClassCode()
  {
    return (String)getAttributeInternal(SALESCLASSCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SALES_CLASS_CODE using the alias name SalesClassCode
   */
  public void setSalesClassCode(String value)
  {
    setAttributeInternal(SALESCLASSCODE, value);
  }

  /**
   * 
   * Gets the attribute value for SALES_ADOPT_CLASS_CODE using the alias name SalesAdoptClassCode
   */
  public String getSalesAdoptClassCode()
  {
    return (String)getAttributeInternal(SALESADOPTCLASSCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SALES_ADOPT_CLASS_CODE using the alias name SalesAdoptClassCode
   */
  public void setSalesAdoptClassCode(String value)
  {
    setAttributeInternal(SALESADOPTCLASSCODE, value);
  }

  /**
   * 
   * Gets the attribute value for SALES_AREA_CODE using the alias name SalesAreaCode
   */
  public String getSalesAreaCode()
  {
    return (String)getAttributeInternal(SALESAREACODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SALES_AREA_CODE using the alias name SalesAreaCode
   */
  public void setSalesAreaCode(String value)
  {
    setAttributeInternal(SALESAREACODE, value);
  }

  /**
   * 
   * Gets the attribute value for SALES_SCHEDULE_DATE using the alias name SalesScheduleDate
   */
  public Date getSalesScheduleDate()
  {
    return (Date)getAttributeInternal(SALESSCHEDULEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SALES_SCHEDULE_DATE using the alias name SalesScheduleDate
   */
  public void setSalesScheduleDate(Date value)
  {
    setAttributeInternal(SALESSCHEDULEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for DELIV_PRICE using the alias name DelivPrice
   */
  public String getDelivPrice()
  {
    return (String)getAttributeInternal(DELIVPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for DELIV_PRICE using the alias name DelivPrice
   */
  public void setDelivPrice(String value)
  {
    setAttributeInternal(DELIVPRICE, value);
  }



  /**
   * 
   * Gets the attribute value for STORE_SALES_PRICE_INC_TAX using the alias name StoreSalesPriceIncTax
   */
  public String getStoreSalesPriceIncTax()
  {
    return (String)getAttributeInternal(STORESALESPRICEINCTAX);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for STORE_SALES_PRICE_INC_TAX using the alias name StoreSalesPriceIncTax
   */
  public void setStoreSalesPriceIncTax(String value)
  {
    setAttributeInternal(STORESALESPRICEINCTAX, value);
  }

  /**
   * 
   * Gets the attribute value for QUOTATION_PRICE using the alias name QuotationPrice
   */
  public String getQuotationPrice()
  {
    return (String)getAttributeInternal(QUOTATIONPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for QUOTATION_PRICE using the alias name QuotationPrice
   */
  public void setQuotationPrice(String value)
  {
    setAttributeInternal(QUOTATIONPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for INTRODUCE_TERMS using the alias name IntroduceTerms
   */
  public String getIntroduceTerms()
  {
    return (String)getAttributeInternal(INTRODUCETERMS);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for INTRODUCE_TERMS using the alias name IntroduceTerms
   */
  public void setIntroduceTerms(String value)
  {
    setAttributeInternal(INTRODUCETERMS, value);
  }

  /**
   * 
   * Gets the attribute value for NOTIFY_FLAG using the alias name NotifyFlag
   */
  public String getNotifyFlag()
  {
    return (String)getAttributeInternal(NOTIFYFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NOTIFY_FLAG using the alias name NotifyFlag
   */
  public void setNotifyFlag(String value)
  {
    setAttributeInternal(NOTIFYFLAG, value);
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
      case SALESLINEID:
        return getSalesLineId();
      case SALESHEADERID:
        return getSalesHeaderId();
      case QUOTENUMBER:
        return getQuoteNumber();
      case QUOTEREVISIONNUMBER:
        return getQuoteRevisionNumber();
      case INVENTORYITEMID:
        return getInventoryItemId();
      case SALESCLASSCODE:
        return getSalesClassCode();
      case SALESADOPTCLASSCODE:
        return getSalesAdoptClassCode();
      case SALESAREACODE:
        return getSalesAreaCode();
      case SALESSCHEDULEDATE:
        return getSalesScheduleDate();
      case DELIVPRICE:
        return getDelivPrice();
      case STORESALESPRICE:
        return getStoreSalesPrice();
      case STORESALESPRICEINCTAX:
        return getStoreSalesPriceIncTax();
      case QUOTATIONPRICE:
        return getQuotationPrice();
      case INTRODUCETERMS:
        return getIntroduceTerms();
      case NOTIFYFLAG:
        return getNotifyFlag();
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
      case NOTIFIEDCOUNT:
        return getNotifiedCount();
      case INVENTORYITEMCODE:
        return getInventoryItemCode();
      case ITEMSHORTNAME:
        return getItemShortName();
      case CASEINCNUM:
        return getCaseIncNum();
      case JANCODE:
        return getJanCode();
      case ITFCODE:
        return getItfCode();
      case DELETEENABLESWITCHER:
        return getDeleteEnableSwitcher();
      case ROWREADONLY:
        return getRowReadOnly();
      case SALESADOPTCLASSRENDER:
        return getSalesAdoptClassRender();
      case SALESAREARENDER:
        return getSalesAreaRender();
      case DELIVPRICERENDER:
        return getDelivPriceRender();
      case STORESALESPRICERENDER:
        return getStoreSalesPriceRender();
      case STORESALESPRICEINCTAXRENDER:
        return getStoreSalesPriceIncTaxRender();
      case QUOTATIONPRICERENDER:
        return getQuotationPriceRender();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SALESLINEID:
        setSalesLineId((Number)value);
        return;
      case SALESHEADERID:
        setSalesHeaderId((Number)value);
        return;
      case QUOTENUMBER:
        setQuoteNumber((String)value);
        return;
      case QUOTEREVISIONNUMBER:
        setQuoteRevisionNumber((Number)value);
        return;
      case INVENTORYITEMID:
        setInventoryItemId((Number)value);
        return;
      case SALESCLASSCODE:
        setSalesClassCode((String)value);
        return;
      case SALESADOPTCLASSCODE:
        setSalesAdoptClassCode((String)value);
        return;
      case SALESAREACODE:
        setSalesAreaCode((String)value);
        return;
      case SALESSCHEDULEDATE:
        setSalesScheduleDate((Date)value);
        return;
      case DELIVPRICE:
        setDelivPrice((String)value);
        return;
      case STORESALESPRICE:
        setStoreSalesPrice((String)value);
        return;
      case STORESALESPRICEINCTAX:
        setStoreSalesPriceIncTax((String)value);
        return;
      case QUOTATIONPRICE:
        setQuotationPrice((String)value);
        return;
      case INTRODUCETERMS:
        setIntroduceTerms((String)value);
        return;
      case NOTIFYFLAG:
        setNotifyFlag((String)value);
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
      case NOTIFIEDCOUNT:
        setNotifiedCount((Number)value);
        return;
      case INVENTORYITEMCODE:
        setInventoryItemCode((String)value);
        return;
      case ITEMSHORTNAME:
        setItemShortName((String)value);
        return;
      case CASEINCNUM:
        setCaseIncNum((String)value);
        return;
      case JANCODE:
        setJanCode((String)value);
        return;
      case ITFCODE:
        setItfCode((String)value);
        return;
      case DELETEENABLESWITCHER:
        setDeleteEnableSwitcher((String)value);
        return;
      case ROWREADONLY:
        setRowReadOnly((Boolean)value);
        return;
      case SALESADOPTCLASSRENDER:
        setSalesAdoptClassRender((Boolean)value);
        return;
      case SALESAREARENDER:
        setSalesAreaRender((Boolean)value);
        return;
      case DELIVPRICERENDER:
        setDelivPriceRender((Boolean)value);
        return;
      case STORESALESPRICERENDER:
        setStoreSalesPriceRender((Boolean)value);
        return;
      case STORESALESPRICEINCTAXRENDER:
        setStoreSalesPriceIncTaxRender((Boolean)value);
        return;
      case QUOTATIONPRICERENDER:
        setQuotationPriceRender((Boolean)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NotifiedCount
   */
  public Number getNotifiedCount()
  {
    return (Number)getAttributeInternal(NOTIFIEDCOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NotifiedCount
   */
  public void setNotifiedCount(Number value)
  {
    setAttributeInternal(NOTIFIEDCOUNT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DeleteEnableSwitcher
   */
  public String getDeleteEnableSwitcher()
  {
    return (String)getAttributeInternal(DELETEENABLESWITCHER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DeleteEnableSwitcher
   */
  public void setDeleteEnableSwitcher(String value)
  {
    setAttributeInternal(DELETEENABLESWITCHER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RowReadOnly
   */
  public Boolean getRowReadOnly()
  {
    return (Boolean)getAttributeInternal(ROWREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RowReadOnly
   */
  public void setRowReadOnly(Boolean value)
  {
    setAttributeInternal(ROWREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SalesAdoptClassRender
   */
  public Boolean getSalesAdoptClassRender()
  {
    return (Boolean)getAttributeInternal(SALESADOPTCLASSRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SalesAdoptClassRender
   */
  public void setSalesAdoptClassRender(Boolean value)
  {
    setAttributeInternal(SALESADOPTCLASSRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SalesAreaRender
   */
  public Boolean getSalesAreaRender()
  {
    return (Boolean)getAttributeInternal(SALESAREARENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SalesAreaRender
   */
  public void setSalesAreaRender(Boolean value)
  {
    setAttributeInternal(SALESAREARENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DelivPriceRender
   */
  public Boolean getDelivPriceRender()
  {
    return (Boolean)getAttributeInternal(DELIVPRICERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DelivPriceRender
   */
  public void setDelivPriceRender(Boolean value)
  {
    setAttributeInternal(DELIVPRICERENDER, value);
  }





  /**
   * 
   * Gets the attribute value for STORE_SALES_PRICE using the alias name StoreSalesPrice
   */
  public String getStoreSalesPrice()
  {
    return (String)getAttributeInternal(STORESALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for STORE_SALES_PRICE using the alias name StoreSalesPrice
   */
  public void setStoreSalesPrice(String value)
  {
    setAttributeInternal(STORESALESPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StoreSalesPriceIncTaxRender
   */
  public Boolean getStoreSalesPriceIncTaxRender()
  {
    return (Boolean)getAttributeInternal(STORESALESPRICEINCTAXRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StoreSalesPriceIncTaxRender
   */
  public void setStoreSalesPriceIncTaxRender(Boolean value)
  {
    setAttributeInternal(STORESALESPRICEINCTAXRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StoreSalesPriceRender
   */
  public Boolean getStoreSalesPriceRender()
  {
    return (Boolean)getAttributeInternal(STORESALESPRICERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StoreSalesPriceRender
   */
  public void setStoreSalesPriceRender(Boolean value)
  {
    setAttributeInternal(STORESALESPRICERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuotationPriceRender
   */
  public Boolean getQuotationPriceRender()
  {
    return (Boolean)getAttributeInternal(QUOTATIONPRICERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuotationPriceRender
   */
  public void setQuotationPriceRender(Boolean value)
  {
    setAttributeInternal(QUOTATIONPRICERENDER, value);
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
   * Gets the attribute value for the calculated attribute CaseIncNum
   */
  public String getCaseIncNum()
  {
    return (String)getAttributeInternal(CASEINCNUM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CaseIncNum
   */
  public void setCaseIncNum(String value)
  {
    setAttributeInternal(CASEINCNUM, value);
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









}