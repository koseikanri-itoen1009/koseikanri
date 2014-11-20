/*============================================================================
* �t�@�C���� : XxcsoInstallBaseViewSizeVORowImpl
* �T�v����   : �������ėp������ʁ^�\���s���r���[�s�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-25 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * �\���s�����擾���邽�߂̃r���[�s�N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBaseViewSizeVORowImpl extends OAViewRowImpl 
{

  protected static final int VIEWSIZE = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallBaseViewSizeVORowImpl()
  {
  }


  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VIEWSIZE:
        return getViewSize();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VIEWSIZE:
        setViewSize((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ViewSize
   */
  public String getViewSize()
  {
    return (String)getAttributeInternal(VIEWSIZE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ViewSize
   */
  public void setViewSize(String value)
  {
    setAttributeInternal(VIEWSIZE, value);
  }
}