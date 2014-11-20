/*============================================================================
* �t�@�C���� : XxcsoAccountRtnRsrcLovVORowImpl
* �T�v����   : �ڋq�R�[�hLOV�p�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS�x���a��    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * �ڋq�R�[�h��LOV�̃r���[�s�N���X�ł��B
 * @author  SCS�x���a��
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAccountRtnRsrcLovVORowImpl extends OAViewRowImpl 
{


  protected static final int ACCOUNTNUMBER = 0;
  protected static final int PARTYNAME = 1;
  protected static final int RTNBASECODE = 2;
  protected static final int EMPLOYEENUMBER = 3;
  protected static final int ROUTENUMBER = 4;
  protected static final int CUSTACCOUNTID = 5;
  protected static final int ISRSV = 6;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAccountRtnRsrcLovVORowImpl()
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
   * Gets the attribute value for the calculated attribute EmployeeNumber
   */
  public String getEmployeeNumber()
  {
    return (String)getAttributeInternal(EMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmployeeNumber
   */
  public void setEmployeeNumber(String value)
  {
    setAttributeInternal(EMPLOYEENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RouteNumber
   */
  public String getRouteNumber()
  {
    return (String)getAttributeInternal(ROUTENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RouteNumber
   */
  public void setRouteNumber(String value)
  {
    setAttributeInternal(ROUTENUMBER, value);
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
      case RTNBASECODE:
        return getRtnBaseCode();
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case ROUTENUMBER:
        return getRouteNumber();
      case CUSTACCOUNTID:
        return getCustAccountId();
      case ISRSV:
        return getIsRsv();
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
      case RTNBASECODE:
        setRtnBaseCode((String)value);
        return;
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case ROUTENUMBER:
        setRouteNumber((String)value);
        return;
      case CUSTACCOUNTID:
        setCustAccountId((Number)value);
        return;
      case ISRSV:
        setIsRsv((String)value);
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

  /**
   * 
   * Gets the attribute value for the calculated attribute RtnBaseCode
   */
  public String getRtnBaseCode()
  {
    return (String)getAttributeInternal(RTNBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RtnBaseCode
   */
  public void setRtnBaseCode(String value)
  {
    setAttributeInternal(RTNBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IsRsv
   */
  public String getIsRsv()
  {
    return (String)getAttributeInternal(ISRSV);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IsRsv
   */
  public void setIsRsv(String value)
  {
    setAttributeInternal(ISRSV, value);
  }



}