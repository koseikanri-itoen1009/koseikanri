/*============================================================================
* �t�@�C���� : XxcsoAccountTypeVORowImpl
* �T�v����   : �ڋq�^�C�v�����p�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-29 1.0  SCS�y���  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
/*******************************************************************************
 * �I�������ڋq�R�[�h�̌ڋq�^�C�v���������邽�߂̃r���[�s�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAccountTypeVORowImpl extends OAViewRowImpl 
{
  protected static final int ACCOUNTNUMBER = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAccountTypeVORowImpl()
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ACCOUNTNUMBER:
        return getAccountNumber();
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
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}