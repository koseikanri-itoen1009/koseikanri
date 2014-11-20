/*============================================================================
* ファイル名 : XxcsoContractCustomerFullVORowImpl
* 概要説明   : 契約先テーブル情報ビュー行オブジェクトクラス
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
import oracle.jbo.domain.Date;

/*******************************************************************************
 * 契約先テーブル情報ビュー行オブジェクトクラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractCustomerFullVORowImpl extends OAViewRowImpl 
{
  protected static final int CONTRACTCUSTOMERID = 0;


  protected static final int CONTRACTNUMBER = 1;
  protected static final int CONTRACTNAME = 2;
  protected static final int CONTRACTNAMEKANA = 3;
  protected static final int DELEGATENAME = 4;
  protected static final int POSTCODE = 5;
  protected static final int PREFECTURES = 6;
  protected static final int CITYWARD = 7;
  protected static final int ADDRESS1 = 8;
  protected static final int ADDRESS2 = 9;
  protected static final int PHONENUMBER = 10;
  protected static final int CREATEDBY = 11;
  protected static final int CREATIONDATE = 12;
  protected static final int LASTUPDATEDBY = 13;
  protected static final int LASTUPDATEDATE = 14;
  protected static final int LASTUPDATELOGIN = 15;
  protected static final int REQUESTID = 16;
  protected static final int PROGRAMAPPLICATIONID = 17;
  protected static final int PROGRAMID = 18;
  protected static final int PROGRAMUPDATEDATE = 19;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractCustomerFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoContractCustomersEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoContractCustomersEOImpl getXxcsoContractCustomersEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoContractCustomersEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for CONTRACT_CUSTOMER_ID using the alias name ContractCustomerId
   */
  public Number getContractCustomerId()
  {
    return (Number)getAttributeInternal(CONTRACTCUSTOMERID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTRACT_CUSTOMER_ID using the alias name ContractCustomerId
   */
  public void setContractCustomerId(Number value)
  {
    setAttributeInternal(CONTRACTCUSTOMERID, value);
  }

  /**
   * 
   * Gets the attribute value for CONTRACT_NUMBER using the alias name ContractNumber
   */
  public String getContractNumber()
  {
    return (String)getAttributeInternal(CONTRACTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTRACT_NUMBER using the alias name ContractNumber
   */
  public void setContractNumber(String value)
  {
    setAttributeInternal(CONTRACTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for CONTRACT_NAME using the alias name ContractName
   */
  public String getContractName()
  {
    return (String)getAttributeInternal(CONTRACTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTRACT_NAME using the alias name ContractName
   */
  public void setContractName(String value)
  {
    setAttributeInternal(CONTRACTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for CONTRACT_NAME_KANA using the alias name ContractNameKana
   */
  public String getContractNameKana()
  {
    return (String)getAttributeInternal(CONTRACTNAMEKANA);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTRACT_NAME_KANA using the alias name ContractNameKana
   */
  public void setContractNameKana(String value)
  {
    setAttributeInternal(CONTRACTNAMEKANA, value);
  }

  /**
   * 
   * Gets the attribute value for DELEGATE_NAME using the alias name DelegateName
   */
  public String getDelegateName()
  {
    return (String)getAttributeInternal(DELEGATENAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for DELEGATE_NAME using the alias name DelegateName
   */
  public void setDelegateName(String value)
  {
    setAttributeInternal(DELEGATENAME, value);
  }

  /**
   * 
   * Gets the attribute value for POST_CODE using the alias name PostCode
   */
  public String getPostCode()
  {
    return (String)getAttributeInternal(POSTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for POST_CODE using the alias name PostCode
   */
  public void setPostCode(String value)
  {
    setAttributeInternal(POSTCODE, value);
  }

  /**
   * 
   * Gets the attribute value for PREFECTURES using the alias name Prefectures
   */
  public String getPrefectures()
  {
    return (String)getAttributeInternal(PREFECTURES);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PREFECTURES using the alias name Prefectures
   */
  public void setPrefectures(String value)
  {
    setAttributeInternal(PREFECTURES, value);
  }

  /**
   * 
   * Gets the attribute value for CITY_WARD using the alias name CityWard
   */
  public String getCityWard()
  {
    return (String)getAttributeInternal(CITYWARD);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CITY_WARD using the alias name CityWard
   */
  public void setCityWard(String value)
  {
    setAttributeInternal(CITYWARD, value);
  }

  /**
   * 
   * Gets the attribute value for ADDRESS_1 using the alias name Address1
   */
  public String getAddress1()
  {
    return (String)getAttributeInternal(ADDRESS1);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ADDRESS_1 using the alias name Address1
   */
  public void setAddress1(String value)
  {
    setAttributeInternal(ADDRESS1, value);
  }

  /**
   * 
   * Gets the attribute value for ADDRESS_2 using the alias name Address2
   */
  public String getAddress2()
  {
    return (String)getAttributeInternal(ADDRESS2);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ADDRESS_2 using the alias name Address2
   */
  public void setAddress2(String value)
  {
    setAttributeInternal(ADDRESS2, value);
  }

  /**
   * 
   * Gets the attribute value for PHONE_NUMBER using the alias name PhoneNumber
   */
  public String getPhoneNumber()
  {
    return (String)getAttributeInternal(PHONENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PHONE_NUMBER using the alias name PhoneNumber
   */
  public void setPhoneNumber(String value)
  {
    setAttributeInternal(PHONENUMBER, value);
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
      case CONTRACTCUSTOMERID:
        return getContractCustomerId();
      case CONTRACTNUMBER:
        return getContractNumber();
      case CONTRACTNAME:
        return getContractName();
      case CONTRACTNAMEKANA:
        return getContractNameKana();
      case DELEGATENAME:
        return getDelegateName();
      case POSTCODE:
        return getPostCode();
      case PREFECTURES:
        return getPrefectures();
      case CITYWARD:
        return getCityWard();
      case ADDRESS1:
        return getAddress1();
      case ADDRESS2:
        return getAddress2();
      case PHONENUMBER:
        return getPhoneNumber();
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
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case CONTRACTCUSTOMERID:
        setContractCustomerId((Number)value);
        return;
      case CONTRACTNUMBER:
        setContractNumber((String)value);
        return;
      case CONTRACTNAME:
        setContractName((String)value);
        return;
      case CONTRACTNAMEKANA:
        setContractNameKana((String)value);
        return;
      case DELEGATENAME:
        setDelegateName((String)value);
        return;
      case POSTCODE:
        setPostCode((String)value);
        return;
      case PREFECTURES:
        setPrefectures((String)value);
        return;
      case CITYWARD:
        setCityWard((String)value);
        return;
      case ADDRESS1:
        setAddress1((String)value);
        return;
      case ADDRESS2:
        setAddress2((String)value);
        return;
      case PHONENUMBER:
        setPhoneNumber((String)value);
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
}