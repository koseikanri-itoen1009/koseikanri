/*============================================================================
* �t�@�C���� : XxcsoNotifyUserLovVORowImpl
* �T�v����   : �ʒm��LOV�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-10 1.0  SCS����_     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * �ʒm��LOV�r���[�s�N���X
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoNotifyUserLovVORowImpl extends OAViewRowImpl 
{


  protected static final int EMPLOYEENUMBER = 0;
  protected static final int FULLNAME = 1;
  protected static final int POSITIONNAME = 2;
  protected static final int WORKBASECODE = 3;
  protected static final int WORKBASENAME = 4;
  protected static final int USERNAME = 5;
  protected static final int POSITIONSORTCODE = 6;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoNotifyUserLovVORowImpl()
  {
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
   * Gets the attribute value for the calculated attribute FullName
   */
  public String getFullName()
  {
    return (String)getAttributeInternal(FULLNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FullName
   */
  public void setFullName(String value)
  {
    setAttributeInternal(FULLNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PositionName
   */
  public String getPositionName()
  {
    return (String)getAttributeInternal(POSITIONNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PositionName
   */
  public void setPositionName(String value)
  {
    setAttributeInternal(POSITIONNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute WorkBaseCode
   */
  public String getWorkBaseCode()
  {
    return (String)getAttributeInternal(WORKBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute WorkBaseCode
   */
  public void setWorkBaseCode(String value)
  {
    setAttributeInternal(WORKBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute WorkBaseName
   */
  public String getWorkBaseName()
  {
    return (String)getAttributeInternal(WORKBASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute WorkBaseName
   */
  public void setWorkBaseName(String value)
  {
    setAttributeInternal(WORKBASENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UserName
   */
  public String getUserName()
  {
    return (String)getAttributeInternal(USERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UserName
   */
  public void setUserName(String value)
  {
    setAttributeInternal(USERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PositionSortCode
   */
  public String getPositionSortCode()
  {
    return (String)getAttributeInternal(POSITIONSORTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PositionSortCode
   */
  public void setPositionSortCode(String value)
  {
    setAttributeInternal(POSITIONSORTCODE, value);
  }


  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case FULLNAME:
        return getFullName();
      case POSITIONNAME:
        return getPositionName();
      case WORKBASECODE:
        return getWorkBaseCode();
      case WORKBASENAME:
        return getWorkBaseName();
      case USERNAME:
        return getUserName();
      case POSITIONSORTCODE:
        return getPositionSortCode();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case FULLNAME:
        setFullName((String)value);
        return;
      case POSITIONNAME:
        setPositionName((String)value);
        return;
      case WORKBASECODE:
        setWorkBaseCode((String)value);
        return;
      case WORKBASENAME:
        setWorkBaseName((String)value);
        return;
      case USERNAME:
        setUserName((String)value);
        return;
      case POSITIONSORTCODE:
        setPositionSortCode((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}