/*============================================================================
* ファイル名 : XxcsoQuoteLinesSalesVEOImpl
* 概要説明   : 見積明細ビューエンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAPlsqlEntityImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.Key;

import oracle.jbo.AttributeList;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoCustomDmlExecUtils;
import com.sun.java.util.collections.Iterator;
import java.sql.SQLException;

/*******************************************************************************
 * 見積明細ビューのエンティティクラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteLinesSalesVEOImpl extends OAPlsqlEntityImpl 
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
  protected static final int XXCSOQUOTEHEADERSEO = 29;


















  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteLinesSalesVEOImpl()
  {
  }

  /**
   * 
   * Retrieves the definition object for this instance class.
   */
  public static synchronized EntityDefImpl getDefinitionObject()
  {
    if (mDefinitionObject == null)
    {
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoQuoteLinesSalesVEO");
    }
    return mDefinitionObject;
  }














  /*****************************************************************************
   * エンティティの作成処理です。
   * @param list 属性リスト
   *****************************************************************************
   */
  public void create(AttributeList list)
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    super.create(list);
    
    // 仮の値を設定します。
    EntityDefImpl lineDef = XxcsoQuoteLinesSalesVEOImpl.getDefinitionObject();
    Iterator lineIt = lineDef.getAllEntityInstancesIterator(txn);

    int minValue = 0;
    
    while( lineIt.hasNext() )
    {
      XxcsoQuoteLinesSalesVEOImpl lineEo 
        = (XxcsoQuoteLinesSalesVEOImpl)lineIt.next();
      int quoteLineId = lineEo.getQuoteLineId().intValue();

      if ( minValue > quoteLineId )
      {
        minValue = quoteLineId;
      }
    }

    minValue--;

    XxcsoUtils.debug(txn, "new id:" + minValue);
    
    setQuoteLineId(new Number(minValue));
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * レコードロック処理です。
   * 子テーブルはロックしないので空振りします。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.lockRow
   *****************************************************************************
   */
  public void lockRow()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "[END]");
  }
  
  /*****************************************************************************
   * レコード作成処理です。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.insertRow
   *****************************************************************************
   */
  public void insertRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    replacePrice();

    EntityDefImpl headerEntityDef
      = XxcsoQuoteHeadersEOImpl.getDefinitionObject();

    Iterator headerEoIt
      = headerEntityDef.getAllEntityInstancesIterator(getOADBTransaction());

    Number quoteHeaderId = null;
    
    while ( headerEoIt.hasNext() )
    {
      XxcsoQuoteHeadersEOImpl headerEo
        = (XxcsoQuoteHeadersEOImpl)headerEoIt.next();

      if ( headerEo.getEntityState() == OAPlsqlEntityImpl.STATUS_NEW )
      {
        // 新規作成の場合のみヘッダIDを設定します。
        quoteHeaderId = headerEo.getQuoteHeaderId();
        setQuoteHeaderId(quoteHeaderId);
        break;
      }
    }

    // 登録する直前でシーケンス値を払い出します。
    Number quoteLineId
      = getOADBTransaction().getSequenceValue("XXCSO_QUOTE_LINES_S01");

    setQuoteLineId(quoteLineId);

    try
    {
      XxcsoCustomDmlExecUtils.insertRow(
        txn
       ,"xxcso_quote_lines"
       ,this
       ,XxcsoQuoteLinesSalesVEOImpl.getDefinitionObject()
      );
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw XxcsoMessage.createSqlErrorMessage(
        e,
        XxcsoConstants.TOKEN_VALUE_QUOTE_LINE +
          XxcsoConstants.TOKEN_VALUE_DELIMITER1 +
          XxcsoConstants.TOKEN_VALUE_CREATE
      );
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * レコード更新処理です。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.updateRow
   *****************************************************************************
   */
  public void updateRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    replacePrice();
    
    try
    {
      XxcsoCustomDmlExecUtils.updateRow(
        txn
       ,"xxcso_quote_lines"
       ,this
       ,XxcsoQuoteLinesSalesVEOImpl.getDefinitionObject()
      );
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw XxcsoMessage.createSqlErrorMessage(
        e,
        XxcsoConstants.TOKEN_VALUE_QUOTE_LINE +
          XxcsoConstants.TOKEN_VALUE_DELIMITER1 +
          XxcsoConstants.TOKEN_VALUE_UPDATE
      );
    }
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * レコード削除処理です。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.deleteRow
   *****************************************************************************
   */
  public void deleteRow()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    try
    {
      XxcsoCustomDmlExecUtils.deleteRow(
        txn
       ,"xxcso_quote_lines"
       ,this
       ,XxcsoQuoteLinesSalesVEOImpl.getDefinitionObject()
      );
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw XxcsoMessage.createSqlErrorMessage(
        e,
        XxcsoConstants.TOKEN_VALUE_QUOTE_LINE +
          XxcsoConstants.TOKEN_VALUE_DELIMITER1 +
          XxcsoConstants.TOKEN_VALUE_DELETE
        );
    }
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 金額データ置き換え処理
   *****************************************************************************
   */
  private void replacePrice()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    if ( getUsuallyDelivPrice() != null &&
         ! "".equals(getUsuallyDelivPrice())
       )
    {
      setUsuallyDelivPrice(getUsuallyDelivPrice().replaceAll(",",""));
    }
    if ( getUsuallyStoreSalePrice() != null &&
         ! "".equals(getUsuallyStoreSalePrice())
       )
    {
      setUsuallyStoreSalePrice(getUsuallyStoreSalePrice().replaceAll(",",""));
    }
    if ( getThisTimeDelivPrice() != null &&
         ! "".equals(getThisTimeDelivPrice())
       )
    {
      setThisTimeDelivPrice(getThisTimeDelivPrice().replaceAll(",",""));
    }
    if ( getThisTimeStoreSalePrice() != null &&
         ! "".equals(getThisTimeStoreSalePrice())
       )
    {
      setThisTimeStoreSalePrice(getThisTimeStoreSalePrice().replaceAll(",",""));
    }

    XxcsoUtils.debug(txn, "[END]");
  }



  /**
   * 
   * Gets the attribute value for QuoteLineId, using the alias name QuoteLineId
   */
  public Number getQuoteLineId()
  {
    return (Number)getAttributeInternal(QUOTELINEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuoteLineId
   */
  public void setQuoteLineId(Number value)
  {
    setAttributeInternal(QUOTELINEID, value);
  }

  /**
   * 
   * Gets the attribute value for QuoteHeaderId, using the alias name QuoteHeaderId
   */
  public Number getQuoteHeaderId()
  {
    return (Number)getAttributeInternal(QUOTEHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuoteHeaderId
   */
  public void setQuoteHeaderId(Number value)
  {
    setAttributeInternal(QUOTEHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for ReferenceQuoteLineId, using the alias name ReferenceQuoteLineId
   */
  public Number getReferenceQuoteLineId()
  {
    return (Number)getAttributeInternal(REFERENCEQUOTELINEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ReferenceQuoteLineId
   */
  public void setReferenceQuoteLineId(Number value)
  {
    setAttributeInternal(REFERENCEQUOTELINEID, value);
  }

  /**
   * 
   * Gets the attribute value for InventoryItemId, using the alias name InventoryItemId
   */
  public Number getInventoryItemId()
  {
    return (Number)getAttributeInternal(INVENTORYITEMID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InventoryItemId
   */
  public void setInventoryItemId(Number value)
  {
    setAttributeInternal(INVENTORYITEMID, value);
  }

  /**
   * 
   * Gets the attribute value for QuoteDiv, using the alias name QuoteDiv
   */
  public String getQuoteDiv()
  {
    return (String)getAttributeInternal(QUOTEDIV);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuoteDiv
   */
  public void setQuoteDiv(String value)
  {
    setAttributeInternal(QUOTEDIV, value);
  }

  /**
   * 
   * Gets the attribute value for UsuallyDelivPrice, using the alias name UsuallyDelivPrice
   */
  public String getUsuallyDelivPrice()
  {
    return (String)getAttributeInternal(USUALLYDELIVPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for UsuallyDelivPrice
   */
  public void setUsuallyDelivPrice(String value)
  {
    setAttributeInternal(USUALLYDELIVPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for UsuallyStoreSalePrice, using the alias name UsuallyStoreSalePrice
   */
  public String getUsuallyStoreSalePrice()
  {
    return (String)getAttributeInternal(USUALLYSTORESALEPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for UsuallyStoreSalePrice
   */
  public void setUsuallyStoreSalePrice(String value)
  {
    setAttributeInternal(USUALLYSTORESALEPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for ThisTimeDelivPrice, using the alias name ThisTimeDelivPrice
   */
  public String getThisTimeDelivPrice()
  {
    return (String)getAttributeInternal(THISTIMEDELIVPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ThisTimeDelivPrice
   */
  public void setThisTimeDelivPrice(String value)
  {
    setAttributeInternal(THISTIMEDELIVPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for ThisTimeStoreSalePrice, using the alias name ThisTimeStoreSalePrice
   */
  public String getThisTimeStoreSalePrice()
  {
    return (String)getAttributeInternal(THISTIMESTORESALEPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ThisTimeStoreSalePrice
   */
  public void setThisTimeStoreSalePrice(String value)
  {
    setAttributeInternal(THISTIMESTORESALEPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for QuotationPrice, using the alias name QuotationPrice
   */
  public Number getQuotationPrice()
  {
    return (Number)getAttributeInternal(QUOTATIONPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuotationPrice
   */
  public void setQuotationPrice(Number value)
  {
    setAttributeInternal(QUOTATIONPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for SalesDiscountPrice, using the alias name SalesDiscountPrice
   */
  public Number getSalesDiscountPrice()
  {
    return (Number)getAttributeInternal(SALESDISCOUNTPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesDiscountPrice
   */
  public void setSalesDiscountPrice(Number value)
  {
    setAttributeInternal(SALESDISCOUNTPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for UsuallNetPrice, using the alias name UsuallNetPrice
   */
  public Number getUsuallNetPrice()
  {
    return (Number)getAttributeInternal(USUALLNETPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for UsuallNetPrice
   */
  public void setUsuallNetPrice(Number value)
  {
    setAttributeInternal(USUALLNETPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for ThisTimeNetPrice, using the alias name ThisTimeNetPrice
   */
  public Number getThisTimeNetPrice()
  {
    return (Number)getAttributeInternal(THISTIMENETPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ThisTimeNetPrice
   */
  public void setThisTimeNetPrice(Number value)
  {
    setAttributeInternal(THISTIMENETPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for AmountOfMargin, using the alias name AmountOfMargin
   */
  public Number getAmountOfMargin()
  {
    return (Number)getAttributeInternal(AMOUNTOFMARGIN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for AmountOfMargin
   */
  public void setAmountOfMargin(Number value)
  {
    setAttributeInternal(AMOUNTOFMARGIN, value);
  }

  /**
   * 
   * Gets the attribute value for MarginRate, using the alias name MarginRate
   */
  public Number getMarginRate()
  {
    return (Number)getAttributeInternal(MARGINRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for MarginRate
   */
  public void setMarginRate(Number value)
  {
    setAttributeInternal(MARGINRATE, value);
  }

  /**
   * 
   * Gets the attribute value for QuoteStartDate, using the alias name QuoteStartDate
   */
  public Date getQuoteStartDate()
  {
    return (Date)getAttributeInternal(QUOTESTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuoteStartDate
   */
  public void setQuoteStartDate(Date value)
  {
    setAttributeInternal(QUOTESTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for QuoteEndDate, using the alias name QuoteEndDate
   */
  public Date getQuoteEndDate()
  {
    return (Date)getAttributeInternal(QUOTEENDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuoteEndDate
   */
  public void setQuoteEndDate(Date value)
  {
    setAttributeInternal(QUOTEENDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for Remarks, using the alias name Remarks
   */
  public String getRemarks()
  {
    return (String)getAttributeInternal(REMARKS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Remarks
   */
  public void setRemarks(String value)
  {
    setAttributeInternal(REMARKS, value);
  }

  /**
   * 
   * Gets the attribute value for LineOrder, using the alias name LineOrder
   */
  public String getLineOrder()
  {
    return (String)getAttributeInternal(LINEORDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LineOrder
   */
  public void setLineOrder(String value)
  {
    setAttributeInternal(LINEORDER, value);
  }

  /**
   * 
   * Gets the attribute value for BusinessPrice, using the alias name BusinessPrice
   */
  public Number getBusinessPrice()
  {
    return (Number)getAttributeInternal(BUSINESSPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BusinessPrice
   */
  public void setBusinessPrice(Number value)
  {
    setAttributeInternal(BUSINESSPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for CreatedBy, using the alias name CreatedBy
   */
  public Number getCreatedBy()
  {
    return (Number)getAttributeInternal(CREATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreatedBy
   */
  public void setCreatedBy(Number value)
  {
    setAttributeInternal(CREATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for CreationDate, using the alias name CreationDate
   */
  public Date getCreationDate()
  {
    return (Date)getAttributeInternal(CREATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreationDate
   */
  public void setCreationDate(Date value)
  {
    setAttributeInternal(CREATIONDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdatedBy, using the alias name LastUpdatedBy
   */
  public Number getLastUpdatedBy()
  {
    return (Number)getAttributeInternal(LASTUPDATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdatedBy
   */
  public void setLastUpdatedBy(Number value)
  {
    setAttributeInternal(LASTUPDATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdateDate, using the alias name LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    setAttributeInternal(LASTUPDATEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdateLogin, using the alias name LastUpdateLogin
   */
  public Number getLastUpdateLogin()
  {
    return (Number)getAttributeInternal(LASTUPDATELOGIN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateLogin
   */
  public void setLastUpdateLogin(Number value)
  {
    setAttributeInternal(LASTUPDATELOGIN, value);
  }

  /**
   * 
   * Gets the attribute value for RequestId, using the alias name RequestId
   */
  public Number getRequestId()
  {
    return (Number)getAttributeInternal(REQUESTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for RequestId
   */
  public void setRequestId(Number value)
  {
    setAttributeInternal(REQUESTID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramApplicationId, using the alias name ProgramApplicationId
   */
  public Number getProgramApplicationId()
  {
    return (Number)getAttributeInternal(PROGRAMAPPLICATIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramApplicationId
   */
  public void setProgramApplicationId(Number value)
  {
    setAttributeInternal(PROGRAMAPPLICATIONID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramId, using the alias name ProgramId
   */
  public Number getProgramId()
  {
    return (Number)getAttributeInternal(PROGRAMID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramId
   */
  public void setProgramId(Number value)
  {
    setAttributeInternal(PROGRAMID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramUpdateDate, using the alias name ProgramUpdateDate
   */
  public Date getProgramUpdateDate()
  {
    return (Date)getAttributeInternal(PROGRAMUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramUpdateDate
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
      case XXCSOQUOTEHEADERSEO:
        return getXxcsoQuoteHeadersEO();
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
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }


  /**
   * 
   * Gets the associated entity XxcsoQuoteHeadersEOImpl
   */
  public XxcsoQuoteHeadersEOImpl getXxcsoQuoteHeadersEO()
  {
    return (XxcsoQuoteHeadersEOImpl)getAttributeInternal(XXCSOQUOTEHEADERSEO);
  }

  /**
   * 
   * Sets <code>value</code> as the associated entity XxcsoQuoteHeadersEOImpl
   */
  public void setXxcsoQuoteHeadersEO(XxcsoQuoteHeadersEOImpl value)
  {
    setAttributeInternal(XXCSOQUOTEHEADERSEO, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number quoteLineId)
  {
    return new Key(new Object[] {quoteLineId});
  }























}