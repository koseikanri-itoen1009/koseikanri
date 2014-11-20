/*============================================================================
* ファイル名 : XxcsoAccountSearchLovVOImpl
* 概要説明   : 顧客コードLOV用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
/*******************************************************************************
 * 顧客コードのLOVのビュー行クラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAccountStoreLovVORowImpl extends OAViewRowImpl 
{


  protected static final int ACCOUNTNUMBER = 0;
  protected static final int PARTYNAME = 1;
  protected static final int CUSTOMERCLASSNAME = 2;
  protected static final int CUSTACCOUNTID = 3;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAccountStoreLovVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AccountNumber
   */
  public String getAccountNumber()
  {
    return (String)getAttributeInternal(ACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AccountNumber
   */
  public void setAccountNumber(String value)
  {
    setAttributeInternal(ACCOUNTNUMBER, value);
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
   * Gets the attribute value for the calculated attribute CustomerClassName
   */
  public String getCustomerClassName()
  {
    return (String)getAttributeInternal(CUSTOMERCLASSNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustomerClassName
   */
  public void setCustomerClassName(String value)
  {
    setAttributeInternal(CUSTOMERCLASSNAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case PARTYNAME:
        return getPartyName();
      case CUSTOMERCLASSNAME:
        return getCustomerClassName();
      case CUSTACCOUNTID:
        return getCustAccountId();
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
      case PARTYNAME:
        setPartyName((String)value);
        return;
      case CUSTOMERCLASSNAME:
        setCustomerClassName((String)value);
        return;
      case CUSTACCOUNTID:
        setCustAccountId((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CustAccountId
   */
  public Number getCustAccountId()
  {
    return (Number)getAttributeInternal(CUSTACCOUNTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustAccountId
   */
  public void setCustAccountId(Number value)
  {
    setAttributeInternal(CUSTACCOUNTID, value);
  }
}