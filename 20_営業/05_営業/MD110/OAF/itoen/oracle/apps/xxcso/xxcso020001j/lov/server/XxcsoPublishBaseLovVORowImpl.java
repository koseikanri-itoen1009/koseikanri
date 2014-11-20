/*============================================================================
* �t�@�C���� : XxcsoPublishBaseLovVORowImpl
* �T�v����   : �S�����_�R�[�hLOV�p�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-18 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * �S�����_�R�[�h��LOV�̃r���[�s�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPublishBaseLovVORowImpl extends OAViewRowImpl 
{
  protected static final int BASECODE = 0;


  protected static final int BASENAME = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPublishBaseLovVORowImpl()
  {
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
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
}