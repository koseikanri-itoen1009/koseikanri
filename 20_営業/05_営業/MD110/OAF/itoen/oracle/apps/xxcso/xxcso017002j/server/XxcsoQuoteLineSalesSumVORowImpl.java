/*============================================================================
* ファイル名 : XxcsoQuoteLinesStoreFullVORowImpl
* 概要説明   : 見積明細販売情報参照用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
/*******************************************************************************
 * 見積明細販売情報を参照するためのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteLineSalesSumVORowImpl extends OAViewRowImpl 
{


  protected static final int QUOTELINEID = 0;
  protected static final int INVENTORYITEMID = 1;
  protected static final int INVENTORYITEMCODE = 2;
  protected static final int ITEMSHORTNAME = 3;
  protected static final int QUOTEDIV = 4;
  protected static final int USUALLYDELIVPRICE = 5;
  protected static final int THISTIMEDELIVPRICE = 6;
  protected static final int QUOTESTARTDATE = 7;
  protected static final int QUOTEENDDATE = 8;
  protected static final int REMARKS = 9;
  protected static final int LINEORDER = 10;
  protected static final int CASEINCNUM = 11;
  protected static final int BOWLINCNUM = 12;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteLineSalesSumVORowImpl()
  {
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

  /**
   * 
   * Gets the attribute value for the calculated attribute InventoryItemId
   */
  public Number getInventoryItemId()
  {
    return (Number)getAttributeInternal(INVENTORYITEMID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InventoryItemId
   */
  public void setInventoryItemId(Number value)
  {
    setAttributeInternal(INVENTORYITEMID, value);
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
   * Gets the attribute value for the calculated attribute QuoteStartDate
   */
  public Date getQuoteStartDate()
  {
    return (Date)getAttributeInternal(QUOTESTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteStartDate
   */
  public void setQuoteStartDate(Date value)
  {
    setAttributeInternal(QUOTESTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute QuoteEndDate
   */
  public Date getQuoteEndDate()
  {
    return (Date)getAttributeInternal(QUOTEENDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute QuoteEndDate
   */
  public void setQuoteEndDate(Date value)
  {
    setAttributeInternal(QUOTEENDDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case QUOTELINEID:
        return getQuoteLineId();
      case INVENTORYITEMID:
        return getInventoryItemId();
      case INVENTORYITEMCODE:
        return getInventoryItemCode();
      case ITEMSHORTNAME:
        return getItemShortName();
      case QUOTEDIV:
        return getQuoteDiv();
      case USUALLYDELIVPRICE:
        return getUsuallyDelivPrice();
      case THISTIMEDELIVPRICE:
        return getThisTimeDelivPrice();
      case QUOTESTARTDATE:
        return getQuoteStartDate();
      case QUOTEENDDATE:
        return getQuoteEndDate();
      case REMARKS:
        return getRemarks();
      case LINEORDER:
        return getLineOrder();
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
      case INVENTORYITEMID:
        setInventoryItemId((Number)value);
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
      case THISTIMEDELIVPRICE:
        setThisTimeDelivPrice((String)value);
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