/*============================================================================
* ファイル名 : XxcsoSpDecisionLinesVEOImpl
* 概要説明   : SP専決明細エンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-19 1.0  SCS小川浩     新規作成
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
 * SP専決明細のエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionLinesVEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int SPDECISIONLINEID = 0;
  protected static final int SPDECISIONHEADERID = 1;
  protected static final int SPCONTAINERTYPE = 2;
  protected static final int FIXEDPRICE = 3;
  protected static final int SALESPRICE = 4;
  protected static final int DISCOUNTAMT = 5;
  protected static final int BMRATEPERSALESPRICE = 6;
  protected static final int BMAMOUNTPERSALESPRICE = 7;
  protected static final int BMCONVRATEPERSALESPRICE = 8;
  protected static final int BM1BMRATE = 9;
  protected static final int BM1BMAMOUNT = 10;
  protected static final int BM2BMRATE = 11;
  protected static final int BM2BMAMOUNT = 12;
  protected static final int BM3BMRATE = 13;
  protected static final int BM3BMAMOUNT = 14;
  protected static final int CREATEDBY = 15;
  protected static final int CREATIONDATE = 16;
  protected static final int LASTUPDATEDBY = 17;
  protected static final int LASTUPDATEDATE = 18;
  protected static final int LASTUPDATELOGIN = 19;
  protected static final int REQUESTID = 20;
  protected static final int PROGRAMAPPLICATIONID = 21;
  protected static final int PROGRAMID = 22;
  protected static final int PROGRAMUPDATEDATE = 23;
  protected static final int CARDSALECLASS = 24;
  protected static final int XXCSOSPDECISIONHEADERSVEO = 25;

















  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionLinesVEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionLinesVEO");
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
    EntityDefImpl lineDef = XxcsoSpDecisionLinesVEOImpl.getDefinitionObject();
    Iterator lineIt = lineDef.getAllEntityInstancesIterator(txn);

    int minValue = 0;
    
    while( lineIt.hasNext() )
    {
      XxcsoSpDecisionLinesVEOImpl lineEo
        = (XxcsoSpDecisionLinesVEOImpl)lineIt.next();
      int spDecisionLineId = lineEo.getSpDecisionLineId().intValue();

      if ( minValue > spDecisionLineId )
      {
        minValue = spDecisionLineId;
      }
    }

    minValue--;
    
    XxcsoUtils.debug(txn, "new id:" + minValue);
    
    setSpDecisionLineId(new Number(minValue));
    
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
   * エンティティの作成処理です。
   * @param list 属性リスト
   * @see oracle.apps.fnd.framework.server.OAEntityImpl.insertRow
   *****************************************************************************
   */
  public void insertRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    EntityDefImpl headerDef
      = XxcsoSpDecisionHeadersVEOImpl.getDefinitionObject();
    Iterator headerIt = headerDef.getAllEntityInstancesIterator(txn);

    while ( headerIt.hasNext() )
    {
      XxcsoSpDecisionHeadersVEOImpl headerEo
        = (XxcsoSpDecisionHeadersVEOImpl)headerIt.next();

      if ( headerEo.getEntityState() == STATUS_NEW )
      {
        setSpDecisionHeaderId(headerEo.getSpDecisionHeaderId());
        break;
      }
    }
    
    // 登録する直前でシーケンス値を払い出します。
    Number spDecisionLineId
      = getOADBTransaction().getSequenceValue("XXCSO_SP_DECISION_LINES_S01");

    setSpDecisionLineId(spDecisionLineId);

    replaceNumber();
    
    try
    {
      XxcsoCustomDmlExecUtils.insertRow(
        txn
       ,"xxcso_sp_decision_lines"
       ,this
       ,XxcsoSpDecisionLinesVEOImpl.getDefinitionObject()
      );
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw XxcsoMessage.createSqlErrorMessage(
        e,
        XxcsoConstants.TOKEN_VALUE_SP_DECISION_LINE +
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

    replaceNumber();
    
    try
    {
      XxcsoCustomDmlExecUtils.updateRow(
        txn
       ,"xxcso_sp_decision_lines"
       ,this
       ,XxcsoSpDecisionLinesVEOImpl.getDefinitionObject()
      );
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw XxcsoMessage.createSqlErrorMessage(
        e,
        XxcsoConstants.TOKEN_VALUE_SP_DECISION_LINE +
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
       ,"xxcso_sp_decision_lines"
       ,this
       ,XxcsoSpDecisionLinesVEOImpl.getDefinitionObject()
      );
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw XxcsoMessage.createSqlErrorMessage(
        e,
        XxcsoConstants.TOKEN_VALUE_SP_DECISION_LINE +
          XxcsoConstants.TOKEN_VALUE_DELIMITER1 +
          XxcsoConstants.TOKEN_VALUE_DELETE
      );
    }

    XxcsoUtils.debug(txn, "[END]");    
  }


  
  /*****************************************************************************
   * 数値データ置き換え処理
   *****************************************************************************
   */
  private void replaceNumber()
  {
    if ( getFixedPrice() != null &&
         ! "".equals(getFixedPrice())
       )
    {
      setFixedPrice(getFixedPrice().replaceAll(",",""));
    }
    if ( getSalesPrice() != null &&
         ! "".equals(getSalesPrice())
       )
    {
      setSalesPrice(getSalesPrice().replaceAll(",",""));
    }
    if ( getDiscountAmt() != null &&
         ! "".equals(getDiscountAmt())
       )
    {
      setDiscountAmt(getDiscountAmt().replaceAll(",",""));
    }
    if ( getBmRatePerSalesPrice() != null &&
         ! "".equals(getBmRatePerSalesPrice())
       )
    {
      setBmRatePerSalesPrice(getBmRatePerSalesPrice().replaceAll(",",""));
    }
    if ( getBmAmountPerSalesPrice() != null &&
         ! "".equals(getBmAmountPerSalesPrice())
       )
    {
      setBmAmountPerSalesPrice(getBmAmountPerSalesPrice().replaceAll(",",""));
    }
    if ( getBmConvRatePerSalesPrice() != null &&
         ! "".equals(getBmConvRatePerSalesPrice())
       )
    {
      setBmConvRatePerSalesPrice(getBmConvRatePerSalesPrice().replaceAll(",",""));
    }
    if ( getBm1BmRate() != null &&
         ! "".equals(getBm1BmRate())
       )
    {
      setBm1BmRate(getBm1BmRate().replaceAll(",",""));
    }
    if ( getBm1BmAmount() != null &&
         ! "".equals(getBm1BmAmount())
       )
    {
      setBm1BmAmount(getBm1BmAmount().replaceAll(",",""));
    }
    if ( getBm2BmRate() != null &&
         ! "".equals(getBm2BmRate())
       )
    {
      setBm2BmRate(getBm2BmRate().replaceAll(",",""));
    }
    if ( getBm2BmAmount() != null &&
         ! "".equals(getBm2BmAmount())
       )
    {
      setBm2BmAmount(getBm2BmAmount().replaceAll(",",""));
    }
    if ( getBm3BmRate() != null &&
         ! "".equals(getBm3BmRate())
       )
    {
      setBm3BmRate(getBm3BmRate().replaceAll(",",""));
    }
    if ( getBm3BmAmount() != null &&
         ! "".equals(getBm3BmAmount())
       )
    {
      setBm3BmAmount(getBm3BmAmount().replaceAll(",",""));
    }
  }



  /**
   * 
   * Gets the attribute value for SpDecisionLineId, using the alias name SpDecisionLineId
   */
  public Number getSpDecisionLineId()
  {
    return (Number)getAttributeInternal(SPDECISIONLINEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SpDecisionLineId
   */
  public void setSpDecisionLineId(Number value)
  {
    setAttributeInternal(SPDECISIONLINEID, value);
  }

  /**
   * 
   * Gets the attribute value for SpDecisionHeaderId, using the alias name SpDecisionHeaderId
   */
  public Number getSpDecisionHeaderId()
  {
    return (Number)getAttributeInternal(SPDECISIONHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SpDecisionHeaderId
   */
  public void setSpDecisionHeaderId(Number value)
  {
    setAttributeInternal(SPDECISIONHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for SpContainerType, using the alias name SpContainerType
   */
  public String getSpContainerType()
  {
    return (String)getAttributeInternal(SPCONTAINERTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SpContainerType
   */
  public void setSpContainerType(String value)
  {
    setAttributeInternal(SPCONTAINERTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for FixedPrice, using the alias name FixedPrice
   */
  public String getFixedPrice()
  {
    return (String)getAttributeInternal(FIXEDPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for FixedPrice
   */
  public void setFixedPrice(String value)
  {
    setAttributeInternal(FIXEDPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for SalesPrice, using the alias name SalesPrice
   */
  public String getSalesPrice()
  {
    return (String)getAttributeInternal(SALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesPrice
   */
  public void setSalesPrice(String value)
  {
    setAttributeInternal(SALESPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for DiscountAmt, using the alias name DiscountAmt
   */
  public String getDiscountAmt()
  {
    return (String)getAttributeInternal(DISCOUNTAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for DiscountAmt
   */
  public void setDiscountAmt(String value)
  {
    setAttributeInternal(DISCOUNTAMT, value);
  }

  /**
   * 
   * Gets the attribute value for BmRatePerSalesPrice, using the alias name BmRatePerSalesPrice
   */
  public String getBmRatePerSalesPrice()
  {
    return (String)getAttributeInternal(BMRATEPERSALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BmRatePerSalesPrice
   */
  public void setBmRatePerSalesPrice(String value)
  {
    setAttributeInternal(BMRATEPERSALESPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for BmAmountPerSalesPrice, using the alias name BmAmountPerSalesPrice
   */
  public String getBmAmountPerSalesPrice()
  {
    return (String)getAttributeInternal(BMAMOUNTPERSALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BmAmountPerSalesPrice
   */
  public void setBmAmountPerSalesPrice(String value)
  {
    setAttributeInternal(BMAMOUNTPERSALESPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for BmConvRatePerSalesPrice, using the alias name BmConvRatePerSalesPrice
   */
  public String getBmConvRatePerSalesPrice()
  {
    return (String)getAttributeInternal(BMCONVRATEPERSALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BmConvRatePerSalesPrice
   */
  public void setBmConvRatePerSalesPrice(String value)
  {
    setAttributeInternal(BMCONVRATEPERSALESPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for Bm1BmRate, using the alias name Bm1BmRate
   */
  public String getBm1BmRate()
  {
    return (String)getAttributeInternal(BM1BMRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Bm1BmRate
   */
  public void setBm1BmRate(String value)
  {
    setAttributeInternal(BM1BMRATE, value);
  }

  /**
   * 
   * Gets the attribute value for Bm1BmAmount, using the alias name Bm1BmAmount
   */
  public String getBm1BmAmount()
  {
    return (String)getAttributeInternal(BM1BMAMOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Bm1BmAmount
   */
  public void setBm1BmAmount(String value)
  {
    setAttributeInternal(BM1BMAMOUNT, value);
  }

  /**
   * 
   * Gets the attribute value for Bm2BmRate, using the alias name Bm2BmRate
   */
  public String getBm2BmRate()
  {
    return (String)getAttributeInternal(BM2BMRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Bm2BmRate
   */
  public void setBm2BmRate(String value)
  {
    setAttributeInternal(BM2BMRATE, value);
  }

  /**
   * 
   * Gets the attribute value for Bm2BmAmount, using the alias name Bm2BmAmount
   */
  public String getBm2BmAmount()
  {
    return (String)getAttributeInternal(BM2BMAMOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Bm2BmAmount
   */
  public void setBm2BmAmount(String value)
  {
    setAttributeInternal(BM2BMAMOUNT, value);
  }

  /**
   * 
   * Gets the attribute value for Bm3BmRate, using the alias name Bm3BmRate
   */
  public String getBm3BmRate()
  {
    return (String)getAttributeInternal(BM3BMRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Bm3BmRate
   */
  public void setBm3BmRate(String value)
  {
    setAttributeInternal(BM3BMRATE, value);
  }

  /**
   * 
   * Gets the attribute value for Bm3BmAmount, using the alias name Bm3BmAmount
   */
  public String getBm3BmAmount()
  {
    return (String)getAttributeInternal(BM3BMAMOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Bm3BmAmount
   */
  public void setBm3BmAmount(String value)
  {
    setAttributeInternal(BM3BMAMOUNT, value);
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
      case SPDECISIONLINEID:
        return getSpDecisionLineId();
      case SPDECISIONHEADERID:
        return getSpDecisionHeaderId();
      case SPCONTAINERTYPE:
        return getSpContainerType();
      case FIXEDPRICE:
        return getFixedPrice();
      case SALESPRICE:
        return getSalesPrice();
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
      case CARDSALECLASS:
        return getCardSaleClass();
      case XXCSOSPDECISIONHEADERSVEO:
        return getXxcsoSpDecisionHeadersVEO();
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
      case SPDECISIONHEADERID:
        setSpDecisionHeaderId((Number)value);
        return;
      case SPCONTAINERTYPE:
        setSpContainerType((String)value);
        return;
      case FIXEDPRICE:
        setFixedPrice((String)value);
        return;
      case SALESPRICE:
        setSalesPrice((String)value);
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
      case CARDSALECLASS:
        setCardSaleClass((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }


  /**
   * 
   * Gets the associated entity XxcsoSpDecisionHeadersVEOImpl
   */
  public XxcsoSpDecisionHeadersVEOImpl getXxcsoSpDecisionHeadersVEO()
  {
    return (XxcsoSpDecisionHeadersVEOImpl)getAttributeInternal(XXCSOSPDECISIONHEADERSVEO);
  }

  /**
   * 
   * Sets <code>value</code> as the associated entity XxcsoSpDecisionHeadersVEOImpl
   */
  public void setXxcsoSpDecisionHeadersVEO(XxcsoSpDecisionHeadersVEOImpl value)
  {
    setAttributeInternal(XXCSOSPDECISIONHEADERSVEO, value);
  }


  /**
   * 
   * Gets the attribute value for CardSaleClass, using the alias name CardSaleClass
   */
  public String getCardSaleClass()
  {
    return (String)getAttributeInternal(CARDSALECLASS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CardSaleClass
   */
  public void setCardSaleClass(String value)
  {
    setAttributeInternal(CARDSALECLASS, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number spDecisionLineId)
  {
    return new Key(new Object[] {spDecisionLineId});
  }
















}