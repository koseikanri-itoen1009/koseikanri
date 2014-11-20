/*============================================================================
* �t�@�C���� : XxcsoContractAuthorityCheckVORowImpl
* �T�v����   : �����`�F�b�N�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-20 1.0  SCS�y���    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
/*******************************************************************************
 * �����`�F�b�N���邽�߂̃r���[�s�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractAuthorityCheckVORowImpl extends OAViewRowImpl 
{







  protected static final int AUTHORITY = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractAuthorityCheckVORowImpl()
  {
  }


  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case AUTHORITY:
        return getAuthority();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case AUTHORITY:
        setAuthority((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Authority
   */
  public String getAuthority()
  {
    return (String)getAttributeInternal(AUTHORITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Authority
   */
  public void setAuthority(String value)
  {
    setAttributeInternal(AUTHORITY, value);
  }
}