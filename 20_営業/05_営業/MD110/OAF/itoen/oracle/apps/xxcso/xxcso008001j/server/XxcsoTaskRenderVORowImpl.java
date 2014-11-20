/*============================================================================
* �t�@�C���� : XxcsoTaskRenderVOImpl
* �T�v����   : �T�������󋵏Ɖ�^�����ݒ�p�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-24 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * �X�P�W���[�����[�W���������ݒ�p�r���[�N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoTaskRenderVORowImpl extends OAViewRowImpl 
{

  protected static final int TASKRENDER = 0;
  protected static final int NULL = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoTaskRenderVORowImpl()
  {
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case TASKRENDER:
        return getTaskRender();
      case NULL:
        return getNull();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case TASKRENDER:
        setTaskRender((Boolean)value);
        return;
      case NULL:
        setNull((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TaskRender
   */
  public Boolean getTaskRender()
  {
    return (Boolean)getAttributeInternal(TASKRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TaskRender
   */
  public void setTaskRender(Boolean value)
  {
    setAttributeInternal(TASKRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Null
   */
  public String getNull()
  {
    return (String)getAttributeInternal(NULL);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Null
   */
  public void setNull(String value)
  {
    setAttributeInternal(NULL, value);
  }
}