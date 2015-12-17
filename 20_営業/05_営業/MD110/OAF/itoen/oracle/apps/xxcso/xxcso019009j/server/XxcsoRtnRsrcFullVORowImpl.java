/*============================================================================
* ファイル名 : XxcsoRtnRsrcFullVORowImpl
* 概要説明   : 一括更新リージョン用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS富尾和基    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * 一括更新リージョンのビュー行クラスです。
 * @author  SCS富尾和基
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcFullVORowImpl extends OAViewRowImpl 
{


  protected static final int ACCOUNTNUMBER = 0;
  protected static final int CUSTACCOUNTID = 1;
  protected static final int CREATEDBY = 2;
  protected static final int CREATIONDATE = 3;
  protected static final int LASTUPDATEDBY = 4;
  protected static final int LASTUPDATEDATE = 5;
  protected static final int LASTUPDATELOGIN = 6;
  protected static final int TRGTROUTENO = 7;
  protected static final int TRGTROUTENOSTARTDATE = 8;
  protected static final int TRGTROUTENOEXTENSIONID = 9;
  protected static final int TRGTROUTENOLASTUPDDATE = 10;
  protected static final int NEXTROUTENO = 11;
  protected static final int NEXTROUTENOSTARTDATE = 12;
  protected static final int NEXTROUTENOEXTENSIONID = 13;
  protected static final int NEXTROUTENOLASTUPDDATE = 14;
  protected static final int TRGTRESOURCE = 15;
  protected static final int TRGTRESOURCESTARTDATE = 16;
  protected static final int TRGTRESOURCEEXTENSIONID = 17;
  protected static final int TRGTRESOURCELASTUPDDATE = 18;
  protected static final int NEXTRESOURCE = 19;
  protected static final int NEXTRESOURCESTARTDATE = 20;
  protected static final int NEXTRESOURCEEXTENSIONID = 21;
  protected static final int NEXTRESOURCELASTUPDDATE = 22;
  protected static final int TRGTRESOURCECNT = 23;
  protected static final int NEXTRESOURCECNT = 24;
  protected static final int RSVBASECODE = 25;
  protected static final int ACCOUNTNUMBERREADONLY = 26;
  protected static final int ISRSVFLG = 27;
  protected static final int PARTYNAME = 28;
  protected static final int SORTCODE = 29;
  protected static final int SALEBASECODE = 30;
  protected static final int RSVSALEBASECODE = 31;
  protected static final int RSVSALEBASEACTDATE = 32;
  protected static final int CUSTOMERCLASSCODE = 33;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoRtnRsrcVEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoRtnRsrcVEOImpl getXxcsoRtnRsrcVEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoRtnRsrcVEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for ACCOUNT_NUMBER using the alias name AccountNumber
   */
  public String getAccountNumber()
  {
    return (String)getAttributeInternal(ACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ACCOUNT_NUMBER using the alias name AccountNumber
   */
  public void setAccountNumber(String value)
  {
    setAttributeInternal(ACCOUNTNUMBER, value);
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
   * Gets the attribute value for TRGT_ROUTE_NO using the alias name TrgtRouteNo
   */
  public String getTrgtRouteNo()
  {
    return (String)getAttributeInternal(TRGTROUTENO);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TRGT_ROUTE_NO using the alias name TrgtRouteNo
   */
  public void setTrgtRouteNo(String value)
  {
    setAttributeInternal(TRGTROUTENO, value);
  }

  /**
   * 
   * Gets the attribute value for TRGT_ROUTE_NO_START_DATE using the alias name TrgtRouteNoStartDate
   */
  public Date getTrgtRouteNoStartDate()
  {
    return (Date)getAttributeInternal(TRGTROUTENOSTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TRGT_ROUTE_NO_START_DATE using the alias name TrgtRouteNoStartDate
   */
  public void setTrgtRouteNoStartDate(Date value)
  {
    setAttributeInternal(TRGTROUTENOSTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for TRGT_ROUTE_NO_EXTENSION_ID using the alias name TrgtRouteNoExtensionId
   */
  public Number getTrgtRouteNoExtensionId()
  {
    return (Number)getAttributeInternal(TRGTROUTENOEXTENSIONID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TRGT_ROUTE_NO_EXTENSION_ID using the alias name TrgtRouteNoExtensionId
   */
  public void setTrgtRouteNoExtensionId(Number value)
  {
    setAttributeInternal(TRGTROUTENOEXTENSIONID, value);
  }

  /**
   * 
   * Gets the attribute value for TRGT_ROUTE_NO_LAST_UPD_DATE using the alias name TrgtRouteNoLastUpdDate
   */
  public Date getTrgtRouteNoLastUpdDate()
  {
    return (Date)getAttributeInternal(TRGTROUTENOLASTUPDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TRGT_ROUTE_NO_LAST_UPD_DATE using the alias name TrgtRouteNoLastUpdDate
   */
  public void setTrgtRouteNoLastUpdDate(Date value)
  {
    setAttributeInternal(TRGTROUTENOLASTUPDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for NEXT_ROUTE_NO using the alias name NextRouteNo
   */
  public String getNextRouteNo()
  {
    return (String)getAttributeInternal(NEXTROUTENO);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NEXT_ROUTE_NO using the alias name NextRouteNo
   */
  public void setNextRouteNo(String value)
  {
    setAttributeInternal(NEXTROUTENO, value);
  }

  /**
   * 
   * Gets the attribute value for NEXT_ROUTE_NO_START_DATE using the alias name NextRouteNoStartDate
   */
  public Date getNextRouteNoStartDate()
  {
    return (Date)getAttributeInternal(NEXTROUTENOSTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NEXT_ROUTE_NO_START_DATE using the alias name NextRouteNoStartDate
   */
  public void setNextRouteNoStartDate(Date value)
  {
    setAttributeInternal(NEXTROUTENOSTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for NEXT_ROUTE_NO_EXTENSION_ID using the alias name NextRouteNoExtensionId
   */
  public Number getNextRouteNoExtensionId()
  {
    return (Number)getAttributeInternal(NEXTROUTENOEXTENSIONID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NEXT_ROUTE_NO_EXTENSION_ID using the alias name NextRouteNoExtensionId
   */
  public void setNextRouteNoExtensionId(Number value)
  {
    setAttributeInternal(NEXTROUTENOEXTENSIONID, value);
  }

  /**
   * 
   * Gets the attribute value for NEXT_ROUTE_NO_LAST_UPD_DATE using the alias name NextRouteNoLastUpdDate
   */
  public Date getNextRouteNoLastUpdDate()
  {
    return (Date)getAttributeInternal(NEXTROUTENOLASTUPDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NEXT_ROUTE_NO_LAST_UPD_DATE using the alias name NextRouteNoLastUpdDate
   */
  public void setNextRouteNoLastUpdDate(Date value)
  {
    setAttributeInternal(NEXTROUTENOLASTUPDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for TRGT_RESOURCE using the alias name TrgtResource
   */
  public String getTrgtResource()
  {
    return (String)getAttributeInternal(TRGTRESOURCE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TRGT_RESOURCE using the alias name TrgtResource
   */
  public void setTrgtResource(String value)
  {
    setAttributeInternal(TRGTRESOURCE, value);
  }

  /**
   * 
   * Gets the attribute value for TRGT_RESOURCE_START_DATE using the alias name TrgtResourceStartDate
   */
  public Date getTrgtResourceStartDate()
  {
    return (Date)getAttributeInternal(TRGTRESOURCESTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TRGT_RESOURCE_START_DATE using the alias name TrgtResourceStartDate
   */
  public void setTrgtResourceStartDate(Date value)
  {
    setAttributeInternal(TRGTRESOURCESTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for TRGT_RESOURCE_EXTENSION_ID using the alias name TrgtResourceExtensionId
   */
  public Number getTrgtResourceExtensionId()
  {
    return (Number)getAttributeInternal(TRGTRESOURCEEXTENSIONID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TRGT_RESOURCE_EXTENSION_ID using the alias name TrgtResourceExtensionId
   */
  public void setTrgtResourceExtensionId(Number value)
  {
    setAttributeInternal(TRGTRESOURCEEXTENSIONID, value);
  }

  /**
   * 
   * Gets the attribute value for TRGT_RESOURCE_LAST_UPD_DATE using the alias name TrgtResourceLastUpdDate
   */
  public Date getTrgtResourceLastUpdDate()
  {
    return (Date)getAttributeInternal(TRGTRESOURCELASTUPDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for TRGT_RESOURCE_LAST_UPD_DATE using the alias name TrgtResourceLastUpdDate
   */
  public void setTrgtResourceLastUpdDate(Date value)
  {
    setAttributeInternal(TRGTRESOURCELASTUPDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for NEXT_RESOURCE using the alias name NextResource
   */
  public String getNextResource()
  {
    return (String)getAttributeInternal(NEXTRESOURCE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NEXT_RESOURCE using the alias name NextResource
   */
  public void setNextResource(String value)
  {
    setAttributeInternal(NEXTRESOURCE, value);
  }

  /**
   * 
   * Gets the attribute value for NEXT_RESOURCE_START_DATE using the alias name NextResourceStartDate
   */
  public Date getNextResourceStartDate()
  {
    return (Date)getAttributeInternal(NEXTRESOURCESTARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NEXT_RESOURCE_START_DATE using the alias name NextResourceStartDate
   */
  public void setNextResourceStartDate(Date value)
  {
    setAttributeInternal(NEXTRESOURCESTARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for NEXT_RESOURCE_EXTENSION_ID using the alias name NextResourceExtensionId
   */
  public Number getNextResourceExtensionId()
  {
    return (Number)getAttributeInternal(NEXTRESOURCEEXTENSIONID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NEXT_RESOURCE_EXTENSION_ID using the alias name NextResourceExtensionId
   */
  public void setNextResourceExtensionId(Number value)
  {
    setAttributeInternal(NEXTRESOURCEEXTENSIONID, value);
  }

  /**
   * 
   * Gets the attribute value for NEXT_RESOURCE_LAST_UPD_DATE using the alias name NextResourceLastUpdDate
   */
  public Date getNextResourceLastUpdDate()
  {
    return (Date)getAttributeInternal(NEXTRESOURCELASTUPDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NEXT_RESOURCE_LAST_UPD_DATE using the alias name NextResourceLastUpdDate
   */
  public void setNextResourceLastUpdDate(Date value)
  {
    setAttributeInternal(NEXTRESOURCELASTUPDDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case CUSTACCOUNTID:
        return getCustAccountId();
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
      case TRGTROUTENO:
        return getTrgtRouteNo();
      case TRGTROUTENOSTARTDATE:
        return getTrgtRouteNoStartDate();
      case TRGTROUTENOEXTENSIONID:
        return getTrgtRouteNoExtensionId();
      case TRGTROUTENOLASTUPDDATE:
        return getTrgtRouteNoLastUpdDate();
      case NEXTROUTENO:
        return getNextRouteNo();
      case NEXTROUTENOSTARTDATE:
        return getNextRouteNoStartDate();
      case NEXTROUTENOEXTENSIONID:
        return getNextRouteNoExtensionId();
      case NEXTROUTENOLASTUPDDATE:
        return getNextRouteNoLastUpdDate();
      case TRGTRESOURCE:
        return getTrgtResource();
      case TRGTRESOURCESTARTDATE:
        return getTrgtResourceStartDate();
      case TRGTRESOURCEEXTENSIONID:
        return getTrgtResourceExtensionId();
      case TRGTRESOURCELASTUPDDATE:
        return getTrgtResourceLastUpdDate();
      case NEXTRESOURCE:
        return getNextResource();
      case NEXTRESOURCESTARTDATE:
        return getNextResourceStartDate();
      case NEXTRESOURCEEXTENSIONID:
        return getNextResourceExtensionId();
      case NEXTRESOURCELASTUPDDATE:
        return getNextResourceLastUpdDate();
      case TRGTRESOURCECNT:
        return getTrgtResourceCnt();
      case NEXTRESOURCECNT:
        return getNextResourceCnt();
      case RSVBASECODE:
        return getRsvBaseCode();
      case ACCOUNTNUMBERREADONLY:
        return getAccountNumberReadOnly();
      case ISRSVFLG:
        return getIsRsvFlg();
      case PARTYNAME:
        return getPartyName();
      case SORTCODE:
        return getSortCode();
      case SALEBASECODE:
        return getSaleBaseCode();
      case RSVSALEBASECODE:
        return getRsvSaleBaseCode();
      case RSVSALEBASEACTDATE:
        return getRsvSaleBaseActDate();
      case CUSTOMERCLASSCODE:
        return getCustomerClassCode();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case CUSTACCOUNTID:
        setCustAccountId((Number)value);
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
      case TRGTROUTENO:
        setTrgtRouteNo((String)value);
        return;
      case TRGTROUTENOSTARTDATE:
        setTrgtRouteNoStartDate((Date)value);
        return;
      case TRGTROUTENOEXTENSIONID:
        setTrgtRouteNoExtensionId((Number)value);
        return;
      case TRGTROUTENOLASTUPDDATE:
        setTrgtRouteNoLastUpdDate((Date)value);
        return;
      case NEXTROUTENO:
        setNextRouteNo((String)value);
        return;
      case NEXTROUTENOSTARTDATE:
        setNextRouteNoStartDate((Date)value);
        return;
      case NEXTROUTENOEXTENSIONID:
        setNextRouteNoExtensionId((Number)value);
        return;
      case NEXTROUTENOLASTUPDDATE:
        setNextRouteNoLastUpdDate((Date)value);
        return;
      case TRGTRESOURCE:
        setTrgtResource((String)value);
        return;
      case TRGTRESOURCESTARTDATE:
        setTrgtResourceStartDate((Date)value);
        return;
      case TRGTRESOURCEEXTENSIONID:
        setTrgtResourceExtensionId((Number)value);
        return;
      case TRGTRESOURCELASTUPDDATE:
        setTrgtResourceLastUpdDate((Date)value);
        return;
      case NEXTRESOURCE:
        setNextResource((String)value);
        return;
      case NEXTRESOURCESTARTDATE:
        setNextResourceStartDate((Date)value);
        return;
      case NEXTRESOURCEEXTENSIONID:
        setNextResourceExtensionId((Number)value);
        return;
      case NEXTRESOURCELASTUPDDATE:
        setNextResourceLastUpdDate((Date)value);
        return;
      case TRGTRESOURCECNT:
        setTrgtResourceCnt((Number)value);
        return;
      case NEXTRESOURCECNT:
        setNextResourceCnt((Number)value);
        return;
      case RSVBASECODE:
        setRsvBaseCode((String)value);
        return;
      case ACCOUNTNUMBERREADONLY:
        setAccountNumberReadOnly((Boolean)value);
        return;
      case ISRSVFLG:
        setIsRsvFlg((String)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
        return;
      case SORTCODE:
        setSortCode((Number)value);
        return;
      case SALEBASECODE:
        setSaleBaseCode((String)value);
        return;
      case RSVSALEBASECODE:
        setRsvSaleBaseCode((String)value);
        return;
      case RSVSALEBASEACTDATE:
        setRsvSaleBaseActDate((Date)value);
        return;
      case CUSTOMERCLASSCODE:
        setCustomerClassCode((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PartyName
   */
  public String getPartyName()
  {
    return (String)getAttributeInternal(PARTYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PartyName
   */
  public void setPartyName(String value)
  {
    setAttributeInternal(PARTYNAME, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute RsvBaseCode
   */
  public String getRsvBaseCode()
  {
    return (String)getAttributeInternal(RSVBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RsvBaseCode
   */
  public void setRsvBaseCode(String value)
  {
    setAttributeInternal(RSVBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AccountNumberReadOnly
   */
  public Boolean getAccountNumberReadOnly()
  {
    return (Boolean)getAttributeInternal(ACCOUNTNUMBERREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AccountNumberReadOnly
   */
  public void setAccountNumberReadOnly(Boolean value)
  {
    setAttributeInternal(ACCOUNTNUMBERREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for CUST_ACCOUNT_ID using the alias name CustAccountId
   */
  public Number getCustAccountId()
  {
    return (Number)getAttributeInternal(CUSTACCOUNTID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CUST_ACCOUNT_ID using the alias name CustAccountId
   */
  public void setCustAccountId(Number value)
  {
    setAttributeInternal(CUSTACCOUNTID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IsRsvFlg
   */
  public String getIsRsvFlg()
  {
    return (String)getAttributeInternal(ISRSVFLG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IsRsvFlg
   */
  public void setIsRsvFlg(String value)
  {
    setAttributeInternal(ISRSVFLG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TrgtResourceCnt
   */
  public Number getTrgtResourceCnt()
  {
    return (Number)getAttributeInternal(TRGTRESOURCECNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TrgtResourceCnt
   */
  public void setTrgtResourceCnt(Number value)
  {
    setAttributeInternal(TRGTRESOURCECNT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NextResourceCnt
   */
  public Number getNextResourceCnt()
  {
    return (Number)getAttributeInternal(NEXTRESOURCECNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NextResourceCnt
   */
  public void setNextResourceCnt(Number value)
  {
    setAttributeInternal(NEXTRESOURCECNT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SortCode
   */
  public Number getSortCode()
  {
    return (Number)getAttributeInternal(SORTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SortCode
   */
  public void setSortCode(Number value)
  {
    setAttributeInternal(SORTCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SaleBaseCode
   */
  public String getSaleBaseCode()
  {
    return (String)getAttributeInternal(SALEBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SaleBaseCode
   */
  public void setSaleBaseCode(String value)
  {
    setAttributeInternal(SALEBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RsvSaleBaseCode
   */
  public String getRsvSaleBaseCode()
  {
    return (String)getAttributeInternal(RSVSALEBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RsvSaleBaseCode
   */
  public void setRsvSaleBaseCode(String value)
  {
    setAttributeInternal(RSVSALEBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RsvSaleBaseActDate
   */
  public Date getRsvSaleBaseActDate()
  {
    return (Date)getAttributeInternal(RSVSALEBASEACTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RsvSaleBaseActDate
   */
  public void setRsvSaleBaseActDate(Date value)
  {
    setAttributeInternal(RSVSALEBASEACTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CustomerClassCode
   */
  public String getCustomerClassCode()
  {
    return (String)getAttributeInternal(CUSTOMERCLASSCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustomerClassCode
   */
  public void setCustomerClassCode(String value)
  {
    setAttributeInternal(CUSTOMERCLASSCODE, value);
  }









}