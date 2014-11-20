/*============================================================================
* �t�@�C���� : XxcsoContractBankLovVORowImpl
* �T�v����   : ���Z�@�֏��擾LOV�r���[�s�I�u�W�F�N�g�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS����_    �V�K�쐬
*============================================================================
*/

package itoen.oracle.apps.xxcso.xxcso010003j.lov.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * ���Z�@�֏��擾LOV�r���[�s�I�u�W�F�N�g�N���X
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractBankLovVORowImpl extends OAViewRowImpl 
{
  protected static final int BANKNUMBER = 0;


  protected static final int BANKNAME = 1;
  protected static final int BANKNUM = 2;
  protected static final int BANKBRANCHNAME = 3;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractBankLovVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BankNumber
   */
  public String getBankNumber()
  {
    return (String)getAttributeInternal(BANKNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BankNumber
   */
  public void setBankNumber(String value)
  {
    setAttributeInternal(BANKNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BankName
   */
  public String getBankName()
  {
    return (String)getAttributeInternal(BANKNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BankName
   */
  public void setBankName(String value)
  {
    setAttributeInternal(BANKNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BankNum
   */
  public String getBankNum()
  {
    return (String)getAttributeInternal(BANKNUM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BankNum
   */
  public void setBankNum(String value)
  {
    setAttributeInternal(BANKNUM, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BankBranchName
   */
  public String getBankBranchName()
  {
    return (String)getAttributeInternal(BANKBRANCHNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BankBranchName
   */
  public void setBankBranchName(String value)
  {
    setAttributeInternal(BANKBRANCHNAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case BANKNUMBER:
        return getBankNumber();
      case BANKNAME:
        return getBankName();
      case BANKNUM:
        return getBankNum();
      case BANKBRANCHNAME:
        return getBankBranchName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case BANKNUMBER:
        setBankNumber((String)value);
        return;
      case BANKNAME:
        setBankName((String)value);
        return;
      case BANKNUM:
        setBankNum((String)value);
        return;
      case BANKBRANCHNAME:
        setBankBranchName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}