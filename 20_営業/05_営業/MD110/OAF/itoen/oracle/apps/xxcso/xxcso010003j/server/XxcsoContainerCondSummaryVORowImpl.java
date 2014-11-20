/*============================================================================
* ファイル名 : XxcsoContainerCondSummaryVORowImpl
* 概要説明   : SP専決明細テーブル情報取得ビュー行オブジェクトクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * SP専決明細テーブル情報取得ビュー行オブジェクトクラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContainerCondSummaryVORowImpl extends OAViewRowImpl 
{


  protected static final int SPDECISIONLINEID = 0;
  protected static final int SPCONTAINERNAME = 1;
  protected static final int DISCOUNTAMT = 2;
  protected static final int BMRATEPERSALESPRICE = 3;
  protected static final int BMAMOUNTPERSALESPRICE = 4;
  protected static final int BMCONVRATEPERSALESPRICE = 5;
  protected static final int BM1BMRATE = 6;
  protected static final int BM1BMAMOUNT = 7;
  protected static final int BM2BMRATE = 8;
  protected static final int BM2BMAMOUNT = 9;
  protected static final int BM3BMRATE = 10;
  protected static final int BM3BMAMOUNT = 11;
  protected static final int SORTCODE = 12;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContainerCondSummaryVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpDecisionLineId
   */
  public Number getSpDecisionLineId()
  {
    return (Number)getAttributeInternal(SPDECISIONLINEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpDecisionLineId
   */
  public void setSpDecisionLineId(Number value)
  {
    setAttributeInternal(SPDECISIONLINEID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpContainerName
   */
  public String getSpContainerName()
  {
    return (String)getAttributeInternal(SPCONTAINERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpContainerName
   */
  public void setSpContainerName(String value)
  {
    setAttributeInternal(SPCONTAINERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DiscountAmt
   */
  public String getDiscountAmt()
  {
    return (String)getAttributeInternal(DISCOUNTAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DiscountAmt
   */
  public void setDiscountAmt(String value)
  {
    setAttributeInternal(DISCOUNTAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BmRatePerSalesPrice
   */
  public String getBmRatePerSalesPrice()
  {
    return (String)getAttributeInternal(BMRATEPERSALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BmRatePerSalesPrice
   */
  public void setBmRatePerSalesPrice(String value)
  {
    setAttributeInternal(BMRATEPERSALESPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BmAmountPerSalesPrice
   */
  public String getBmAmountPerSalesPrice()
  {
    return (String)getAttributeInternal(BMAMOUNTPERSALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BmAmountPerSalesPrice
   */
  public void setBmAmountPerSalesPrice(String value)
  {
    setAttributeInternal(BMAMOUNTPERSALESPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BmConvRatePerSalesPrice
   */
  public String getBmConvRatePerSalesPrice()
  {
    return (String)getAttributeInternal(BMCONVRATEPERSALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BmConvRatePerSalesPrice
   */
  public void setBmConvRatePerSalesPrice(String value)
  {
    setAttributeInternal(BMCONVRATEPERSALESPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1BmRate
   */
  public String getBm1BmRate()
  {
    return (String)getAttributeInternal(BM1BMRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1BmRate
   */
  public void setBm1BmRate(String value)
  {
    setAttributeInternal(BM1BMRATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1BmAmount
   */
  public String getBm1BmAmount()
  {
    return (String)getAttributeInternal(BM1BMAMOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1BmAmount
   */
  public void setBm1BmAmount(String value)
  {
    setAttributeInternal(BM1BMAMOUNT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2BmRate
   */
  public String getBm2BmRate()
  {
    return (String)getAttributeInternal(BM2BMRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2BmRate
   */
  public void setBm2BmRate(String value)
  {
    setAttributeInternal(BM2BMRATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2BmAmount
   */
  public String getBm2BmAmount()
  {
    return (String)getAttributeInternal(BM2BMAMOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2BmAmount
   */
  public void setBm2BmAmount(String value)
  {
    setAttributeInternal(BM2BMAMOUNT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3BmRate
   */
  public String getBm3BmRate()
  {
    return (String)getAttributeInternal(BM3BMRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3BmRate
   */
  public void setBm3BmRate(String value)
  {
    setAttributeInternal(BM3BMRATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3BmAmount
   */
  public String getBm3BmAmount()
  {
    return (String)getAttributeInternal(BM3BMAMOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3BmAmount
   */
  public void setBm3BmAmount(String value)
  {
    setAttributeInternal(BM3BMAMOUNT, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONLINEID:
        return getSpDecisionLineId();
      case SPCONTAINERNAME:
        return getSpContainerName();
      case DISCOUNTAMT:
        return getDiscountAmt();
      case BMRATEPERSALESPRICE:
        return getBmRatePerSalesPrice();
      case BMAMOUNTPERSALESPRICE:
        return getBmAmountPerSalesPrice();
      case BMCONVRATEPERSALESPRICE:
        return getBmConvRatePerSalesPrice();
      case BM1BMRATE:
        return getBm1BmRate();
      case BM1BMAMOUNT:
        return getBm1BmAmount();
      case BM2BMRATE:
        return getBm2BmRate();
      case BM2BMAMOUNT:
        return getBm2BmAmount();
      case BM3BMRATE:
        return getBm3BmRate();
      case BM3BMAMOUNT:
        return getBm3BmAmount();
      case SORTCODE:
        return getSortCode();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONLINEID:
        setSpDecisionLineId((Number)value);
        return;
      case SPCONTAINERNAME:
        setSpContainerName((String)value);
        return;
      case DISCOUNTAMT:
        setDiscountAmt((String)value);
        return;
      case BMRATEPERSALESPRICE:
        setBmRatePerSalesPrice((String)value);
        return;
      case BMAMOUNTPERSALESPRICE:
        setBmAmountPerSalesPrice((String)value);
        return;
      case BMCONVRATEPERSALESPRICE:
        setBmConvRatePerSalesPrice((String)value);
        return;
      case BM1BMRATE:
        setBm1BmRate((String)value);
        return;
      case BM1BMAMOUNT:
        setBm1BmAmount((String)value);
        return;
      case BM2BMRATE:
        setBm2BmRate((String)value);
        return;
      case BM2BMAMOUNT:
        setBm2BmAmount((String)value);
        return;
      case BM3BMRATE:
        setBm3BmRate((String)value);
        return;
      case BM3BMAMOUNT:
        setBm3BmAmount((String)value);
        return;
      case SORTCODE:
        setSortCode((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SortCode
   */
  public String getSortCode()
  {
    return (String)getAttributeInternal(SORTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SortCode
   */
  public void setSortCode(String value)
  {
    setAttributeInternal(SORTCODE, value);
  }
}