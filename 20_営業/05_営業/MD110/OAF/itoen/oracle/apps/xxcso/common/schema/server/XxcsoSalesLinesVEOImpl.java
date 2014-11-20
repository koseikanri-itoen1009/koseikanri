/*============================================================================
* ファイル名 : XxcsoSalesLinesVEOImpl
* 概要説明   : 商談決定情報明細エンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS小川浩     新規作成
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
 * 商談決定情報明細のエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesLinesVEOImpl extends OAPlsqlEntityImpl 
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
  protected static final int XXCSOSALESHEADERSEO = 24;














  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesLinesVEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoSalesLinesVEO");
    }
    return mDefinitionObject;
  }















  /*****************************************************************************
   * エンティティの作成処理です。
   * @param list 属性リスト
   * @see oracle.apps.fnd.framework.server.OAEntityImpl.create
   *****************************************************************************
   */
  public void create(AttributeList list)
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    super.create(list);
    
    // 仮の値を設定します。
    EntityDefImpl lineDef = XxcsoSalesLinesVEOImpl.getDefinitionObject();
    Iterator lineIt = lineDef.getAllEntityInstancesIterator(txn);

    int minValue = 0;
    
    while( lineIt.hasNext() )
    {
      XxcsoSalesLinesVEOImpl lineEo = (XxcsoSalesLinesVEOImpl)lineIt.next();
      int salesLineId = lineEo.getSalesLineId().intValue();

      if ( minValue > salesLineId )
      {
        minValue = salesLineId;
      }
    }

    minValue--;

    XxcsoUtils.debug(txn, "new id:" + minValue);
    
    setSalesLineId(new Number(minValue));
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコードロック処理です。
   * ベーステーブルがビューなので空振りします。
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

    if ( ! XxcsoSalesRequestEOImpl.isRequestMode(txn) )
    {
      // 承認依頼以外の場合は、通知フラグをNに設定する
      setNotifyFlag("N");      
    }

    EntityDefImpl headerDef = XxcsoSalesHeadersEOImpl.getDefinitionObject();
    Iterator headerIt = headerDef.getAllEntityInstancesIterator(txn);

    while ( headerIt.hasNext() )
    {
      XxcsoSalesHeadersEOImpl headerEo
        = (XxcsoSalesHeadersEOImpl)headerIt.next();

      if ( headerEo.getEntityState() == STATUS_NEW )
      {
        setSalesHeaderId(headerEo.getSalesHeaderId());
        break;
      }
    }
    
    // 登録する直前でシーケンス値を払い出します。
    Number salesLineId = txn.getSequenceValue("XXCSO_SALES_LINES_S01");

    setSalesLineId(salesLineId);

    try
    {
      XxcsoCustomDmlExecUtils.insertRow(
        txn
       ,"xxcso_sales_lines"
       ,this
       ,XxcsoSalesLinesVEOImpl.getDefinitionObject()
      );
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw XxcsoMessage.createSqlErrorMessage(
        e,
        XxcsoConstants.TOKEN_VALUE_SALES_LINE +
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
    
    if ( ! XxcsoSalesRequestEOImpl.isRequestMode(txn) )
    {
      // 承認依頼以外の場合は、通知フラグをNに設定する
      setNotifyFlag("N");      
    }

    try
    {
      XxcsoCustomDmlExecUtils.updateRow(
        txn
       ,"xxcso_sales_lines"
       ,this
       ,XxcsoSalesLinesVEOImpl.getDefinitionObject()
      );
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw XxcsoMessage.createSqlErrorMessage(
        e,
        XxcsoConstants.TOKEN_VALUE_SALES_LINE +
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
       ,"xxcso_sales_lines"
       ,this
       ,XxcsoSalesLinesVEOImpl.getDefinitionObject()
      );
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw XxcsoMessage.createSqlErrorMessage(
        e,
        XxcsoConstants.TOKEN_VALUE_SALES_LINE +
          XxcsoConstants.TOKEN_VALUE_DELIMITER1 +
          XxcsoConstants.TOKEN_VALUE_DELETE
        );
    }
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコード変更確認処理です。
   *****************************************************************************
   */
  public static boolean isModified(OADBTransaction txn)
  {
    XxcsoUtils.debug(txn, "[START]");

    EntityDefImpl def = XxcsoSalesLinesVEOImpl.getDefinitionObject();
    Iterator it = def.getAllEntityInstancesIterator(txn);

    boolean modified = false;

    while ( it.hasNext() )
    {
      XxcsoSalesLinesVEOImpl eo = (XxcsoSalesLinesVEOImpl)it.next();
      if ( eo.getEntityState() != STATUS_UNMODIFIED &&
           eo.getEntityState() != STATUS_INITIALIZED
         )
      {
        XxcsoUtils.debug(
          txn
         ,"lineEo modified" +
            " id:" + eo.getSalesLineId() +
            " status:" + eo.getEntityState()
        );
        modified = true;
        break;
      }
    }

    XxcsoUtils.debug(txn, "[END]");

    return modified;
  }


  /*****************************************************************************
   * 金額データ置き換え処理
   *****************************************************************************
   */
  private void replacePrice()
  {
    if ( getDelivPrice() != null &&
         ! "".equals(getDelivPrice())
       )
    {
      setDelivPrice(getDelivPrice().replaceAll(",",""));
    }
    if ( getStoreSalesPrice() != null &&
         ! "".equals(getStoreSalesPrice())
       )
    {
      setStoreSalesPrice(getStoreSalesPrice().replaceAll(",",""));
    }
    if ( getStoreSalesPriceIncTax() != null &&
         ! "".equals(getStoreSalesPriceIncTax())
       )
    {
      setStoreSalesPriceIncTax(getStoreSalesPriceIncTax().replaceAll(",",""));
    }
    if ( getQuotationPrice() != null &&
         ! "".equals(getQuotationPrice())
       )
    {
      setQuotationPrice(getQuotationPrice().replaceAll(",",""));
    }
  }


  /**
   * 
   * Gets the attribute value for SalesLineId, using the alias name SalesLineId
   */
  public Number getSalesLineId()
  {
    return (Number)getAttributeInternal(SALESLINEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesLineId
   */
  public void setSalesLineId(Number value)
  {
    setAttributeInternal(SALESLINEID, value);
  }

  /**
   * 
   * Gets the attribute value for SalesHeaderId, using the alias name SalesHeaderId
   */
  public Number getSalesHeaderId()
  {
    return (Number)getAttributeInternal(SALESHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesHeaderId
   */
  public void setSalesHeaderId(Number value)
  {
    setAttributeInternal(SALESHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for QuoteNumber, using the alias name QuoteNumber
   */
  public String getQuoteNumber()
  {
    return (String)getAttributeInternal(QUOTENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuoteNumber
   */
  public void setQuoteNumber(String value)
  {
    setAttributeInternal(QUOTENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for QuoteRevisionNumber, using the alias name QuoteRevisionNumber
   */
  public Number getQuoteRevisionNumber()
  {
    return (Number)getAttributeInternal(QUOTEREVISIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuoteRevisionNumber
   */
  public void setQuoteRevisionNumber(Number value)
  {
    setAttributeInternal(QUOTEREVISIONNUMBER, value);
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
   * Gets the attribute value for SalesClassCode, using the alias name SalesClassCode
   */
  public String getSalesClassCode()
  {
    return (String)getAttributeInternal(SALESCLASSCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesClassCode
   */
  public void setSalesClassCode(String value)
  {
    setAttributeInternal(SALESCLASSCODE, value);
  }

  /**
   * 
   * Gets the attribute value for SalesAdoptClassCode, using the alias name SalesAdoptClassCode
   */
  public String getSalesAdoptClassCode()
  {
    return (String)getAttributeInternal(SALESADOPTCLASSCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesAdoptClassCode
   */
  public void setSalesAdoptClassCode(String value)
  {
    setAttributeInternal(SALESADOPTCLASSCODE, value);
  }

  /**
   * 
   * Gets the attribute value for SalesAreaCode, using the alias name SalesAreaCode
   */
  public String getSalesAreaCode()
  {
    return (String)getAttributeInternal(SALESAREACODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesAreaCode
   */
  public void setSalesAreaCode(String value)
  {
    setAttributeInternal(SALESAREACODE, value);
  }

  /**
   * 
   * Gets the attribute value for SalesScheduleDate, using the alias name SalesScheduleDate
   */
  public Date getSalesScheduleDate()
  {
    return (Date)getAttributeInternal(SALESSCHEDULEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesScheduleDate
   */
  public void setSalesScheduleDate(Date value)
  {
    setAttributeInternal(SALESSCHEDULEDATE, value);
  }



  /**
   * 
   * Gets the attribute value for StoreSalesPrice, using the alias name StoreSalesPrice
   */
  public String getStoreSalesPrice()
  {
    return (String)getAttributeInternal(STORESALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for StoreSalesPrice
   */
  public void setStoreSalesPrice(String value)
  {
    setAttributeInternal(STORESALESPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for StoreSalesPriceIncTax, using the alias name StoreSalesPriceIncTax
   */
  public String getStoreSalesPriceIncTax()
  {
    return (String)getAttributeInternal(STORESALESPRICEINCTAX);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for StoreSalesPriceIncTax
   */
  public void setStoreSalesPriceIncTax(String value)
  {
    setAttributeInternal(STORESALESPRICEINCTAX, value);
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
   * Gets the attribute value for IntroduceTerms, using the alias name IntroduceTerms
   */
  public String getIntroduceTerms()
  {
    return (String)getAttributeInternal(INTRODUCETERMS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroduceTerms
   */
  public void setIntroduceTerms(String value)
  {
    setAttributeInternal(INTRODUCETERMS, value);
  }

  /**
   * 
   * Gets the attribute value for NotifyFlag, using the alias name NotifyFlag
   */
  public String getNotifyFlag()
  {
    return (String)getAttributeInternal(NOTIFYFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NotifyFlag
   */
  public void setNotifyFlag(String value)
  {
    setAttributeInternal(NOTIFYFLAG, value);
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
      case XXCSOSALESHEADERSEO:
        return getXxcsoSalesHeadersEO();
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
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }






  /**
   * 
   * Gets the attribute value for DelivPrice, using the alias name DelivPrice
   */
  public String getDelivPrice()
  {
    return (String)getAttributeInternal(DELIVPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for DelivPrice
   */
  public void setDelivPrice(String value)
  {
    setAttributeInternal(DELIVPRICE, value);
  }


  /**
   * 
   * Gets the associated entity XxcsoSalesHeadersEOImpl
   */
  public XxcsoSalesHeadersEOImpl getXxcsoSalesHeadersEO()
  {
    return (XxcsoSalesHeadersEOImpl)getAttributeInternal(XXCSOSALESHEADERSEO);
  }

  /**
   * 
   * Sets <code>value</code> as the associated entity XxcsoSalesHeadersEOImpl
   */
  public void setXxcsoSalesHeadersEO(XxcsoSalesHeadersEOImpl value)
  {
    setAttributeInternal(XXCSOSALESHEADERSEO, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number salesLineId)
  {
    return new Key(new Object[] {salesLineId});
  }












}