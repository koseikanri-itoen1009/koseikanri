/*============================================================================
* �t�@�C���� : XxcsoLoginUserSummaryVORowImpl
* �T�v����   : ���O�C�����[�U�[���擾�r���[�s�I�u�W�F�N�g�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * ���O�C�����[�U�[���擾�r���[�s�I�u�W�F�N�g�N���X
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoLoginUserSummaryVORowImpl extends OAViewRowImpl 
{


  protected static final int EMPLOYEENUMBER = 0;
  protected static final int FULLNAME = 1;
  protected static final int BASECODE = 2;
  protected static final int BASENAME = 3;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoLoginUserSummaryVORowImpl()
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
   * Gets the attribute value for the calculated attribute BaseCode
   */
  public String getBaseCode()
  {
    return (String)getAttributeInternal(BASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseCode
   */
  public void setBaseCode(String value)
  {
    setAttributeInternal(BASECODE, value);
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
      case BASECODE:
        return getBaseCode();
      case BASENAME:
        return getBaseName();
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
      case BASECODE:
        setBaseCode((String)value);
        return;
      case BASENAME:
        setBaseName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseName
   */
  public String getBaseName()
  {
    return (String)getAttributeInternal(BASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseName
   */
  public void setBaseName(String value)
  {
    setAttributeInternal(BASENAME, value);
  }
}