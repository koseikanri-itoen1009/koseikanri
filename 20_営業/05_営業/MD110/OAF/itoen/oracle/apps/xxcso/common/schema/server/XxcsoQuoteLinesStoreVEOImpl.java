/*============================================================================
* ファイル名 : XxcsoQuoteLinesStoreVEOImpl
* 概要説明   : 見積明細（帳合用）ビューエンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-06 1.0  SCS及川領    新規作成
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
import oracle.jdbc.OracleCallableStatement;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import java.sql.SQLException;
import com.sun.java.util.collections.Iterator;

/*******************************************************************************
 * 見積明細（帳合用）ビューのエンティティクラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteLinesStoreVEOImpl extends OAPlsqlEntityImpl 
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
  protected static final int SORTCODE = 25;
  protected static final int SELECTFLAG = 26;
  protected static final int XXCSOQUOTEHEADERSEO = 27;














  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteLinesStoreVEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoQuoteLinesStoreVEO");
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
    EntityDefImpl lineDef = XxcsoQuoteLinesStoreVEOImpl.getDefinitionObject();
    Iterator lineIt = lineDef.getAllEntityInstancesIterator(txn);

    int minValue = 0;
    
    while( lineIt.hasNext() )
    {
      XxcsoQuoteLinesStoreVEOImpl lineEo 
        = (XxcsoQuoteLinesStoreVEOImpl)lineIt.next();
      int quoteLineId = lineEo.getQuoteLineId().intValue();

      if ( minValue > quoteLineId )
      {
        minValue = quoteLineId;
      }

    }

    minValue--;

    XxcsoUtils.debug(txn, "new id:" + minValue);
    setQuoteLineId(new Number(minValue));
    XxcsoUtils.debug(txn, "QuoteLineId:" + getQuoteLineId());

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

    // 新規作成の場合は、ヘッダーＩＤを取得します
    EntityDefImpl headerEntityDef
      = XxcsoQuoteHeadersEOImpl.getDefinitionObject();

    Iterator headerEoIt
      = headerEntityDef.getAllEntityInstancesIterator(getOADBTransaction());

    Number quoteHeaderId = null;

    while ( headerEoIt.hasNext() )
    {
      XxcsoQuoteHeadersEOImpl headerEo
        = (XxcsoQuoteHeadersEOImpl)headerEoIt.next();

      // 新規作成の場合のみヘッダIDを設定します。
      if ( headerEo.getEntityState() == STATUS_NEW )
      {
        quoteHeaderId = headerEo.getQuoteHeaderId();
        break;
      }
    }


    if( "Y".equals(getSelectFlag()) &&
        getReferenceQuoteLineId() == null )
    {
      setQuoteHeaderId(quoteHeaderId);

      // 登録する直前でシーケンス値を払い出します。
      Number quoteLineId
        = getOADBTransaction().getSequenceValue("XXCSO_QUOTE_LINES_S01");

      setReferenceQuoteLineId(getQuoteLineId());
      setQuoteLineId(quoteLineId);
    }

    OracleCallableStatement stmt = null;

    //見積明細登録用ファンクションをcall
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append(" xxcso_017002j_pkg.set_quote_lines(");
      sql.append(" :1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13);");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);
      // パラメータの設定
      stmt.setString(1, getSelectFlag());
      stmt.setNUMBER(2, getQuoteLineId());
      stmt.setNUMBER(3, getReferenceQuoteLineId());
      stmt.setString(4, getQuotationPrice());
      stmt.setString(5, getSalesDiscountPrice());
      stmt.setString(6, getUsuallNetPrice());
      stmt.setString(7, getThisTimeNetPrice());
      stmt.setString(8, getAmountOfMargin());
      stmt.setString(9, getMarginRate());
      stmt.setDATE(10, getQuoteStartDate());
      stmt.setString(11, getRemarks());
      stmt.setString(12, getLineOrder());
      stmt.setNUMBER(13, getQuoteHeaderId());
      
      XxcsoUtils.debug(txn, "getSelectFlag:"+getSelectFlag());
      XxcsoUtils.debug(txn, "getQuoteLineId:"+getQuoteLineId());
      XxcsoUtils.debug(
        txn, "getReferenceQuoteLineId:"+getReferenceQuoteLineId());
      XxcsoUtils.debug(txn, "getQuotationPrice:"+getQuotationPrice());
      XxcsoUtils.debug(txn, "getSalesDiscountPrice:"+getSalesDiscountPrice());
      XxcsoUtils.debug(txn, "getUsuallNetPrice:"+getUsuallNetPrice());
      XxcsoUtils.debug(txn, "getThisTimeNetPrice:"+getThisTimeNetPrice());
      XxcsoUtils.debug(txn, "getAmountOfMargin:"+getAmountOfMargin());
      XxcsoUtils.debug(txn, "getMarginRate:"+getMarginRate());
      XxcsoUtils.debug(txn, "getQuoteStartDate:"+getQuoteStartDate());
      XxcsoUtils.debug(txn, "getRemarks:"+getRemarks());
      XxcsoUtils.debug(txn, "getLineOrder:"+getLineOrder());
      XxcsoUtils.debug(txn, "getQuoteHeaderId:"+getQuoteHeaderId());

        XxcsoUtils.debug(txn, "execute stored start");
      stmt.execute();
        XxcsoUtils.debug(txn, "execute stored end");

      populateAttribute(QUOTEHEADERID, quoteHeaderId);
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoConstants.TOKEN_VALUE_REGIST
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException sqle )
      {
        XxcsoUtils.unexpected(txn, sqle);
      }
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

    // 新規作成の場合は、ヘッダーＩＤを取得します
    if( "Y".equals(getSelectFlag()) &&
        getReferenceQuoteLineId() == null )
    {
      // 登録する直前でシーケンス値を払い出します。
      Number quoteLineId
        = getOADBTransaction().getSequenceValue("XXCSO_QUOTE_LINES_S01");

      setReferenceQuoteLineId(getQuoteLineId());
      setQuoteLineId(quoteLineId);
    }

    OracleCallableStatement stmt = null;

    //見積明細登録用ファンクションをcall
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append(" xxcso_017002j_pkg.set_quote_lines(");
      sql.append(" :1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13);");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);
      // パラメータの設定
      stmt.setString(1, getSelectFlag());
      stmt.setNUMBER(2, getQuoteLineId());
      stmt.setNUMBER(3, getReferenceQuoteLineId());
      stmt.setString(4, getQuotationPrice());
      stmt.setString(5, getSalesDiscountPrice());
      stmt.setString(6, getUsuallNetPrice());
      stmt.setString(7, getThisTimeNetPrice());
      stmt.setString(8, getAmountOfMargin());
      stmt.setString(9, getMarginRate());
      stmt.setDATE(10, getQuoteStartDate());
      stmt.setString(11, getRemarks());
      stmt.setString(12, getLineOrder());
      stmt.setNUMBER(13, getQuoteHeaderId());
      
      XxcsoUtils.debug(txn, "getSelectFlag:"+getSelectFlag());
      XxcsoUtils.debug(txn, "getQuoteLineId:"+getQuoteLineId());
      XxcsoUtils.debug(
        txn, "getReferenceQuoteLineId:"+getReferenceQuoteLineId());
      XxcsoUtils.debug(txn, "getQuotationPrice:"+getQuotationPrice());
      XxcsoUtils.debug(txn, "getSalesDiscountPrice:"+getSalesDiscountPrice());
      XxcsoUtils.debug(txn, "getUsuallNetPrice:"+getUsuallNetPrice());
      XxcsoUtils.debug(txn, "getThisTimeNetPrice:"+getThisTimeNetPrice());
      XxcsoUtils.debug(txn, "getAmountOfMargin:"+getAmountOfMargin());
      XxcsoUtils.debug(txn, "getMarginRate:"+getMarginRate());
      XxcsoUtils.debug(txn, "getQuoteStartDate:"+getQuoteStartDate());
      XxcsoUtils.debug(txn, "getRemarks:"+getRemarks());
      XxcsoUtils.debug(txn, "getLineOrder:"+getLineOrder());
      XxcsoUtils.debug(txn, "getQuoteHeaderId:"+getQuoteHeaderId());

        XxcsoUtils.debug(txn, "execute stored start");
      stmt.execute();
        XxcsoUtils.debug(txn, "execute stored end");

    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoConstants.TOKEN_VALUE_REGIST
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException sqle )
      {
        XxcsoUtils.unexpected(txn, sqle);
      }
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * レコード削除処理です。
   * 呼ばれないはずなので、空振りします。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.deleteRow
   *****************************************************************************
   */
  public void deleteRow()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");
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
  public String getQuotationPrice()
  {
    return (String)getAttributeInternal(QUOTATIONPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuotationPrice
   */
  public void setQuotationPrice(String value)
  {
    setAttributeInternal(QUOTATIONPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for SalesDiscountPrice, using the alias name SalesDiscountPrice
   */
  public String getSalesDiscountPrice()
  {
    return (String)getAttributeInternal(SALESDISCOUNTPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesDiscountPrice
   */
  public void setSalesDiscountPrice(String value)
  {
    setAttributeInternal(SALESDISCOUNTPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for UsuallNetPrice, using the alias name UsuallNetPrice
   */
  public String getUsuallNetPrice()
  {
    return (String)getAttributeInternal(USUALLNETPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for UsuallNetPrice
   */
  public void setUsuallNetPrice(String value)
  {
    setAttributeInternal(USUALLNETPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for ThisTimeNetPrice, using the alias name ThisTimeNetPrice
   */
  public String getThisTimeNetPrice()
  {
    return (String)getAttributeInternal(THISTIMENETPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ThisTimeNetPrice
   */
  public void setThisTimeNetPrice(String value)
  {
    setAttributeInternal(THISTIMENETPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for AmountOfMargin, using the alias name AmountOfMargin
   */
  public String getAmountOfMargin()
  {
    return (String)getAttributeInternal(AMOUNTOFMARGIN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for AmountOfMargin
   */
  public void setAmountOfMargin(String value)
  {
    setAttributeInternal(AMOUNTOFMARGIN, value);
  }

  /**
   * 
   * Gets the attribute value for MarginRate, using the alias name MarginRate
   */
  public String getMarginRate()
  {
    return (String)getAttributeInternal(MARGINRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for MarginRate
   */
  public void setMarginRate(String value)
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
   * Gets the attribute value for SortCode, using the alias name SortCode
   */
  public Number getSortCode()
  {
    return (Number)getAttributeInternal(SORTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SortCode
   */
  public void setSortCode(Number value)
  {
    setAttributeInternal(SORTCODE, value);
  }

  /**
   * 
   * Gets the attribute value for SelectFlag, using the alias name SelectFlag
   */
  public String getSelectFlag()
  {
    return (String)getAttributeInternal(SELECTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SelectFlag
   */
  public void setSelectFlag(String value)
  {
    setAttributeInternal(SELECTFLAG, value);
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
      case SORTCODE:
        return getSortCode();
      case SELECTFLAG:
        return getSelectFlag();
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
        setQuotationPrice((String)value);
        return;
      case SALESDISCOUNTPRICE:
        setSalesDiscountPrice((String)value);
        return;
      case USUALLNETPRICE:
        setUsuallNetPrice((String)value);
        return;
      case THISTIMENETPRICE:
        setThisTimeNetPrice((String)value);
        return;
      case AMOUNTOFMARGIN:
        setAmountOfMargin((String)value);
        return;
      case MARGINRATE:
        setMarginRate((String)value);
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
      case SORTCODE:
        setSortCode((Number)value);
        return;
      case SELECTFLAG:
        setSelectFlag((String)value);
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
  public static Key createPrimaryKey(Number quoteLineId, Number quoteHeaderId)
  {
    return new Key(new Object[] {quoteLineId, quoteHeaderId});
  }














}