/*============================================================================
* ファイル名 : XxcsoSalesLineHistSumVORowImpl
* 概要説明   : 商談決定情報履歴明細取得用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-09 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007002j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * 商談決定情報履歴明細を取得するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesLineHistSumVORowImpl extends OAViewRowImpl 
{


  protected static final int LINEHISTORYID = 0;
  protected static final int QUOTENUMBER = 1;
  protected static final int QUOTEREVISIONNUMBER = 2;
  protected static final int INVENTORYITEMCODE = 3;
  protected static final int ITEMSHORTNAME = 4;
  protected static final int CASEINCNUM = 5;
  protected static final int JANCODE = 6;
  protected static final int ITFCODE = 7;
  protected static final int SALESCLASSNAME = 8;
  protected static final int SALESADOPTCLASSNAME = 9;
  protected static final int SALESAREANAME = 10;
  protected static final int SALESSCHEDULEDATE = 11;
  protected static final int DELIVPRICE = 12;
  protected static final int STORESALESPRICE = 13;
  protected static final int STORESALESPRICEINCTAX = 14;
  protected static final int QUOTATIONPRICE = 15;
  protected static final int INTRODUCETERMS = 16;
  protected static final int SALESCLASSCODE = 17;
  protected static final int SALESADOPTCLASSRENDER = 18;
  protected static final int SALESAREARENDER = 19;
  protected static final int DELIVPRICERENDER = 20;
  protected static final int STORESALESPRICERENDER = 21;
  protected static final int STORESALESPRICEINCTAXRENDER = 22;
  protected static final int QUOTATIONPRICERENDER = 23;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesLineHistSumVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LineHistoryId
   */
  public Number getLineHistoryId()
  {
    return (Number)getAttributeInternal(LINEHISTORYID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LineHistoryId
   */
  public void setLineHistoryId(Number value)
  {
    setAttributeInternal(LINEHISTORYID, value);
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
  public Number getQuoteRevisionNumber()
  {
    return (Number)getAttributeInternal(QUOTEREVISIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteRevisionNumber
   */
  public void setQuoteRevisionNumber(Number value)
  {
    setAttributeInternal(QUOTEREVISIONNUMBER, value);
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case LINEHISTORYID:
        return getLineHistoryId();
      case QUOTENUMBER:
        return getQuoteNumber();
      case QUOTEREVISIONNUMBER:
        return getQuoteRevisionNumber();
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
      case SALESCLASSNAME:
        return getSalesClassName();
      case SALESADOPTCLASSNAME:
        return getSalesAdoptClassName();
      case SALESAREANAME:
        return getSalesAreaName();
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
      case SALESCLASSCODE:
        return getSalesClassCode();
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
      case LINEHISTORYID:
        setLineHistoryId((Number)value);
        return;
      case QUOTENUMBER:
        setQuoteNumber((String)value);
        return;
      case QUOTEREVISIONNUMBER:
        setQuoteRevisionNumber((Number)value);
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
      case SALESCLASSNAME:
        setSalesClassName((String)value);
        return;
      case SALESADOPTCLASSNAME:
        setSalesAdoptClassName((String)value);
        return;
      case SALESAREANAME:
        setSalesAreaName((String)value);
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
      case SALESCLASSCODE:
        setSalesClassCode((String)value);
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
   * Gets the attribute value for the calculated attribute SalesClassName
   */
  public String getSalesClassName()
  {
    return (String)getAttributeInternal(SALESCLASSNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SalesClassName
   */
  public void setSalesClassName(String value)
  {
    setAttributeInternal(SALESCLASSNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SalesAdoptClassName
   */
  public String getSalesAdoptClassName()
  {
    return (String)getAttributeInternal(SALESADOPTCLASSNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SalesAdoptClassName
   */
  public void setSalesAdoptClassName(String value)
  {
    setAttributeInternal(SALESADOPTCLASSNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SalesAreaName
   */
  public String getSalesAreaName()
  {
    return (String)getAttributeInternal(SALESAREANAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SalesAreaName
   */
  public void setSalesAreaName(String value)
  {
    setAttributeInternal(SALESAREANAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SalesScheduleDate
   */
  public Date getSalesScheduleDate()
  {
    return (Date)getAttributeInternal(SALESSCHEDULEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SalesScheduleDate
   */
  public void setSalesScheduleDate(Date value)
  {
    setAttributeInternal(SALESSCHEDULEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DelivPrice
   */
  public String getDelivPrice()
  {
    return (String)getAttributeInternal(DELIVPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DelivPrice
   */
  public void setDelivPrice(String value)
  {
    setAttributeInternal(DELIVPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StoreSalesPrice
   */
  public String getStoreSalesPrice()
  {
    return (String)getAttributeInternal(STORESALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StoreSalesPrice
   */
  public void setStoreSalesPrice(String value)
  {
    setAttributeInternal(STORESALESPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StoreSalesPriceIncTax
   */
  public String getStoreSalesPriceIncTax()
  {
    return (String)getAttributeInternal(STORESALESPRICEINCTAX);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StoreSalesPriceIncTax
   */
  public void setStoreSalesPriceIncTax(String value)
  {
    setAttributeInternal(STORESALESPRICEINCTAX, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuotationPrice
   */
  public String getQuotationPrice()
  {
    return (String)getAttributeInternal(QUOTATIONPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuotationPrice
   */
  public void setQuotationPrice(String value)
  {
    setAttributeInternal(QUOTATIONPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroduceTerms
   */
  public String getIntroduceTerms()
  {
    return (String)getAttributeInternal(INTRODUCETERMS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroduceTerms
   */
  public void setIntroduceTerms(String value)
  {
    setAttributeInternal(INTRODUCETERMS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SalesClassCode
   */
  public String getSalesClassCode()
  {
    return (String)getAttributeInternal(SALESCLASSCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SalesClassCode
   */
  public void setSalesClassCode(String value)
  {
    setAttributeInternal(SALESCLASSCODE, value);
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
}