/*============================================================================
* �t�@�C���� : XxcsoEmpSelRenderVORowImpl
* �T�v����   : �T�������󋵏Ɖ�^�����ݒ�p�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-27 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * �S���ґI�����[�W���������ݒ�p�r���[�s�N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoEmpSelRenderVORowImpl extends OAViewRowImpl 
{

  protected static final int NULL = 0;


  protected static final int EMPSELRENDER = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoEmpSelRenderVORowImpl()
  {
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case NULL:
        return getNull();
      case EMPSELRENDER:
        return getEmpSelRender();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case NULL:
        setNull((String)value);
        return;
      case EMPSELRENDER:
        setEmpSelRender((Boolean)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmpSelRender
   */
  public Boolean getEmpSelRender()
  {
    return (Boolean)getAttributeInternal(EMPSELRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmpSelRender
   */
  public void setEmpSelRender(Boolean value)
  {
    setAttributeInternal(EMPSELRENDER, value);
  }



}