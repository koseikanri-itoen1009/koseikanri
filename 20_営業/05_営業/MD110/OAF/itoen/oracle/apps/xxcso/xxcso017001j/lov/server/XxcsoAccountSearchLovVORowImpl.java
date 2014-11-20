/*============================================================================
* �t�@�C���� : XxcsoAccountSearchLovVOImpl
* �T�v����   : �ڋq�R�[�hLOV�p�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-21 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * �ڋq�R�[�h��LOV�̃r���[�s�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAccountSearchLovVORowImpl extends OAViewRowImpl 
{




  protected static final int ACCOUNTNUMBER = 0;
  protected static final int PARTYNAME = 1;
  protected static final int CUSTOMERCLASSNAME = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAccountSearchLovVORowImpl()
  {
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
}