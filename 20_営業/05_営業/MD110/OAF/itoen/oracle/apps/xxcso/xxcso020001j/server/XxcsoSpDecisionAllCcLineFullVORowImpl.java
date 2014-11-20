/*============================================================================
* ファイル名 : XxcsoSpDecisionAllCcLineFullVORowImpl
* 概要説明   : 全容器一律条件登録／更新用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * 全容器一律条件を登録／更新するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionAllCcLineFullVORowImpl extends OAViewRowImpl 
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
  protected static final int SORTCODE = 24;
  protected static final int DEFINEDFIXEDPRICE = 25;
  protected static final int DEFINEDCOSTRATE = 26;
  protected static final int COSTPRICE = 27;
  protected static final int ALLDISCOUNTAMTREADONLY = 28;
  protected static final int ALLCCBM1BMRATEREADONLY = 29;
  protected static final int ALLCCBM1BMAMOUNTREADONLY = 30;
  protected static final int ALLCCBM2BMRATEREADONLY = 31;
  protected static final int ALLCCBM2BMAMOUNTREADONLY = 32;
  protected static final int ALLCCBM3BMRATEREADONLY = 33;
  protected static final int ALLCCBM3BMAMOUNTREADONLY = 34;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionAllCcLineFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoSpDecisionLinesVEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionLinesVEOImpl getXxcsoSpDecisionLinesVEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionLinesVEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for SP_DECISION_LINE_ID using the alias name SpDecisionLineId
   */
  public Number getSpDecisionLineId()
  {
    return (Number)getAttributeInternal(SPDECISIONLINEID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SP_DECISION_LINE_ID using the alias name SpDecisionLineId
   */
  public void setSpDecisionLineId(Number value)
  {
    setAttributeInternal(SPDECISIONLINEID, value);
  }

  /**
   * 
   * Gets the attribute value for SP_DECISION_HEADER_ID using the alias name SpDecisionHeaderId
   */
  public Number getSpDecisionHeaderId()
  {
    return (Number)getAttributeInternal(SPDECISIONHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SP_DECISION_HEADER_ID using the alias name SpDecisionHeaderId
   */
  public void setSpDecisionHeaderId(Number value)
  {
    setAttributeInternal(SPDECISIONHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for SP_CONTAINER_TYPE using the alias name SpContainerType
   */
  public String getSpContainerType()
  {
    return (String)getAttributeInternal(SPCONTAINERTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SP_CONTAINER_TYPE using the alias name SpContainerType
   */
  public void setSpContainerType(String value)
  {
    setAttributeInternal(SPCONTAINERTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for FIXED_PRICE using the alias name FixedPrice
   */
  public String getFixedPrice()
  {
    return (String)getAttributeInternal(FIXEDPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for FIXED_PRICE using the alias name FixedPrice
   */
  public void setFixedPrice(String value)
  {
    setAttributeInternal(FIXEDPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for SALES_PRICE using the alias name SalesPrice
   */
  public String getSalesPrice()
  {
    return (String)getAttributeInternal(SALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SALES_PRICE using the alias name SalesPrice
   */
  public void setSalesPrice(String value)
  {
    setAttributeInternal(SALESPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for DISCOUNT_AMT using the alias name DiscountAmt
   */
  public String getDiscountAmt()
  {
    return (String)getAttributeInternal(DISCOUNTAMT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for DISCOUNT_AMT using the alias name DiscountAmt
   */
  public void setDiscountAmt(String value)
  {
    setAttributeInternal(DISCOUNTAMT, value);
  }

  /**
   * 
   * Gets the attribute value for BM_RATE_PER_SALES_PRICE using the alias name BmRatePerSalesPrice
   */
  public String getBmRatePerSalesPrice()
  {
    return (String)getAttributeInternal(BMRATEPERSALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BM_RATE_PER_SALES_PRICE using the alias name BmRatePerSalesPrice
   */
  public void setBmRatePerSalesPrice(String value)
  {
    setAttributeInternal(BMRATEPERSALESPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for BM_AMOUNT_PER_SALES_PRICE using the alias name BmAmountPerSalesPrice
   */
  public String getBmAmountPerSalesPrice()
  {
    return (String)getAttributeInternal(BMAMOUNTPERSALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BM_AMOUNT_PER_SALES_PRICE using the alias name BmAmountPerSalesPrice
   */
  public void setBmAmountPerSalesPrice(String value)
  {
    setAttributeInternal(BMAMOUNTPERSALESPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for BM_CONV_RATE_PER_SALES_PRICE using the alias name BmConvRatePerSalesPrice
   */
  public String getBmConvRatePerSalesPrice()
  {
    return (String)getAttributeInternal(BMCONVRATEPERSALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BM_CONV_RATE_PER_SALES_PRICE using the alias name BmConvRatePerSalesPrice
   */
  public void setBmConvRatePerSalesPrice(String value)
  {
    setAttributeInternal(BMCONVRATEPERSALESPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for BM1_BM_RATE using the alias name Bm1BmRate
   */
  public String getBm1BmRate()
  {
    return (String)getAttributeInternal(BM1BMRATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BM1_BM_RATE using the alias name Bm1BmRate
   */
  public void setBm1BmRate(String value)
  {
    setAttributeInternal(BM1BMRATE, value);
  }

  /**
   * 
   * Gets the attribute value for BM1_BM_AMOUNT using the alias name Bm1BmAmount
   */
  public String getBm1BmAmount()
  {
    return (String)getAttributeInternal(BM1BMAMOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BM1_BM_AMOUNT using the alias name Bm1BmAmount
   */
  public void setBm1BmAmount(String value)
  {
    setAttributeInternal(BM1BMAMOUNT, value);
  }

  /**
   * 
   * Gets the attribute value for BM2_BM_RATE using the alias name Bm2BmRate
   */
  public String getBm2BmRate()
  {
    return (String)getAttributeInternal(BM2BMRATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BM2_BM_RATE using the alias name Bm2BmRate
   */
  public void setBm2BmRate(String value)
  {
    setAttributeInternal(BM2BMRATE, value);
  }

  /**
   * 
   * Gets the attribute value for BM2_BM_AMOUNT using the alias name Bm2BmAmount
   */
  public String getBm2BmAmount()
  {
    return (String)getAttributeInternal(BM2BMAMOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BM2_BM_AMOUNT using the alias name Bm2BmAmount
   */
  public void setBm2BmAmount(String value)
  {
    setAttributeInternal(BM2BMAMOUNT, value);
  }

  /**
   * 
   * Gets the attribute value for BM3_BM_RATE using the alias name Bm3BmRate
   */
  public String getBm3BmRate()
  {
    return (String)getAttributeInternal(BM3BMRATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BM3_BM_RATE using the alias name Bm3BmRate
   */
  public void setBm3BmRate(String value)
  {
    setAttributeInternal(BM3BMRATE, value);
  }

  /**
   * 
   * Gets the attribute value for BM3_BM_AMOUNT using the alias name Bm3BmAmount
   */
  public String getBm3BmAmount()
  {
    return (String)getAttributeInternal(BM3BMAMOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for BM3_BM_AMOUNT using the alias name Bm3BmAmount
   */
  public void setBm3BmAmount(String value)
  {
    setAttributeInternal(BM3BMAMOUNT, value);
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
      case SORTCODE:
        return getSortCode();
      case DEFINEDFIXEDPRICE:
        return getDefinedFixedPrice();
      case DEFINEDCOSTRATE:
        return getDefinedCostRate();
      case COSTPRICE:
        return getCostPrice();
      case ALLDISCOUNTAMTREADONLY:
        return getAllDiscountAmtReadOnly();
      case ALLCCBM1BMRATEREADONLY:
        return getAllCcBm1BmRateReadOnly();
      case ALLCCBM1BMAMOUNTREADONLY:
        return getAllCcBm1BmAmountReadOnly();
      case ALLCCBM2BMRATEREADONLY:
        return getAllCcBm2BmRateReadOnly();
      case ALLCCBM2BMAMOUNTREADONLY:
        return getAllCcBm2BmAmountReadOnly();
      case ALLCCBM3BMRATEREADONLY:
        return getAllCcBm3BmRateReadOnly();
      case ALLCCBM3BMAMOUNTREADONLY:
        return getAllCcBm3BmAmountReadOnly();
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
      case SORTCODE:
        setSortCode((String)value);
        return;
      case DEFINEDFIXEDPRICE:
        setDefinedFixedPrice((Number)value);
        return;
      case DEFINEDCOSTRATE:
        setDefinedCostRate((Number)value);
        return;
      case COSTPRICE:
        setCostPrice((Number)value);
        return;
      case ALLDISCOUNTAMTREADONLY:
        setAllDiscountAmtReadOnly((Boolean)value);
        return;
      case ALLCCBM1BMRATEREADONLY:
        setAllCcBm1BmRateReadOnly((Boolean)value);
        return;
      case ALLCCBM1BMAMOUNTREADONLY:
        setAllCcBm1BmAmountReadOnly((Boolean)value);
        return;
      case ALLCCBM2BMRATEREADONLY:
        setAllCcBm2BmRateReadOnly((Boolean)value);
        return;
      case ALLCCBM2BMAMOUNTREADONLY:
        setAllCcBm2BmAmountReadOnly((Boolean)value);
        return;
      case ALLCCBM3BMRATEREADONLY:
        setAllCcBm3BmRateReadOnly((Boolean)value);
        return;
      case ALLCCBM3BMAMOUNTREADONLY:
        setAllCcBm3BmAmountReadOnly((Boolean)value);
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



  /**
   * 
   * Gets the attribute value for the calculated attribute DefinedFixedPrice
   */
  public Number getDefinedFixedPrice()
  {
    return (Number)getAttributeInternal(DEFINEDFIXEDPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DefinedFixedPrice
   */
  public void setDefinedFixedPrice(Number value)
  {
    setAttributeInternal(DEFINEDFIXEDPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DefinedCostRate
   */
  public Number getDefinedCostRate()
  {
    return (Number)getAttributeInternal(DEFINEDCOSTRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DefinedCostRate
   */
  public void setDefinedCostRate(Number value)
  {
    setAttributeInternal(DEFINEDCOSTRATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CostPrice
   */
  public Number getCostPrice()
  {
    return (Number)getAttributeInternal(COSTPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CostPrice
   */
  public void setCostPrice(Number value)
  {
    setAttributeInternal(COSTPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AllDiscountAmtReadOnly
   */
  public Boolean getAllDiscountAmtReadOnly()
  {
    return (Boolean)getAttributeInternal(ALLDISCOUNTAMTREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AllDiscountAmtReadOnly
   */
  public void setAllDiscountAmtReadOnly(Boolean value)
  {
    setAttributeInternal(ALLDISCOUNTAMTREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AllCcBm1BmRateReadOnly
   */
  public Boolean getAllCcBm1BmRateReadOnly()
  {
    return (Boolean)getAttributeInternal(ALLCCBM1BMRATEREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AllCcBm1BmRateReadOnly
   */
  public void setAllCcBm1BmRateReadOnly(Boolean value)
  {
    setAttributeInternal(ALLCCBM1BMRATEREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AllCcBm1BmAmountReadOnly
   */
  public Boolean getAllCcBm1BmAmountReadOnly()
  {
    return (Boolean)getAttributeInternal(ALLCCBM1BMAMOUNTREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AllCcBm1BmAmountReadOnly
   */
  public void setAllCcBm1BmAmountReadOnly(Boolean value)
  {
    setAttributeInternal(ALLCCBM1BMAMOUNTREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AllCcBm2BmRateReadOnly
   */
  public Boolean getAllCcBm2BmRateReadOnly()
  {
    return (Boolean)getAttributeInternal(ALLCCBM2BMRATEREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AllCcBm2BmRateReadOnly
   */
  public void setAllCcBm2BmRateReadOnly(Boolean value)
  {
    setAttributeInternal(ALLCCBM2BMRATEREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AllCcBm2BmAmountReadOnly
   */
  public Boolean getAllCcBm2BmAmountReadOnly()
  {
    return (Boolean)getAttributeInternal(ALLCCBM2BMAMOUNTREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AllCcBm2BmAmountReadOnly
   */
  public void setAllCcBm2BmAmountReadOnly(Boolean value)
  {
    setAttributeInternal(ALLCCBM2BMAMOUNTREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AllCcBm3BmRateReadOnly
   */
  public Boolean getAllCcBm3BmRateReadOnly()
  {
    return (Boolean)getAttributeInternal(ALLCCBM3BMRATEREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AllCcBm3BmRateReadOnly
   */
  public void setAllCcBm3BmRateReadOnly(Boolean value)
  {
    setAttributeInternal(ALLCCBM3BMRATEREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AllCcBm3BmAmountReadOnly
   */
  public Boolean getAllCcBm3BmAmountReadOnly()
  {
    return (Boolean)getAttributeInternal(ALLCCBM3BMAMOUNTREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AllCcBm3BmAmountReadOnly
   */
  public void setAllCcBm3BmAmountReadOnly(Boolean value)
  {
    setAttributeInternal(ALLCCBM3BMAMOUNTREADONLY, value);
  }

















































}