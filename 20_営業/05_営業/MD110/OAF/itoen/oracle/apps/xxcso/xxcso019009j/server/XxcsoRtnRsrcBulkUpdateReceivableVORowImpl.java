/*============================================================================
* �t�@�C���� : XxcsoRtnRsrcBulkUpdateReceivableVORowImpl
* �T�v����   : �������_�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2015-09-08 1.0  SCSK�ː��a�K  [E_�{�ғ�_13307]�V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
/*******************************************************************************
 * �������_�r���[�s�N���X�ł��B
 * @author  SCSK�ː��a�K
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateReceivableVORowImpl extends OAViewRowImpl 
{
  protected static final int RECEIVBASECODE = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcBulkUpdateReceivableVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ReceivBaseCode
   */
  public String getReceivBaseCode()
  {
    return (String)getAttributeInternal(RECEIVBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ReceivBaseCode
   */
  public void setReceivBaseCode(String value)
  {
    setAttributeInternal(RECEIVBASECODE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case RECEIVBASECODE:
        return getReceivBaseCode();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case RECEIVBASECODE:
        setReceivBaseCode((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}