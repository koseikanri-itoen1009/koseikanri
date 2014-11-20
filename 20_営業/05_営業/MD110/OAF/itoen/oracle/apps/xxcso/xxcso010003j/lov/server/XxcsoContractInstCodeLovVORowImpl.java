/*============================================================================
* ファイル名 : XxcsoContractInstCodeLovVORowImpl
* 概要説明   : 物件コード取得LOVビューオブジェクトクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 物件コード取得LOVビューオブジェクトクラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractInstCodeLovVORowImpl extends OAViewRowImpl 
{


  protected static final int INSTALLCODE = 0;
  protected static final int VENDORMODEL = 1;
  protected static final int PARTYNAME = 2;
  protected static final int POSTALCODE = 3;
  protected static final int STATE = 4;
  protected static final int CITY = 5;
  protected static final int ADDRESS1 = 6;
  protected static final int ADDRESS2 = 7;
  protected static final int STATUSNAME = 8;
  protected static final int INSTANCEID = 9;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractInstCodeLovVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallCode
   */
  public String getInstallCode()
  {
    return (String)getAttributeInternal(INSTALLCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallCode
   */
  public void setInstallCode(String value)
  {
    setAttributeInternal(INSTALLCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorModel
   */
  public String getVendorModel()
  {
    return (String)getAttributeInternal(VENDORMODEL);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorModel
   */
  public void setVendorModel(String value)
  {
    setAttributeInternal(VENDORMODEL, value);
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
   * Gets the attribute value for the calculated attribute PostalCode
   */
  public String getPostalCode()
  {
    return (String)getAttributeInternal(POSTALCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PostalCode
   */
  public void setPostalCode(String value)
  {
    setAttributeInternal(POSTALCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute State
   */
  public String getState()
  {
    return (String)getAttributeInternal(STATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute State
   */
  public void setState(String value)
  {
    setAttributeInternal(STATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute City
   */
  public String getCity()
  {
    return (String)getAttributeInternal(CITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute City
   */
  public void setCity(String value)
  {
    setAttributeInternal(CITY, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case INSTALLCODE:
        return getInstallCode();
      case VENDORMODEL:
        return getVendorModel();
      case PARTYNAME:
        return getPartyName();
      case POSTALCODE:
        return getPostalCode();
      case STATE:
        return getState();
      case CITY:
        return getCity();
      case ADDRESS1:
        return getAddress1();
      case ADDRESS2:
        return getAddress2();
      case STATUSNAME:
        return getStatusName();
      case INSTANCEID:
        return getInstanceId();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case INSTALLCODE:
        setInstallCode((String)value);
        return;
      case VENDORMODEL:
        setVendorModel((String)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
        return;
      case POSTALCODE:
        setPostalCode((String)value);
        return;
      case STATE:
        setState((String)value);
        return;
      case CITY:
        setCity((String)value);
        return;
      case ADDRESS1:
        setAddress1((String)value);
        return;
      case ADDRESS2:
        setAddress2((String)value);
        return;
      case STATUSNAME:
        setStatusName((String)value);
        return;
      case INSTANCEID:
        setInstanceId((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Address1
   */
  public String getAddress1()
  {
    return (String)getAttributeInternal(ADDRESS1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Address1
   */
  public void setAddress1(String value)
  {
    setAttributeInternal(ADDRESS1, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Address2
   */
  public String getAddress2()
  {
    return (String)getAttributeInternal(ADDRESS2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Address2
   */
  public void setAddress2(String value)
  {
    setAttributeInternal(ADDRESS2, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StatusName
   */
  public String getStatusName()
  {
    return (String)getAttributeInternal(STATUSNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StatusName
   */
  public void setStatusName(String value)
  {
    setAttributeInternal(STATUSNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstanceId
   */
  public Number getInstanceId()
  {
    return (Number)getAttributeInternal(INSTANCEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstanceId
   */
  public void setInstanceId(Number value)
  {
    setAttributeInternal(INSTANCEID, value);
  }
}