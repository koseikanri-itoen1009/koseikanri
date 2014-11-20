/*============================================================================
* ÉtÉ@ÉCÉãñº : XxcsoSpDecisionScLineFullVORowImpl
* äTóvê‡ñæ   : îÑâøï èåèìoò^Å^çXêVópÉrÉÖÅ[çsÉNÉâÉX
* ÉoÅ[ÉWÉáÉì : 1.0
*============================================================================
* èCê≥óöó
* ì˙ït       Ver. íSìñé“       èCê≥ì‡óe
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCSè¨êÏç_     êVãKçÏê¨
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * îÑâøï èåèÇìoò^Å^çXêVÇ∑ÇÈÇΩÇﬂÇÃÉrÉÖÅ[çsÉNÉâÉXÇ≈Ç∑ÅB
 * @author  SCSè¨êÏç_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionScLineFullVORowImpl extends OAViewRowImpl 
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
  protected static final int SELECTFLAG = 25;
  protected static final int FIXEDPRICEREADONLY = 26;
  protected static final int SALESPRICEREADONLY = 27;
  protected static final int SCBM1BMRATEREADONLY = 28;
  protected static final int SCBM1BMAMOUNTREADONLY = 29;
  protected static final int SCBM2BMRATEREADONLY = 30;
  protected static final int SCBM2BMAMOUNTREADONLY = 31;
  protected static final int SCBM3BMRATEREADONLY = 32;
  protected static final int SCBM3BMAMOUNTREADONLY = 33;
  protected static final int SCMULTIPLESELECTIONRENDER = 34;
  protected static final int CARDSALECLASSREADONLY = 35;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionScLineFullVORowImpl()
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
      case CARDSALECLASS:
        return getCardSaleClass();
      case SELECTFLAG:
        return getSelectFlag();
      case FIXEDPRICEREADONLY:
        return getFixedPriceReadOnly();
      case SALESPRICEREADONLY:
        return getSalesPriceReadOnly();
      case SCBM1BMRATEREADONLY:
        return getScBm1BmRateReadOnly();
      case SCBM1BMAMOUNTREADONLY:
        return getScBm1BmAmountReadOnly();
      case SCBM2BMRATEREADONLY:
        return getScBm2BmRateReadOnly();
      case SCBM2BMAMOUNTREADONLY:
        return getScBm2BmAmountReadOnly();
      case SCBM3BMRATEREADONLY:
        return getScBm3BmRateReadOnly();
      case SCBM3BMAMOUNTREADONLY:
        return getScBm3BmAmountReadOnly();
      case SCMULTIPLESELECTIONRENDER:
        return getScMultipleSelectionRender();
      case CARDSALECLASSREADONLY:
        return getCardSaleClassReadOnly();
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
      case SELECTFLAG:
        setSelectFlag((String)value);
        return;
      case FIXEDPRICEREADONLY:
        setFixedPriceReadOnly((Boolean)value);
        return;
      case SALESPRICEREADONLY:
        setSalesPriceReadOnly((Boolean)value);
        return;
      case SCBM1BMRATEREADONLY:
        setScBm1BmRateReadOnly((Boolean)value);
        return;
      case SCBM1BMAMOUNTREADONLY:
        setScBm1BmAmountReadOnly((Boolean)value);
        return;
      case SCBM2BMRATEREADONLY:
        setScBm2BmRateReadOnly((Boolean)value);
        return;
      case SCBM2BMAMOUNTREADONLY:
        setScBm2BmAmountReadOnly((Boolean)value);
        return;
      case SCBM3BMRATEREADONLY:
        setScBm3BmRateReadOnly((Boolean)value);
        return;
      case SCBM3BMAMOUNTREADONLY:
        setScBm3BmAmountReadOnly((Boolean)value);
        return;
      case SCMULTIPLESELECTIONRENDER:
        setScMultipleSelectionRender((Boolean)value);
        return;
      case CARDSALECLASSREADONLY:
        setCardSaleClassReadOnly((Boolean)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
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
   * Gets the attribute value for the calculated attribute ScMultipleSelectionRender
   */
  public Boolean getScMultipleSelectionRender()
  {
    return (Boolean)getAttributeInternal(SCMULTIPLESELECTIONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ScMultipleSelectionRender
   */
  public void setScMultipleSelectionRender(Boolean value)
  {
    setAttributeInternal(SCMULTIPLESELECTIONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FixedPriceReadOnly
   */
  public Boolean getFixedPriceReadOnly()
  {
    return (Boolean)getAttributeInternal(FIXEDPRICEREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FixedPriceReadOnly
   */
  public void setFixedPriceReadOnly(Boolean value)
  {
    setAttributeInternal(FIXEDPRICEREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SalesPriceReadOnly
   */
  public Boolean getSalesPriceReadOnly()
  {
    return (Boolean)getAttributeInternal(SALESPRICEREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SalesPriceReadOnly
   */
  public void setSalesPriceReadOnly(Boolean value)
  {
    setAttributeInternal(SALESPRICEREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ScBm1BmRateReadOnly
   */
  public Boolean getScBm1BmRateReadOnly()
  {
    return (Boolean)getAttributeInternal(SCBM1BMRATEREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ScBm1BmRateReadOnly
   */
  public void setScBm1BmRateReadOnly(Boolean value)
  {
    setAttributeInternal(SCBM1BMRATEREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ScBm1BmAmountReadOnly
   */
  public Boolean getScBm1BmAmountReadOnly()
  {
    return (Boolean)getAttributeInternal(SCBM1BMAMOUNTREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ScBm1BmAmountReadOnly
   */
  public void setScBm1BmAmountReadOnly(Boolean value)
  {
    setAttributeInternal(SCBM1BMAMOUNTREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ScBm2BmRateReadOnly
   */
  public Boolean getScBm2BmRateReadOnly()
  {
    return (Boolean)getAttributeInternal(SCBM2BMRATEREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ScBm2BmRateReadOnly
   */
  public void setScBm2BmRateReadOnly(Boolean value)
  {
    setAttributeInternal(SCBM2BMRATEREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ScBm2BmAmountReadOnly
   */
  public Boolean getScBm2BmAmountReadOnly()
  {
    return (Boolean)getAttributeInternal(SCBM2BMAMOUNTREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ScBm2BmAmountReadOnly
   */
  public void setScBm2BmAmountReadOnly(Boolean value)
  {
    setAttributeInternal(SCBM2BMAMOUNTREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ScBm3BmRateReadOnly
   */
  public Boolean getScBm3BmRateReadOnly()
  {
    return (Boolean)getAttributeInternal(SCBM3BMRATEREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ScBm3BmRateReadOnly
   */
  public void setScBm3BmRateReadOnly(Boolean value)
  {
    setAttributeInternal(SCBM3BMRATEREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ScBm3BmAmountReadOnly
   */
  public Boolean getScBm3BmAmountReadOnly()
  {
    return (Boolean)getAttributeInternal(SCBM3BMAMOUNTREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ScBm3BmAmountReadOnly
   */
  public void setScBm3BmAmountReadOnly(Boolean value)
  {
    setAttributeInternal(SCBM3BMAMOUNTREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for CARD_SALE_CLASS using the alias name CardSaleClass
   */
  public String getCardSaleClass()
  {
    return (String)getAttributeInternal(CARDSALECLASS);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CARD_SALE_CLASS using the alias name CardSaleClass
   */
  public void setCardSaleClass(String value)
  {
    setAttributeInternal(CARDSALECLASS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CardSaleClassReadOnly
   */
  public Boolean getCardSaleClassReadOnly()
  {
    return (Boolean)getAttributeInternal(CARDSALECLASSREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CardSaleClassReadOnly
   */
  public void setCardSaleClassReadOnly(Boolean value)
  {
    setAttributeInternal(CARDSALECLASSREADONLY, value);
  }





}